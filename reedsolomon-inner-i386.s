#  This file is part of par2cmdline (a PAR 2.0 compatible file verification and
#  repair tool). See http://parchive.sourceforge.net for details of PAR 2.0.
#
#  Copyright (c) 2007-2008 Vincent Tan.
#
#  par2cmdline is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  par2cmdline is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#  Modifications for concurrent processing, Unicode support, and hierarchial
#  directory support are Copyright (c) 2007-2008 Vincent Tan.
#  Search for "#if WANT_CONCURRENT" for concurrent code.
#  Concurrent processing utilises Intel Thread Building Blocks 2.0,
#  Copyright (c) 2007 Intel Corp.
#

#
# reedsolomon-inner-i386.s
#
# void ReedSolomonInnerLoop(const u32* src, const u32* end, u32* dst,
#                           const u16* L, const u16* H);
#

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%esi
	pushl	%edi

# System V i386 ABI says that EAX, ECX and EDX are volatile across function calls
#	pushl	%edx
#	pushl	%ecx
	pushl	%ebx
#	pushl	%eax

	subl	$0x1004, %esp
#
# setup tables in local stack frame
#
	movl	0x14(%ebp), %esi		# L
	movl	0x18(%ebp), %edi		# H
	xorl	%ebx, %ebx
	movl	$0x0100, %ecx

SetupLoop:
	movw	(%esi), %ax				# get an L entry
	addl	$0x02, %esi
	movzwl	%ax, %eax
	movl	%eax, 0x0804(%esp, %ebx, 4)	# L
	shll	$0x10, %eax
	movl	%eax, 0x0C04(%esp, %ebx, 4) # L+256

	movw	(%edi), %ax				# get an H entry
	addl	$0x02, %edi
	movzwl	%ax, %eax
	movl	%eax, 0x0004(%esp, %ebx, 4)	# H
	shll	$0x10, %eax
	movl	%eax, 0x0404(%esp, %ebx, 4) # H+256

	addl	$0x01, %ebx
#	cmpl	%ecx, %ebx
#	jb		SetupLoop
	subl	$0x01, %ecx
	jnz		SetupLoop
#
# begin main decode loop
#
	movl	0x08(%ebp), %edx		# src
	movl	0x0C(%ebp), %edi		# end
	movl	0x10(%ebp), %esi		# dst

#	int		$3

TopOfInnerLoop:
#  do {
#    u32 s = *src++;
	movl	(%edx), %ecx 

    // Use the two lookup tables computed earlier
#	u16 sw = s >> 16;
	movl	%ecx, %eax 
	shrl	$0x10, %eax
#    u32 d  = (L+256)[u8(sw >> 0)]; // use pre-shifted entries
#        d ^= (H+256)[u8(sw >> 8)]; // use pre-shifted entries
#        d ^= *dst ^ (L[u8(       s  >>  0)]      )
#                  ^ (H[u8(((u16) s) >>  8)]      )
#                  ; // <- one shift instruction eliminated
	movzbl	%ah, %ebx
	movl	0x0404(%esp, %ebx, 4), %ebx		# (H+256)[u8(sw >> 8)]
	movzbl	%ch, %ebp 
	xorl	0x0004(%esp, %ebp, 4), %ebx		# H[u8(s >> 8)]
	movzbl	%al, %eax
	xorl	0x0C04(%esp, %eax, 4), %ebx		# (L+256)[u8(sw >> 0)]
	movzbl	%cl, %ecx
	xorl	0x0804(%esp, %ecx, 4), %ebx		# L[u8(s >> 0)]
	addl	$0x04, %edx
	xorl	%ebx, (%esi)
#    dst++;
	addl	$0x04, %esi
#  } while (src < end);
	cmpl	%edi, %edx
	jb		TopOfInnerLoop
#
# end of loop: restore stack/regs, exit
#
	addl	$0x1004, %esp

#	popl	%eax
	popl	%ebx
#	popl	%ecx
#	popl	%edx
	popl	%edi
	popl	%esi
	popl	%ebp
	ret
