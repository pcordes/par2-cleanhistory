//  This file is part of par2cmdline (a PAR 2.0 compatible file verification and
//  repair tool). See http://parchive.sourceforge.net for details of PAR 2.0.
//
//  Copyright (c) 2008 Vincent Tan, created 2008-09-17. par2pipeline.h
//
//  par2cmdline is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  par2cmdline is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//  Modifications for concurrent processing, async I/O, Unicode support, and
//  hierarchial directory support are Copyright (c) 2007-2008 Vincent Tan.
//  Search for "#if WANT_CONCURRENT" for concurrent code.
//  Concurrent processing utilises Intel Thread Building Blocks 2.0,
//  Copyright (c) 2007 Intel Corp.

#include "par2cmdline.h"

// implements async I/O using a TBB pipeline

#if WANT_CONCURRENT
  #if CONCURRENT_PIPELINE

    #include "tbb/tbb_thread.h"
    #include "tbb/tick_count.h"

  class buffer {
  public:
    enum WRITE_STATUS { NONE, ASYNC_WRITE };
  private:
    aiocb_type aiocb_;
    u8* inputbuffer_;

    tbb::atomic<int> refcount_;
    u32 inputindex_;
    WRITE_STATUS write_status_;

    friend class pipeline_state_base;
    bool try_to_acquire(void) {
      if (1 == ++refcount_)
        return true;

      --refcount_;
      return false;
    }
    void add_ref(void) { ++refcount_; }
    int release(void) { assert(refcount_ > 0); return --refcount_; }

  public:
    buffer(void) : inputbuffer_(NULL), inputindex_(0), write_status_(NONE) {
      refcount_ = 0;
    }

    ~buffer(void) {
      if (inputbuffer_)
        tbb::cache_aligned_allocator<u8>().deallocate(inputbuffer_, 0);
    }

    bool alloc(size_t sz) {
      assert(NULL == inputbuffer_);
      inputbuffer_ = tbb::cache_aligned_allocator<u8>().allocate(sz);//new u8[sz];
      return NULL != inputbuffer_;
    }

    const u8* get(void) const { return inputbuffer_; }
    u8* get(void) { return inputbuffer_; }

    u32 get_inputindex(void) const { return inputindex_; }
    void set_inputindex(u32 ii) { inputindex_ = ii; }

    aiocb_type& get_aiocb(void) { return aiocb_; }

    void set_write_status(WRITE_STATUS ws) { write_status_ = ws; }
    WRITE_STATUS get_write_status(void) const { return write_status_; }
  }; // buffer

  class pipeline_state_base {
  public:
    typedef tbb::concurrent_hash_map<DiskFile*, DiskFile*, intptr_hasher<DiskFile*> >  DiskFile_map_type;

  private:
    const u64                                    chunksize_;
    const u32                                    missingblockcount_;

    const size_t                                 blocklength_;
    const u64                                    blockoffset_;

    vector<DataBlock*>&                          inputblocks_;

    u32                                          inputindex_;
    vector<DataBlock*>::iterator                 inputblock_;
    tbb::mutex                                   inputblock_mutex_; // locks inputblock_ and copyblock_

    #if __GNUC__ &&  __ppc__
    // this won't cause any data corruption - it might only cause an incorrect total value to be printed
    u64                                          totalwritten_;
    #else
    tbb::atomic<u64>                             totalwritten_;
    #endif

    DiskFile_map_type                            openfiles_;

    bool                                         ok_; // if an error or failure occurs then this becomes false

  protected:
    static bool try_to_acquire(buffer& b) { return b.try_to_acquire(); }
    static void add_ref(buffer& b) { return b.add_ref(); }
    static int release(buffer& b) { return b.release(); }

  public:
    pipeline_state_base(
      u64                                        chunksize,
      u32                                        missingblockcount,
      size_t                                     blocklength,
      u64                                        blockoffset,
      vector<DataBlock*>&                        inputblocks) :
      chunksize_(chunksize), missingblockcount_(missingblockcount),
      blocklength_(blocklength), blockoffset_(blockoffset),
      inputblocks_(inputblocks), inputindex_(0), inputblock_(inputblocks.begin()),
      ok_(true) {
      totalwritten_ = 0;
    }

    ~pipeline_state_base(void) {}

    bool is_ok(void) const { return ok_; }
    void set_not_ok(void) { ok_ = false; }

    u64 totalwritten(void) const { return totalwritten_; }
    void add_to_totalwritten(u64 d) { totalwritten_ += d; }

    const size_t                                 blocklength(void) const { return blocklength_; }
    const u64                                    blockoffset(void) const { return blockoffset_; }

    tbb::mutex&                                  inputblock_mutex(void) { return inputblock_mutex_; }
    vector<DataBlock*>::iterator                 inputblock(void) { return inputblock_; }
    vector<DataBlock*>::iterator                 inputblocks_end(void) { return inputblocks_.end(); }
    u32                                          get_and_inc_inputindex(void) {
      ++inputblock_;
      return inputindex_++;
	}

    bool                                         find_diskfile(DiskFile_map_type::const_accessor& a, DiskFile* key) {
      return openfiles_.find(a, key);
    }
    bool                                         insert_diskfile(DiskFile_map_type::accessor& a, DiskFile* key) {
      return openfiles_.insert(a, key);
    }
  };

  template <typename BUFFER>
  class pipeline_state : public pipeline_state_base {
  private:
    std::vector< BUFFER, tbb::cache_aligned_allocator<BUFFER> > inputbuffers_;
    size_t                                                      inputbuffersidx_; // where to start searching for next buffer

  public:
    pipeline_state(
      u64                                        chunksize,
      u32                                        missingblockcount,
      size_t                                     blocklength,
      u64                                        blockoffset,
      vector<DataBlock*>&                        inputblocks) :
      pipeline_state_base(chunksize, missingblockcount, blocklength, blockoffset, inputblocks),
      inputbuffersidx_(0) {
      const size_t n_buffer = tbb::task_scheduler_init::default_num_threads() + 1;
      inputbuffers_.resize(n_buffer);
      for (size_t i = 0; i != n_buffer; ++i)
        if (!inputbuffers_[i].alloc((size_t)chunksize))
          throw 1;
    }

    BUFFER* first_available_buffer(void) {
      for (;;) {
        size_t off = inputbuffersidx_;
        size_t n_buffer = inputbuffers_.size();
        for (size_t i = 0; i != n_buffer; ++i) {
          if (try_to_acquire(inputbuffers_[off])) {
//printf("first_available_buffer() -> %p=inputbuffer->acquired()\n", &inputbuffers_[off]);
            return &inputbuffers_[off];
          }

          if (n_buffer == ++off) off = 0;
        }

//printf("the pause that refreshes...\n");
        tbb::this_tbb_thread::sleep( tbb::tick_count::interval_t(0.001) ); // pause for 1ms
      }
      //assert(false);
      //return NULL;
    }

    void release(BUFFER* b) {
//printf("release() -> %p=inputbuffer->release()\n", b);
      if (0 == pipeline_state_base::release(*b))
        inputbuffersidx_ = b - &inputbuffers_[0];
    }
  };

  template <typename SUBCLASS, typename BUFFER>
  class filter_read_base : public tbb::filter {
  private:
    filter_read_base& operator=(const filter_read_base&); // assignment disallowed
  protected:
    typedef pipeline_state<BUFFER> state_type;
    state_type& state_;
  public:
    filter_read_base(state_type& s) :
      tbb::filter(false /* tbb::filter::parallel */), state_(s) {}
    virtual void* operator()(void*);
  };

  template <typename SUBCLASS, typename BUFFER>
  //virtual
  void* filter_read_base<SUBCLASS, BUFFER>::operator()(void*) {
    if (!state_.is_ok())
        return NULL; // abort

    vector<DataBlock*>::iterator inputblock;
    BUFFER*                      inputbuffer;

    // try to acquire a buffer (this should always succeed)
    inputbuffer = state_.first_available_buffer();
    assert(NULL != inputbuffer);

    {
      u32 inputindex;

      {
        tbb::mutex::scoped_lock l(state_.inputblock_mutex());

        inputblock = state_.inputblock();
        if (inputblock == state_.inputblocks_end())
          return NULL; // finished

        inputindex = state_.get_and_inc_inputindex();

        static_cast<SUBCLASS*> (this)->on_mutex_held(inputbuffer);
      }

//printf("inputindex=%u\n", inputindex);

      inputbuffer->set_inputindex(inputindex);
    }

    // For each input block

    { // if the file is not opened then do only one open call
      DiskFile* df = (*inputblock)->GetDiskFile();

      typename state_type::DiskFile_map_type::const_accessor fa;
      while (!state_.find_diskfile(fa, df)) {
//printf("opening DiskFile %s\n", df->FileName().c_str());
        // if this thread was the one that inserted df into the map then open the file
        // (otherwise the file is double opened)

        // There was a race condition here: df is not open, thread 1 queries the hash_map and
        // finds no entry so it calls insert(), thread 2 then queries the hash_map and finds
        // the entry so it then tries to read from the file which thread 1 has yet to open.
        // This race is avoided by using a write-accessor during the insert() call: this will
        // block other threads from trying to use the not-yet-opened-file.
        typename state_type::DiskFile_map_type::accessor ia; // "insert accessor"
        if (state_.insert_diskfile(ia, df)) {
          // The winner gets here and is the one responsible for opening file;
          // other threads trying to access 'df' will now block in the find() call above.
          if (!df->Open(true)) { // open file for async I/O
//printf("opening DiskFile %s failed\n", df->FileName().c_str());
            state_.set_not_ok();
            return NULL;
          }

          // Release the accessor lock 'ia' and thus allow other threads to access the
          // now-open file. Now that df is in the map, the 'fa' accessor can acquire it.
        } else {
          // The loser must try again until it has read-only access to the key 'df' via the
          // above find(), because although the file is now in the hash_map, it may not yet be open.
        }
      }

      // since the data is read/written asynchronously, the const_accessor 'fa' can be released
    }

    {
      // Read data from the current input block
      if (!(*inputblock)->ReadDataAsync(inputbuffer->get_aiocb(), state_.blockoffset(),
                                        state_.blocklength(), inputbuffer->get())) {
//printf("start reading DiskFile %s failed\n", (*inputblock)->GetDiskFile()->FileName().c_str());
        state_.set_not_ok();
        state_.release(inputbuffer);
        return NULL;
      }

      // at this point, returning to caller is possible if another pipeline stage is inserted: it
      // would allow another async read to be requested or other processing to occur.

      inputbuffer->get_aiocb().suspend_until_completed();
      if (!inputbuffer->get_aiocb().completedOK() || !static_cast<SUBCLASS*> (this)->on_inputbuffer_read(inputbuffer)) {
//printf("completion of reading DiskFile %s failed\n", (*inputblock)->GetDiskFile()->FileName().c_str());
        state_.set_not_ok();
        state_.release(inputbuffer);
        return NULL;
      }
    }

    return inputbuffer;
  }

  template <typename SUBCLASS, typename BUFFER, typename DELEGATE>
  class filter_process_base : public tbb::filter {
    typedef DELEGATE delegate_type;
    delegate_type& delegate_;
  protected:
    typedef pipeline_state<BUFFER> state_type;
    state_type& state_;
  public:
    filter_process_base(delegate_type& delegate, state_type& s) :
      tbb::filter(false /* SERIAL tbb::filter::parallel */), delegate_(delegate), state_(s) {}
    virtual void* operator()(void*);
  };

  template <typename SUBCLASS, typename BUFFER, typename DELEGATE>
  //virtual
  void* filter_process_base<SUBCLASS, BUFFER, DELEGATE>::operator()(void* item) {
    BUFFER* inputbuffer = static_cast<BUFFER*> (item);
    assert(NULL != inputbuffer);
//printf("filter_process_base::operator()\n");

//printf("inputbuffer->get_inputindex()=%u\n", inputbuffer->get_inputindex());
    delegate_.ProcessDataConcurrently(state_.blocklength(), inputbuffer->get_inputindex(), inputbuffer->get());

    if (buffer::ASYNC_WRITE == inputbuffer->get_write_status()) {
      inputbuffer->get_aiocb().suspend_until_completed();
      if (!inputbuffer->get_aiocb().completedOK()) {
        state_.set_not_ok();
//printf("writing inputbuffer=%p completed unsuccessfully\n", inputbuffer);
      }
      inputbuffer->set_write_status(buffer::NONE);
    }

//printf("filter_process_base::operator() -> %p=inputbuffer->release()\n", inputbuffer);
    state_.release(inputbuffer);
//printf("released buffer %u\n", inputbuffer - filter_read::inputbuffers_);
    return NULL;
  }

  #endif
#endif

