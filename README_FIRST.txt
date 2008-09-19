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


This version has been modified to utilise the Intel Threading Building Blocks
2.1 library, which enables it to process files concurrently instead of the
original version's serial processing. Computers with more than one CPU or core
such as those using Intel Core Duo, Intel Core Duo 2, or AMD Athlon X2 CPUs
can now create or repair par2 archives much quicker than the original version.
For example, dual core machines can achieve near-double performance when
creating or repairing.

The Intel Threading Building Blocks 2.1 library is obtained from:

http://osstbb.intel.com/

The licensing of this source code has not been modified: it is still published
under the GPLv2 (or later), and the COPYING file is included in this
distribution as per the GPL.


To download the source code or some operating system builds of the
concurrent version of par2cmdline 0.4, go to:

http://www.chuchusoft.com/par2_tbb


--- Installing the pre-built Windows (32-bit) version ---


The Windows version is a 32-bit Windows build of the concurrent version of
par2cmdline 0.4. It is distributed as an executable (par2.exe) along
with the required Intel Threading Building Blocks 2.1 library (tbb.dll)
which comes from the tbb21_009oss_win.tar.gz distribution.

The par2.exe and tbb.dll files included in this distribution require
version 7.1 of the Microsoft C runtime libraries, which are probably
already on your PC if it is running Windows 2000, Windows XP or
Windows Vista. The Microsoft C runtime libraries are named MSVCP71.DLL
and MSVCR71.DLL and are most likely to be in the C:\Windows\system32
folder.

To install, place the par2.exe and tbb.dll files in a folder and
invoke them from the command line.

To uninstall, delete the par2.exe and tbb.dll files along with any
files from the distribution folder.


--- Installing the pre-built Mac OS X version ---


The Mac version is a "fat" universal build of the concurrent version
of par2cmdline 0.4 for Mac OS X 10.4 (32-bit binaries) and 10.5 (64-bit
binaries). In other words, the par2 executable file contains both a 32-bit
x86/PowerPC and a 64-bit x86_64/PowerPC-64-bit build of the par2 sources.
It is distributed as an executable (par2) along with the required Intel
Threading Building Blocks 2.1 library (libtbb.dylib). The libtbb.dylib file
is also "fat" universal (32-bit and 64-bit versions for x86/ppc/x86_64/ppc64
are contained inside it).

To install, place the par2 and libtbb.dylib files in a folder and
invoke them from the command line.

To uninstall, delete the par2 and libtbb.dylib files along with any
files from the distribution folder.


--- Installing the pre-built Linux version ---


The Linux version is a 32-bit i386 build of the concurrent version of
par2cmdline 0.4 for GNU/Linux kernel version 2.6 with GCC 4. It is
distributed as an executable (par2) along with the required Intel
Threading Building Blocks 2.1 library (libtbb.so).

To install, place the par2 and libtbb.so files in a folder and
invoke them from the command line.

To uninstall, delete the par2 and libtbb.so files along with any
files from the distribution folder.


--- Installing the pre-built FreeBSD version ---


Both the 32-bit and 64-bit binaries were built using RELEASE 7.0 of FreeBSD.

To install: copy libtbb.so to /usr/local/lib, copy par2 to a convenient
location, eg, /usr/local/bin, then remove the distribution directory. You
will need superuser permission to copy files to the /usr/local area.

To uninstall, delete the par2 and libtbb.so files along with any
files from the distribution folder.


--- Building and installing on UNIX type systems ---


For UNIX or similar systems, the included configure script should be used to
generate a makefile which is then built with a Make utility. Before using
them however, you may need to modify the configure scripts as detailed below.

Because this version depends on the Intel Threading Building Blocks 2.1 library,
you will need to tell the build system where the headers and libraries are in
order to compile and link the program. There are 2 ways to do this: use the
tbbvars.sh script included in TBB to add the appropriate environment variables,
or manually modify the Makefile to use the appropriate paths. The tbbvars.sh
file is in the tbb<version>oss_src/build directory. To manually modify the
Makefile:

  In `Makefile.am', go to line 59 (Darwin/Mac OS X):

AM_CXXFLAGS = -Wall -I../tbb21_009oss/include -gfull -O3 -fvisibility=hidden -fvisibility-inlines-hidden

  or line 63 (other POSIX systems):

AM_CXXFLAGS = -Wall -I../tbb21_009oss/include

and modify the path to wherever your extracted Intel TBB files are. Note that it
should point at the `include' directory inside the main tbb directory.

For linking, `Makefile.am' line 57:

LDADD = -lstdc++ -ltbb -L.

has already had the tbb library added to the list of libraries to link against.
You will need to have libtbb.a (or libtbb.dylib or libtbb.so etc.) in your
library path (usually /usr/lib).

Alternatively, if the TBB library is not in a standard library directory (or
on the linker's list of library paths) then add a library path so the linker
can link to the TBB:

LDADD = -lstdc++ -ltbb -L<directory>

For example:

LDADD = -lstdc++ -ltbb -L.

The Mac OS X distribution of this project is built using a relative-path
for the dynamic library. Please see the next section for more information.

The GNU/Linux distribution of this project is built using a relative-path
for the dynamic library (by passing the "-R $ORIGIN" option to the linker).


--- Building and installing on Mac OS X systems ---


The Mac version is a "fat" universal build of the concurrent version
of par2cmdline 0.4 for Mac OS X 10.4 (32-bit binaries) and 10.5 (64-bit
binaries). In other words, the par2 executable file contains both a 32-bit
x86/PowerPC and a 64-bit x86_64/PowerPC-64-bit build of the par2 sources.
It is distributed as an executable (par2) along with the required Intel
Threading Building Blocks 2.1 library (libtbb.dylib). The libtbb.dylib file
is also "fat" universal (32-bit and 64-bit versions for x86/ppc/x86_64/ppc64
are contained inside it).

The par2 32-bit executable is built for 10.4, and the 64-bit executable is
built for 10.5, which are then symbol stripped and combined using the lipo
tool. The 64-bit executable needs to be built for 10.5 because the 10.4
build of the 64-bit executable was found to (1) cause the "fat" executable
to crash when it was run under 10.5, and (2) not be able to correctly read
par2 files when those files resided on a SMB server (ie, a shared folder on
a Windows computer). Combining the mixed-OS executables solves both of these
problems (see the 20080116 version release notes below for details).

The libtbb.dylib file is built from the TBB 2.0 tbb21_009oss_src.tar.gz
distribution. It was built for the x86, ppc, x86_64 and ppc64 architectures
and will therefore run on all Macs that support 10.4 or 10.5.

Normally, the libtbb.dylib file is built so that for a client program to use
it, it would usually have to be placed in /usr/lib, which would therefore
require administrator privileges to install it onto a Mac OS X system. The
version included in this distribution does not require that it be installed,
and is therefore usable "out of the box". To implement this change, the
macos.gcc.inc file was modified with this line:

LIB_LINK_FLAGS = -dynamiclib -Wl,-exported_symbols_list,$(TBB.DEF) -Wl,-install_name,@executable_path/$@


The par2 executable has been symbol stripped (using the 'strip' command line
tool).


--- Building and installing on Windows operating systems ---


This modified version has been built and tested on Windows XP SP2 using Visual
C++ Express 2008.

For Windows, the project file for Visual Studio 2008 has been included. Open
the project file in Visual Studio and go to the project properties window.
For the C/C++ include paths, make sure the path to where you extracted the
Intel TBB files is correct. Similarly for the linker paths.

To run the built binary, make sure the Intel TBB dynamic link library is in
the library path - typically the tbb.dll file will be placed in either
%WINDIR%\System32 or in the directory that the par2.exe file is in.

The Windows distribution of this project is built with Visual C++ 2008 Express
Edition but the executable is linked against the Visual Studio .NET 2003's C
runtime library to avoid having to distribute the Visual C++ 2008's C runtime
library.

To build this version, download the source tarball from the website and use the
included vcproj with Visual C++ Express 2008. You will need to ensure that
the include and library paths that point to the PSDK are *above* the ones
that point to Visual C++'s folders so that the Microsoft C Runtime that is
used to build the program are from the older version 7.1 library and not
the version 9.0 library that comes with Visual C++ Express 2008.

In order to get things to link, the project has been modified according to
the instructions in the "Using VS2005 to ship legacy code for XP and
Windows 2000.html" file which is located in the "Using VS2005 to ship
legacy code for XP and Windows 2000" folder. You will also need to copy
the CxxFrameHandler3_to_CxxFrameHandler.obj file to your
par2cmdline-0.4-tbb-<version> folder.



--- Building and installing on FreeBSD ---


Instructions:

[1] build and install TBB
- extract TBB from the source archive.
- on a command line, execute:

  cp -r <TBB-src>/include/tbb /usr/local/include
  cd <TBB-src> && /usr/local/bin/gmake
  # change the next line to match your machine's configuration:
  cp <TBB-src>/build/FreeBSD_em64t_gcc_cc4.1.0_kernel7.0_release/libtbb.so /usr/local/lib

[2] build and install par2cmdline-0.4-tbb
- extract and build par2cmdline-0.4-tbb using tar, ./configure, and make
- copy built binary to where you want to install it (eg, /usr/local/bin)

[3] cleanup
- remove <TBB-src> and par2cmdline-0.4-tbb source directories


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


--- Version History ---


The changes in the 20080919 version are:

- added more information to a few of the error messages to make it easier to specify
  block counts, etc. when using the -d option.
- redundancy can now be specified using floating point values instead of integral values,
  eg, 8.5% instead of 8% or 9%.
- added the -0 option to create dummy par2 files. This was done so that the actual size
  of the par2 files can be quickly determined. For example, suppose you wish to fill up
  a CD-R's or DVD-R's remaining empty space with par2 files of the files filling up the
  disc, then by using the -0 option, you can quickly work out whether the par2 files
  will fit and by how much, which in turn allows you to maximize the use of the remaining
  empty space (you would alter the block count number and/or size so that the optimal
  number of blocks are created to fill up the remaining space). To determine how much
  CD-R or DVD-R space you have to fill, find out how many blocks your blank disc has
  (using a burning program such as ImgBurn [Windows]) and how many blocks your data
  would occupy when burned (using an image creation program such as mkisofs [all
  platforms] which has a handy -print-size option). ImgBurn [Windows] can also tell
  you how many blocks you have for filling if you use its 'build' command.
  WARNING: be careful when using this command that you don't burn the dummy par2 files
  that it creates because they don't have any valid data in them. Remember, they are
  created only to determine the actual size of the real par2 files that would be
  created if you had not used the -0 option.
- added MMX-based code from Paul Houle's phpar2_12src version of par2cmdline-0.4. As
  a result, the repair and creation of par2 files using x86 or x86_64 MMX code is about
  20% faster than the scalar version in singlethreaded testing. Multithreaded testing
  showed no noticable improvement (ie, YMMV). The scalar version is used if your CPU
  is not MMX capable. MMX CPUs: Intel Pentium II and later, AMD Athlon64 and later.
- added asynchronous I/O for platforms that support such I/O: Mac OS X, Windows,
  GNU/Linux. This results in a small (~1-5%) improvement in throughput, especially for
  repairing. Unfortunately, using async I/O causes a crash under FreeBSD, so the
  pre-built binaries are built to only use synchronous I/O.
- first release of 32-bit and 64-bit PowerPC binaries for Mac OS X. The 32-bit version
  requires at least 10.4, and the 64-bit version requires at least 10.5. The 64-bit
  version is UNTESTED (because of lack of access to a G5 Mac).
- first release of a 64-bit x86_64 binary for GNU/Linux. Tested under the 64-bit
  version of Gentoo 2008.0.
- the 64-bit Windows binary is built using the tbb20_20080408oss release of the TBB;
  the Mac, GNU/Linux, FreeBSD and 32-bit Windows binaries are built using the
  tbb21_009oss release of the TBB. The tbb21_009oss release does not support the
  VC7.1 runtime libraries on Win64 so it was necessary to fallback to a previous
  version for the Windows 64-bit binary.

The changes in the 20080420 version are:

- added the -t0 option to allow verification to be done serially but still perform
  repair concurrently, and for creation, MD5 checksumming will be done serially
  and par2 data creation will be done concurrently. The default is to perform
  all operations concurrently, so if you want the new behaviour, you will need to
  manually specify -t0 on the command line or build your own custom version of
  the executable.
- if the realpath() API returned NULL, the par2 files created would end up with
  the name of the first file in the list of files to create par2 files for. Fixed.
- no longer includes duplicate file names in the list of files to create redundancy
  data for (which would otherwise bloat the .par2 files)
- now displays the instruction set being executed
- updated to use the tbb20_017oss_src.tar.gz version of the Intel TBB library.

The changes in the 20080203 version are:

- the Linux version wasn't working because it was not built correctly: the
  reedsolomon-inner-i386-posix.s was using an incorrect include directive. Fixed.
  *** WARNING ***
  A consequence of this error is that par2 files created with the 20080116 Linux
  binary contain incorrect repair data and therefore cannot be used to repair
  data files. The par2 files will need to be created again using either the
  20071128 build of the Linux binary or this build of it.
  *** WARNING ***
- tweaked the Makefile and par2cmdline.h to allow for building under FreeBSD.
- first release of 32-bit and 64-bit binaries for FreeBSD (built under RELEASE 6.2).
- updated to use the 20080115 version of the Intel TBB library.

The changes in the 20080116 version are:

- the initial processing (creation) and verification (repair) of target files
  is now performed serially because of complaints that concurrent processing
  was causing disk thrashing. Since this part of the program's operation is
  mostly I/O bound, the change back to serial processing is a reasonable change.
- full paths are now only displayed when a -d parameter is given to the
  program, otherwise the original behavior of displaying just the file name
  now occurs.
- Unicode support was added. This requires some explanation.

  Windows version: previous versions processed file names and directory
  paths using the default code page for non-Unicode programs, which is
  typically whatever the current locale setting is. In other words,
  file names that had characters that could not be represented in the
  default code page ended up being mangled by the program, resulting
  in .par2 files which contained mangled file names (directory names
  also suffered mangling). Such .par2 files could not be used on other
  computers unless they also used the same code page, which for POSIX
  systems is very unlikely. The correct solution is to store and retrieve
  all file names and directory paths using a Unicode representation.
  To keep some backward compatibility, the names should be stored in
  an 8-bit-per-character format (so that older .par2 files can still
  be processed by the program), so decomposed (a.k.a. composite) UTF-8
  was chosen as the canonical file name encoding for the storage of
  file names and directory paths in .par2 files.
  To implement this change, the Windows version now takes all file
  names from the operating system as precomposed UTF-16 and converts
  them to decomposed UTF-8 strings which are stored in memory and
  in .par2 files. If the operating system needs to use the string,
  it is converted back into precomposed UTF-16 and then passed to
  the OS for use.

  POSIX version: it is assumed that the operating system will deliver
  and accept decomposed (a.k.a. composite) UTF-8 characters to/from
  the program so no conversion is performed. Darwin / Mac OS X is
  one such system that passes and accepts UTF-8 character strings, so
  the Mac OS X version of the program works correctly with .par2
  files containing Unicode file names. If the operating system
  does not deliver nor accept decomposed UTF-8 character strings,
  this version (and previous versions) will not create .par2 files
  that contain Unicode file names or directory paths, and which
  will cause mangled file/directory names when used on other
  operating systems.

  Summary:
  [1] for .par2 files created on Windows using a version of
  this program prior to this version and which contain non-ASCII
  characters (characters outside the range of 0 - 127 (0x00 - 0x7F)
  in numeric value, this program will be able to use such files
  but will probably complain about missing files or will create
  repaired files using the wrong file name or directory path, ie,
  file name mangling will occur.
  [2] for .par2 files created on UTF-8 based operating systems
  using a prior version of this program, this version will be
  able to correctly use such files (ie, the changes made to the
  program should not cause any change in behavior, and no file
  name mangling will occur).
  [3] for .par2 files created on non-UTF-8 based operating systems
  using a prior version of this program, this version will be
  able to use such files but file name mangling will occur.
  [4] for .par2 files created on UTF-8 based operating systems
  using this version of this program, file name mangling will
  not occur.
  [5] for .par2 files created on non-UTF-8 based operating systems
  using this version of this program, file name mangling will
  occur.

- split up the reedsolomon-inner.s file so that it builds
  correctly under Darwin and other POSIX systems.
- changed the way the pre-built Mac OS X version is built because
  the 64-bit version built under 10.4 (1) crashes when it is run
  under 10.5, and (2) does not read par2 files when the files
  reside on a SMB server (ie, a shared folder on a Windows
  computer) because 10.4's SMB client software appears to
  incorrectly service 64-bit client programs. These problems only
  occurred with the 64-bit version; the 32-bit version works
  correctly.

  To solve both of these problems, the pre-built executable is now
  released containing both a 32-bit executable built under 10.4
  and a 64-bit executable built under 10.5. When run under 10.4,
  the 64-bit executable does not execute because it is linked
  against the 10.5 system libraries, so under 10.4, only the
  32-bit executable is executed, which solves problem (2). When
  run under 10.5 on a 64-bit x86 computer, the 64-bit executable
  executes, which solves problem (1), and because 10.5's SMB
  client correctly services 64-bit client programs, problem (2)
  is solved.

The changes in the 20071128 version are:

- if par2 was asked to verify/repair with just a single .par2 file, it would
  crash. Fixed.
- built for GNU/Linux using the Gentoo distribution (i386 version).
- updated to use the 20071030 version of the Intel TBB library.

The changes in the 20071121 version are:

- changed several concurrent loops from using TBB's parallel_for to
  parallel_while so that files will be processed in a sequential (but
  still concurrent/threaded) manner. For example, 100 files were
  previously processed on dual core machines as:
  Thread 1: file 1, file 2, file 3, ..., file 50
  Thread 2: file 50, file 51, file 52, ..., file 100
  which caused hard disk head thrashing. Now the threads will
  process the files from file 1 to file 100 on a
  first-come-first-served basis.
- limited the rate at which cout was called to at most 10 times per
  second.
- when building for i386 using GCC, this version will now build
  with an assembler version of the inner Reed-Solomon loop because
  the code generated by GCC was not as fast/small as the Visual
  C++ version. Doing this should bring the GCC-built (POSIX)
  version's speed up to that of the Visual C++ (Windows) version.
- for canonicalising paths on POSIX systems, the program will now
  try to use the realpath() API, if it's available, instead of the
  fragile code in the original version.
- on POSIX systems, attempting to use a parameter of "-d." for par2
  creation would cause the program to fail because it was not
  resolving a partial path to a canonical full path. Fixed.

The changes in the 20071022 version are:

- synchronised the sources with the version of par2cmdline in the CVS at <http://sourceforge.net/projects/parchive>
- built against the 20070927 version of the Intel TBB
- tweaked the inner loop of the Reed Solomon code so that the compiler
  will produce faster/better/smaller code (which may or may not speed up
  the program).
- added support for creating and repairing data files in directory trees
  via the new -d<directory> command line switch.

  The original modifications for this were done by Pacer:

<http://www.quickpar.co.uk/forum/viewtopic.php4?t=460&amp;start=0&amp;postdays=0&amp;postorder=asc&amp;highlight=&amp>

  This version defaults to the original behaviour of par2cmdline: if no
  -d switch is provided then the data files are expected to be in the same
  directory that the .par2 files are in.

  Providing a -d switch will change the way that par2cmdline behaves as follows.
  For par2 creation, any file inside the provided <directory> will have
  its sub-path stored in the par2 files. For par2 repair, files for
  verification/repair will be searched for inside the provided <directory>.

  Example:

    in /users/home/vincent/pictures/ there is
       2007_01_vacation_fiji
         01.jpg
         02.jpg
         03.jpg
         04.jpg
       2007_03_business_trip_usa
         01.jpg
         02.jpg
       2007_06_wedding
         01.jpg
         02.jpg
         03.jpg
         04.jpg
         05.jpg
         06.jpg

    Using the command:

./par2 c -d/users/home/vincent/pictures/ /users/home/vincent/pictures.par2 /users/home/vincent/pictures

    will create par2 files in /users/home/vincent containing sub-paths such as:

      2007_01_vacation_fiji/01.jpg
      2007_01_vacation_fiji/02.jpg
      2007_01_vacation_fiji/03.jpg
      2007_01_vacation_fiji/04.jpg
      2007_03_business_trip_usa/01.jpg
      2007_03_business_trip_usa/02.jpg
      2007_06_wedding/01.jpg
      etc. etc.

    If you later try to repair the files which are now in /users/home/joe/pictures,
    you would use the command:

      ./par2 r -d/users/home/joe/pictures/ /users/home/joe/pictures.par2

    The par2 file could be anywhere on your disk: as long as the -d<directory>
    switch specifies the root of the files, the verification/repair will occur correctly.

    Notes:

    [1] the directory given to -d does not need to have a trailing '/' character.
    [2] on Windows, either / or \ can be used.
    [3] partial paths can be used. For example, if the current directory is
        /users/home/vincent, then this be used instead of the above command:

        ./par2 c -dpictures pictures.par2 pictures

    [4] if a directory has spaces or other characters that need escaping from the
        shell then the use of double quotes is recommended. For example:

        ./par2 c "-dpicture collection" "picture collection.par2" "picture collection"


The changes in the 20070927 version are:

- applied a fix for a bug reported by user 'shenhanc' in 
Par2CreatorSourceFile.cpp where a loop variable would not get
incremented when silent output was requested.

The changes in the 20070926 version are:

- fixed an integer overflow bug in Par2CreatorSourceFile.cpp which resulted
in incorrect MD5 hashes being stored in par2 files when they were created
from source files that were larger than or equal to 4GB in size. This bug
affected all 32-bit builds of the program. It did not affect the 64-bit
builds on those platforms where sizeof(size_t) == 8.

The changes in the 20070924 version are:

- the original par2cmdline-0.4 sources were not able to process files
larger than 2GB on the Win32 platform because diskfile.cpp used the
stat() function which only returns a signed 32-bit number on Win32.
This was changed to use _stati64() which returns a proper 64-bit file
size. Note that the FAT32 file system from the Windows 95 era does not
support files larger than 1 GB so this change is really applicable only
to files on NTFS disks - the default file system on Windows 2000/XP/Vista.

The changes in the 20070831 version are:

- modified to utilise Intel TBB 2.0.



Vincent Tan.
September 19, 2008.

//
//  Modifications for concurrent processing, Unicode support, and hierarchial
//  directory support are Copyright (c) 2007-2008 Vincent Tan.
//  Search for "#if WANT_CONCURRENT" for concurrent code.
//  Concurrent processing utilises Intel Thread Building Blocks 2.0,
//  Copyright (c) 2007 Intel Corp.
//
