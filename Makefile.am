##  This file is part of par2cmdline (a PAR 2.0 compatible file verification and
##  repair tool). See http://parchive.sourceforge.net for details of PAR 2.0.
##
##  Copyright (c) 2003 Peter Brian Clements
##  Modifications for specific OS support (Mac, Linux, FreeBSD), and x86/x86_64
##  assembly code building (c) 2008 Vincent Tan.
##
##  par2cmdline is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  par2cmdline is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

bin_PROGRAMS = par2

if AMD64
ARCH = x86_64
ARCH_MMX = x86_64
endif
if X86MMX
ARCH = i386
ARCH_MMX = i686
else
if X86CPU
ARCH = i386
ARCH_MMX = i686
endif
endif
if PPC64
ARCH = ppc64
endif
if PPC32
ARCH = ppc
endif

if PLATFORM_DARWIN
PLATFORM = darwin
FLAGS_ARCH = -arch $(ARCH)
ASMOBJECTS_PLATFORM = 
CXXFLAGS_DARWIN =                                 #  because the functions in the .s files process RS data
#CXXFLAGS_DARWIN = -fomit-frame-pointer           <= if you want GCC to produce slightly better scalar x86 code
#CXXFLAGS_DARWIN = -mmmx -fomit-frame-pointer     <= if you want GCC to produce SIMD code using instrinsic fns
else
PLATFORM = posix
FLAGS_ARCH =
ASMOBJECTS_PLATFORM = detect-mmx.s
endif

if AMD64
ASMOBJECTS = reedsolomon-$(ARCH)-scalar-$(PLATFORM).s reedsolomon-$(ARCH_MMX)-mmx-$(PLATFORM).s
endif
if X86CPU
ASMOBJECTS = reedsolomon-$(ARCH)-scalar-$(PLATFORM).s reedsolomon-$(ARCH_MMX)-mmx-$(PLATFORM).s $(ASMOBJECTS_PLATFORM)
endif

.s.o:
	$(CCASCOMPILE) $(FLAGS_ARCH) -c -o $@ $<

par2_SOURCES = par2cmdline.cpp par2cmdline.h \
	commandline.cpp commandline.h \
	crc.cpp crc.h \
	creatorpacket.cpp creatorpacket.h \
	criticalpacket.cpp criticalpacket.h \
	datablock.cpp datablock.h \
	descriptionpacket.cpp descriptionpacket.h \
	diskfile.cpp diskfile.h \
	filechecksummer.cpp filechecksummer.h \
	galois.cpp galois.h \
	letype.h \
	mainpacket.cpp mainpacket.h \
	md5.cpp md5.h \
	par1fileformat.cpp par1fileformat.h \
	par1repairer.cpp par1repairer.h \
	par1repairersourcefile.cpp par1repairersourcefile.h \
	par2creator.cpp par2creator.h \
	par2creatorsourcefile.cpp par2creatorsourcefile.h \
	par2fileformat.cpp par2fileformat.h \
	par2pipeline.cpp par2pipeline.h \
	par2repairer.cpp par2repairer.h \
	par2repairersourcefile.cpp par2repairersourcefile.h \
	recoverypacket.cpp recoverypacket.h \
	reedsolomon.cpp reedsolomon.h \
	verificationhashtable.cpp verificationhashtable.h \
	verificationpacket.cpp verificationpacket.h \
	$(ASMOBJECTS)

LDADD = -lstdc++ -ltbb -L.
if PLATFORM_DARWIN
AM_CXXFLAGS = -Wall -I$(top_srcdir)/../tbb21_009oss/include -gfull -O3 -fvisibility=hidden -fvisibility-inlines-hidden $(CXXFLAGS_DARWIN) $(FLAGS_ARCH)
if X86CPU
AM_CXXFLAGS += -isysroot /Developer/SDKs/MacOSX10.4u.sdk
AM_LDFLAGS = -mmacosx-version-min=10.4
endif
if PPC32
AM_CXXFLAGS += -isysroot /Developer/SDKs/MacOSX10.4u.sdk
AM_LDFLAGS = -mmacosx-version-min=10.4
endif
endif
if PLATFORM_FREEBSD
AM_LDFLAGS = -L/usr/local/lib
AM_CXXFLAGS = -Wall -I/usr/local/include $(FLAGS_ARCH)
endif
if PLATFORM_LINUX
AM_LDFLAGS = '-Wl,-R,$$ORIGIN'
AM_CXXFLAGS = -Wall -I$(top_srcdir)/../tbb21_009oss/include $(FLAGS_ARCH)
endif

EXTRA_DIST = PORTING ROADMAP par2cmdline.sln par2cmdline.vcproj \
	testdata.tar.gz pretest test1 test2 test3 test4 test5 test6 \
	posttest \
	detect-mmx.s \
	reedsolomon-i386-scalar-darwin.s \
	reedsolomon-i386-scalar-posix.s \
	reedsolomon-i386-scalar.s \
	reedsolomon-i686-mmx-darwin.s \
	reedsolomon-i686-mmx-posix.s \
	reedsolomon-i686-mmx.s \
	reedsolomon-x86_64-scalar-darwin.s \
	reedsolomon-x86_64-scalar-posix.s \
	reedsolomon-x86_64-scalar.s \
	reedsolomon-x86_64-mmx-darwin.s \
	reedsolomon-x86_64-mmx-posix.s \
	reedsolomon-x86_64-mmx.s

TESTS = pretest test1 test2 test3 test4 test5 test6 posttest

install-exec-hook :
	ln -f $(DESTDIR)$(bindir)/par2$(EXEEXT) $(DESTDIR)$(bindir)/par2create$(EXEEXT)
	ln -f $(DESTDIR)$(bindir)/par2$(EXEEXT) $(DESTDIR)$(bindir)/par2verify$(EXEEXT)
	ln -f $(DESTDIR)$(bindir)/par2$(EXEEXT) $(DESTDIR)$(bindir)/par2repair$(EXEEXT)

uninstall-hook :
	rm -f $(DESTDIR)$(bindir)/par2create$(EXEEXT)
	rm -f $(DESTDIR)$(bindir)/par2verify$(EXEEXT)
	rm -f $(DESTDIR)$(bindir)/par2repair$(EXEEXT)

