//  This file is part of par2cmdline (a PAR 2.0 compatible file verification and
//  repair tool). See http://parchive.sourceforge.net for details of PAR 2.0.
//
//  Copyright (c) 2003 Peter Brian Clements
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
//  Modifications for concurrent processing Copyright (c) 2007 Vincent Tan.
//  Search for "#if WANT_CONCURRENT" for concurrent code.
//  Concurrent processing utilises Intel Thread Building Blocks 2.0,
//  Copyright (c) 2007 Intel Corp.

#ifndef __PARCMDLINE_H__
#define __PARCMDLINE_H__


#ifdef WIN32
// Windows includes
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

// System includes
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <fcntl.h>
#include <assert.h>

#define snprintf _snprintf
#define stat _stati64 /* _stat64 */ /* so that files >= 4GB can be processed, was: #define stat _stat */

#define __LITTLE_ENDIAN 1234
#define __BIG_ENDIAN    4321
#define __PDP_ENDIAN    3412

#define __BYTE_ORDER __LITTLE_ENDIAN

typedef unsigned char    u8;
typedef unsigned short   u16;
typedef unsigned long    u32;
typedef unsigned __int64 u64;

#ifndef _SIZE_T_DEFINED
#  ifdef _WIN64
typedef unsigned __int64 size_t;
#  else
typedef unsigned int     size_t;
#  endif
#  define _SIZE_T_DEFINED
#endif


#else // WIN32
#ifdef HAVE_CONFIG_H

#include <config.h>

#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif

#ifdef HAVE_STDIO_H
#  include <stdio.h>
#endif

#if HAVE_DIRENT_H
#  include <dirent.h>
#  define NAMELEN(dirent) strlen((dirent)->d_name)
#else
#  define dirent direct
#  define NAMELEN(dirent) (dirent)->d_namelen
#  if HAVE_SYS_NDIR_H
#    include <sys/ndir.h>
#  endif
#  if HAVE_SYS_DIR_H
#    include <sys/dir.h>
#  endif
#  if HAVE_NDIR_H
#    include <ndir.h>
#  endif
#endif

#if STDC_HEADERS
#  include <string.h>
#else
#  if !HAVE_STRCHR
#    define strchr index
#    define strrchr rindex
#  endif
char *strchr(), *strrchr();
#  if !HAVE_MEMCPY
#    define memcpy(d, s, n) bcopy((s), (d), (n))
#    define memove(d, s, n) bcopy((s), (d), (n))
#  endif
#endif

#if HAVE_MEMORY_H
#  include <memory.h>
#endif

#if !HAVE_STRICMP
#  if HAVE_STRCASECMP
#    define stricmp strcasecmp
#  endif
#endif

#if HAVE_INTTYPES_H
#  include <inttypes.h>
#endif

#if HAVE_STDINT_H
#  include <stdint.h>
typedef uint8_t            u8;
typedef uint16_t           u16;
typedef uint32_t           u32;
typedef uint64_t           u64;
#else
typedef unsigned char      u8;
typedef unsigned short     u16;
typedef unsigned int       u32;
typedef unsigned long long u64;
#endif

#if HAVE_SYS_STAT_H
#  include <sys/stat.h>
#endif

#if HAVE_SYS_TYPES_H
#  include <sys/types.h>
#endif

#if HAVE_UNISTD_H
#  include <unistd.h>
#endif

#define _MAX_PATH 255

#if HAVE_ENDIAN_H
#  include <endian.h>
#  ifndef __LITTLE_ENDIAN
#    ifdef _LITTLE_ENDIAN
#      define __LITTLE_ENDIAN _LITTLE_ENDIAN
#      define __LITTLE_ENDIAN _LITTLE_ENDIAN
#      define __BIG_ENDIAN _BIG_ENDIAN
#      define __PDP_ENDIAN _PDP_ENDIAN
#    else
#      error <endian.h> does not define __LITTLE_ENDIAN etc.
#    endif
#  endif
#else
#  define __LITTLE_ENDIAN 1234
#  define __BIG_ENDIAN    4321
#  define __PDP_ENDIAN    3412
#  if WORDS_BIGENDIAN
#    define __BYTE_ORDER __BIG_ENDIAN
#  else
#    define __BYTE_ORDER __LITTLE_ENDIAN
#  endif
#endif

#else // HAVE_CONFIG_H

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <assert.h>

#include <errno.h>

#define _MAX_PATH 255
#define stricmp strcasecmp
#define _stat stat

typedef   unsigned char        u8;
typedef   unsigned short       u16;
typedef   unsigned int         u32;
typedef   unsigned long long   u64;

#endif
#endif

#ifdef WIN32
#define PATHSEP "\\"
#define ALTPATHSEP "/"
#else
#define PATHSEP "/"
#define ALTPATHSEP "\\"
#endif

// Return type of par2cmdline
typedef enum Result
{
  eSuccess                     = 0,

  eRepairPossible              = 1,  // Data files are damaged and there is
                                     // enough recovery data available to
                                     // repair them.

  eRepairNotPossible           = 2,  // Data files are damaged and there is
                                     // insufficient recovery data available
                                     // to be able to repair them.

  eInvalidCommandLineArguments = 3,  // There was something wrong with the
                                     // command line arguments

  eInsufficientCriticalData    = 4,  // The PAR2 files did not contain sufficient
                                     // information about the data files to be able
                                     // to verify them.

  eRepairFailed                = 5,  // Repair completed but the data files
                                     // still appear to be damaged.


  eFileIOError                 = 6,  // An error occured when accessing files
  eLogicError                  = 7,  // In internal error occurred
  eMemoryError                 = 8,  // Out of memory

} Result;

#define LONGMULTIPLY

// STL includes
#include <string>
#include <list>
#include <vector>
#include <map>
#include <algorithm>

#include <ctype.h>
#include <iostream>
#include <iomanip>

#include <cassert>

using namespace std;

#ifdef offsetof
#undef offsetof
#endif
#define offsetof(TYPE, MEMBER) ((size_t) ((char*)(&((TYPE *)1)->MEMBER) - (char*)1))

#define WANT_CONCURRENT 1

#if WANT_CONCURRENT
  #include "tbb/task_scheduler_init.h"
  #include "tbb/atomic.h"
  #include "tbb/concurrent_hash_map.h"
  #include "tbb/concurrent_vector.h"
  #include "tbb/tick_count.h"
  #include "tbb/blocked_range.h"
  #include "tbb/parallel_for.h"
  #include "tbb/mutex.h"

  class CTimeInterval {
  public:
    CTimeInterval(const std::string& label) :
      _label(label), _start(tbb::tick_count::now()), _done(false) {}
    ~CTimeInterval(void) {  emit();  }
    void  suppress_emission(void) { _done = true; }
    void  emit(void) {
      if (!_done) {
        _done  =  true;
        tbb::tick_count  end  =  tbb::tick_count::now();
        cout << _label << " took " << (end-_start).seconds() << " seconds." << endl;
      }
    }
  private:
    std::string     _label;
    tbb::tick_count _start;
    bool            _done;
  };

  #define WANT_PARALLEL_WHILE 1
  // using parallel_for() causes disk thrashing because it partitions
  // the files into large groups, each of which is iterated over by one
  // thread. For example, 100 files on a 2 CPU machine would be processed
  // in a manner like this:
  //
  // thread #1: file 1, file 2, file 3, ..., file 50
  // thread #2: file 51, file 52, file 53, ..., file 100
  //
  // using parallel_while allows the threads to iterate over the files
  // in sequential order; in effect, a FIFO queue is being implemented.

  #include "tbb/parallel_while.h"
  #include "../src/tbb/tbb_misc.h" // for tbb::DetectNumberOfWorkers(); it's a pity that tbb_misc.h is not in <tbb_home>/include/tbb/

  // === begin generic classes for use with parallel_while() ===

  template <typename ITEM>
  class item_stream {
    ITEM _item;
  public:
    bool pop_if_present( ITEM& item ) {
      if ( _item ) {
        item = _item;
        _item = get_next_item(_item);
        return true;
      } else {
        return false;
      }
    }

    item_stream(ITEM root_item) : _item(root_item) {}
  };

  template <typename BODY>
  class incrementing_parallel_while : public tbb::parallel_while<BODY> {
    tbb::atomic<size_t> _nexti;
  public:
    incrementing_parallel_while(size_t start_i = 0) { _nexti = start_i; }
    size_t get_next_i(void) const { return _nexti; }

    std::pair<bool, size_t> increment_next_i_up_to(size_t max_i) {
      size_t i = 1 + _nexti.fetch_and_increment();
      if (i < max_i)
        return std::pair<bool, size_t>(true, i);

      _nexti.fetch_and_decrement();
      return std::pair<bool, size_t>(false, 0);
    }
  };

  template <typename BODY>
  class incrementing_parallel_while_with_max : public incrementing_parallel_while<BODY> {
    size_t _maxi;
  public:
    incrementing_parallel_while_with_max(size_t start_i, size_t max_i) :
      incrementing_parallel_while<BODY>(start_i), _maxi(max_i) {}

    std::pair<bool, size_t> increment_next_i(void)
    { return incrementing_parallel_while<BODY>::increment_next_i_up_to(_maxi); }
  };

  template <typename ITEM, template <typename ITEM> class PARALLEL_WHILE = incrementing_parallel_while>
  class item_applier {
    PARALLEL_WHILE< item_applier<ITEM, PARALLEL_WHILE> >& _w;
  public:
    void operator()( ITEM item ) const {
      apply_to_item(item);
      if (!add_next_items(_w, item))
        dispose_item(item);
    }

    typedef ITEM argument_type;
    item_applier(PARALLEL_WHILE< item_applier<ITEM, PARALLEL_WHILE> >& w) : _w(w) {}
  };

  template <typename ITEM>
  static
  ITEM*
  get_next_item(ITEM* item)
  {
    return item->next();
  }

  template <typename ITEM>
  static
  void
  apply_to_item(ITEM* item)
  {
    item->apply();
  }

  template <typename ITEM>
  static
  void
  dispose_item(ITEM* item)
  {
    delete item;
  }

  // returns true if item was recycled into w (so caller should not dispose of item),
  // and false if item was not recycled (so caller MUST dispose of item)
  template <typename ITEM>
  static
  bool
  add_next_items(
    incrementing_parallel_while_with_max< item_applier<ITEM*,
                  incrementing_parallel_while_with_max> >& w,
    ITEM* item)
  {
    const size_t n = item->is_first() ? tbb::DetectNumberOfWorkers() : 1;

    bool res = false;
    std::pair<bool, size_t> pr(w.increment_next_i());
    if (pr.first && item->set_next_i(pr.second)) {
      w.add(item);
      res = true;

      for (size_t i = 1; i != n; ++i) {
        pr = w.increment_next_i();
        if (pr.first) {
          ITEM* clone = item->clone_for_next_i(pr.second);
          if (clone) {
            w.add(clone);
            continue;
          }
        }
        break;
      }
    }

    return res;
  }

  template <typename ITEM, template <typename ITEM> class PARALLEL_WHILE>
  static
  void
  parallel_while(ITEM* first_item, size_t item_count)
  {
    std::auto_ptr<ITEM> item(first_item); // capture first_item for exception safety
    PARALLEL_WHILE< item_applier<ITEM*, PARALLEL_WHILE> >
                                        w(0, item_count);
    item_applier<ITEM*, PARALLEL_WHILE> body(w);
    item_stream<ITEM*>                  stream(item.release());
    w.run( stream, body );
  }

  // === end generic classes for use with parallel_while() ===
#endif

#include "letype.h"
// par2cmdline includes

#include "galois.h"
#include "crc.h"
#include "md5.h"
#include "par2fileformat.h"
#include "commandline.h"
#include "reedsolomon.h"

#include "diskfile.h"
#include "datablock.h"

#include "criticalpacket.h"
#include "par2creatorsourcefile.h"

#include "mainpacket.h"
#include "creatorpacket.h"
#include "descriptionpacket.h"
#include "verificationpacket.h"
#include "recoverypacket.h"

#include "par2repairersourcefile.h"

#include "filechecksummer.h"
#include "verificationhashtable.h"

#include "par2creator.h"
#include "par2repairer.h"

#include "par1fileformat.h"
#include "par1repairersourcefile.h"
#include "par1repairer.h"

// Heap checking 
#ifdef _MSC_VER
#define _CRTDBG_MAP_ALLOC
#include <crtdbg.h>
#define DEBUG_NEW new(_NORMAL_BLOCK, THIS_FILE, __LINE__)
#endif

#endif // __PARCMDLINE_H__

