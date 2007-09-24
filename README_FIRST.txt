--- Introduction ---


This is a concurrent (multithreaded) version of par2cmdline 0.4, a utility to
create and repair data files using Reed Solomon coding. par2 parity archives
are commonly used on Usenet postings to allow corrupted postings to be
repaired instead of needing the original poster to repost the corrupted
file(s).

For more information about par2, go to this web site:

http://parchive.sourceforge.net/

The original version of par2cmdline 0.4 was downloaded from:

http://sourceforge.net/projects/parchive


This version has been modified to utilise the Intel Thread Building Blocks 2.0
library, which enables it to process files concurrently instead of the
original version's serial processing. Computers with more than one CPU or core
such as those using Intel Core Duo, Intel Pentium D, or AMD Athlon X2 CPUs can
now create or repair par2 archives much quicker than the original version. For
example, dual core machines can achieve near-double performance when creating
or repairing.

The Intel Thread Building Blocks 2.0 library is obtained from:

http://osstbb.intel.com/

The licensing of this source code has not been modified: it is still published
under the GPLv2 (or later), and the COPYING file is included in this
distribution as per the GPL.


To download the source code or some operating system builds of the
concurrent version of par2cmdline 0.4, go to:

http://www.chuchusoft.com/par2_tbb


--- Building and installing on UNIX type systems ---


This modified version has been built and tested on Mac OS X 10.4.10 using GCC 4.

For UNIX or similar systems, the included configure script should be used to
generate a makefile which is then built with a Make utility. Before using
them however, you may need to modify the configure scripts as detailed below.

Because this version depends on the Intel Thread Building Blocks 2.0 library, you
will need to tell the build system where the headers and libraries are in order to
compile and link the program. In `Makefile.in', go to line 73:

DEFAULT_INCLUDES = -I. -I$(srcdir) -I. -l../tbb20_20070815oss_src/include

and modify the path to wherever your extracted Intel TBB files are. Note that it
should point at the `include' directory inside the main tbb directory.

For linking, the `Makefile.in' line 230:

LDADD = -lstdc++ -ltbb

has already had the tbb library added to the list of libraries to link against.
You will need to have libtbb.a (or libtbb.dylib or libtbb.so etc.) in your
library path (usually /usr/lib).


--- Building and installing on Windows operating systems ---


This modified version has been built and tested on Windows XP SP2 using Visual
C++ Express 2005.

For Windows, project files for Visual Studio .NET 2003 and Visual Studio 2005
have been included. Open a project file in Visual Studio and go to the project
properties window. For the C/C++ include paths, make sure the path to where
you extracted the Intel TBB files is correct. Similarly for the linker paths.

To run the built binary, make sure the Intel TBB dynamic link library is in
the library path - typically the tbb.dll file will be placed in either
%WINDIR%\System32 or in the directory that the par2.exe file is in.


--- Technical Details ---


All source code modifications have been isolated to blocks that have this form:

#if WANT_CONCURRENT

  <code added for concurrency>

#else

  <original code>

#endif

to make it easier to see what was modified and how it was done.

The technique used to modify the original code was:

[1] add timing code to instrument/document the places where concurrency would be of
    benefit. The CTimeInterval class was used to time sections of the code.
[2] decide which functions to make concurrent, based on the timing information
    obtained in step [1].
[3] for each function to make concurrent, study it and its sub-functions for
    concurrent access problems (shared data points)
[4] read the Intel TBB tutorials and reference manual to learn how to use the
    library to convert serial code to concurrent code

It was then decided to apply concurrency to:

- loading of recovery packets (par2 files), which necessitated changes to some member
  variables in par2repairer.h:
  - sourcefilemap [LoadDescriptionPacket, LoadVerificationPacket]
  - recoverypacketmap [LoadRecoveryPacket]
  - mainpacket [LoadMainPacket]
  - creatorpacket [LoadCreatorPacket]
  They were changed to use concurrent-safe containers/wrappers. To handle concurrent
  access to pointer-based member variables, the pointers are wrapped in atomic<T>
  wrappers. tbb::atomic<T> does not have operator-> which is needed to deference
  the wrapped pointers so a sub-class of tbb::atomic<T> was created, named
  atomic_ptr<T>. For maps and vectors, tbb's concurrent_hash_map and concurrent_vector
  were used.
  Because DiskFileMap needed to be accessed concurrently, a concurrent version of it
  was created (class ConcurrentDiskFileMap)
- source file verification
- repairing data blocks

In the original version, progress information was written to cout (stdout) in a serial
manner, but the concurrent version would produce garbled overlapping output unless
output was made concurrent-safe. This was achieved in two ways: for simple infrequent
output routines, a simple mutex was used to gate access to cout to only one thread at
a time. For frequent use of cout, such as during the repair process, an atomic integer
variable was used to gate access, but *without* blocking a thread that would have
otherwise been blocked if a mutex had been used instead. The code used is:

  if (0 == cout_in_use.compare_and_swap(outputendindex, 0)) { // <= this version doesn't block - only need 1 thread to write to cout
    cout << "Processing: " << newfraction/10 << '.' << newfraction%10 << "%\r" << flush;
    cout_in_use = 0;
  }

Initially cout_in_use is set to zero so that the first thread to put its value of
outputendindex into cout_in_use will get a zero back from cout_in_use.compare_and_swap()
and therefore enter the 'true block' of the 'if' statement. Other threads that then try
to put their value of outputendindex into cout_in_use while the first thread is still
using cout will fail to do so and so they will skip the 'true block' but they won't block.

For par2 creation, similar modifications were made to the source code that also allowed
concurrent processing to occur.

To convert from serial to concurrent operation, for() loops were changed to using Intel
TBB parallel_for() calls, with a functor object (callback) supplied to provide the body
of the parallel for loop. To access member variable in the body of the parallel loop,
new member functions were added so that the functor's operator() could dispatch into the
original object to do the for loop body's processing.

It should be noted that there are two notable parts of the program that could not be
made concurrent: (1) file verification involves computing MD5 hashes for the entire file
but computing the hash is an inherently serial computation, and (2) computing the Reed-
Solomon matrix for use in creation or repair involves matrix multiplication over a Galois
field, which is also an inherently serial computation and so it too could not be made into
a concurrent operation.

Nevertheless, the majority of the program's execution time is spent either repairing the
lost data, or in creating the redundancy information for later repair, and both of these
operations were able to be made concurrent with a near twice speedup on the dual core
machines that the concurrent version was tested on.

Note that it is important that the computer has sufficient memory (1) to allow the caching
of data and (2) to avoid virtual memory swapping, otherwise the creation or repair process
will become I/O bound instead of CPU bound. Computers with 1 to 2GB of RAM should have
enough memory to not be I/O bound when creating or repairing parity/data files.


--- About this version ---


The changes in this version are:

- the original par2cmdline-0.4 sources were not able to process files
larger than 2GB on the Win32 platform because diskfile.cpp used the
stat() function which only returns a signed 32-bit number on Win32.
This was changed to use _stati64() which returns a proper 64-bit file
size. Note that the FAT32 file system from the Windows 95 era does not
support files larger than 1 GB so this change is really applicable only
to files on NTFS disks - the default file system on Windows 2000/XP/Vista.

Vincent Tan.
September 24, 2007.

//
//  Modifications for concurrent processing Copyright (c) 2007 Vincent Tan.
//  Search for "#if WANT_CONCURRENT" for concurrent code.
//  Concurrent processing utilises Intel Thread Building Blocks 2.0,
//  Copyright (c) 2007 Intel Corp.
//
