#  This file is part of par2cmdline (a PAR 2.0 compatible file verification and
#  repair tool). See http://parchive.sourceforge.net for details of PAR 2.0.
#
#  Based on code by Paul Houle (paulhoule.com) March 22, 2008.
#  Copyright (c) 2008 Paul Houle
#  Copyright (c) 2008 Vincent Tan.
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
# reedsolomon-x86_64-mmx.s
#

#
# void rs_process_x86_64_mmx(void* dst (%rdi), const void* src (%rsi), size_t size (%rdx), const u16* LH (%rcx));
#
	# TODO: use 8 or 16-byte aligned SIMD loads when src is aligned
#	movdqa		(%rsi), %xmm4
	movd		4(%rsi), %mm4
	prefetchT0      (%rdi)

	push		%rbp
#	push		%rsi
#	push		%rdi
	push		%rbx
	#r8-11 can be modified
#	push		%r12
#	push		%r13
#	push		%r14
	push		%r15

	mov			%rcx, %rbp						# combined multiplication table
	mov			%rdx, %r15						# number of bytes to process (multiple of 4)

#	mov			(%rsi), %edx					# load 1st 8 source bytes
#	movq		%xmm4, %rdx
	movq		(%rsi), %rdx
#	movhlps		%xmm4, 8						# setup leaves us ready to jump into the midpoint of an iteration
#	punpckhqdq	%xmm4, %xmm4

#	sub			$8, %r15						# reduce # of loop iterations by 1
#	jz			last8

#	prefetchT0       64(%rdi)
#	prefetchT0       64(%rsi)
#	prefetch0       128(%rsi)					# is it worth prefetching a lot, to trigger HW prefetch?
	add			%r15, %rsi						# point to last set of 8-bytes of input
	add			%r15, %rdi						# point to last set of 8-bytes of output
	neg			%r15							# convert byte size to count-up

# This is faster than the scalar code mainly because wider load/stores
# for the source and dest data leave the load unit(s) free
# for 32b loads from the LH lookup table.
# punpckldq just loads 32b from memory into the high half of the MMX reg

# %rdi		# destination (function arg)
# %rsi		# source  (function arg)
# rbp: lookup table

# eax: scratch (holds %dl)
# ebx: scratch (holds %dh)

# ecx: -count, counts upward to 0.
# edx / mm4: src. (mm4 loads 64B.  edx gets 32B at a time from mm4, and is shifted by 16B for the low/high GF16)

# mm5: previous value of dest

	.align	4
loop:
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movd		0x0000(%rbp, %rax, 2), %mm0		# FIXME: there is no movw to mmx reg.  We need to mask off the bits we don't need
	movd		0x0400(%rbp, %rbx, 2), %mm1
	shr			$16, %edx
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movd		0x0000(%rbp, %rax, 2), %mm2
	movd		0x0400(%rbp, %rbx, 2), %mm3
	movd		%mm4, %edx
	movq		8(%rsi, %r15, 1), %mm4			# read-ahead next 8 source bytes
	movzx		%dl, %eax
	movzx		%dh, %ebx
#	punpckldq	0x0000(%rbp, %rax, 2), %mm0
#	punpckldq	0x0400(%rbp, %rbx, 2), %mm1
	pinsrw		$2, 0x0000(%rbp, %rax, 2), %mm0
	pinsrw		$2, 0x0400(%rbp, %rbx, 2), %mm1
#	movzx		0x0000(%rbp, %rax, 2), %r8
#	movzx		0x0400(%rbp, %rbx, 2), %r9
	shr			$16, %edx
	movzx		%dl, %eax
	movzx		%dh, %ebx
#	punpckldq	0x0000(%rbp, %rax, 2), %mm2
#	punpckldq	0x0400(%rbp, %rbx, 2), %mm3
	pinsrw		$2, 0x0000(%rbp, %rax, 2), %mm2
	pinsrw		$2, 0x0400(%rbp, %rbx, 2), %mm3
	pxor		%mm0, %mm1
	movd		%mm4, %edx						# prepare src bytes 3-0 for next loop
#	movq		0(%rdi, %r15, 1), %mm5
#	pxor		%mm5, %mm1
	pxor		0(%rdi, %r15, 1), %mm1
	pxor		%mm2, %mm3
	psllq		$16, %mm3
	psrlq		$32, %mm4						# align src bytes 7-4 for next loop
	pxor		%mm3, %mm1
	movq		%mm1, 0(%rdi, %r15, 1)

	add			$8, %r15
	jnz			loop

	#
	# handle final iteration separately (so that a read beyond the end of the input/output buffer is avoided)
	#
last8:
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movd		0x0000(%rbp, %rax, 2), %mm0
	shr			$16, %edx
	movd		0x0400(%rbp, %rbx, 2), %mm1
	movzx		%dl, %eax
	movq		0(%rdi, %r15, 1), %mm5
	movzx		%dh, %ebx
	movd		0x0000(%rbp, %rax, 2), %mm2
	movd		%mm4, %edx
#	movq		8(%rsi, %r15, 1), %mm4			# read-ahead next 8 source bytes
	movzx		%dl, %eax
	movd		0x0400(%rbp, %rbx, 2), %mm3
	movzx		%dh, %ebx
	shr			$16, %edx
#	punpckldq	0x0000(%rbp, %rax, 4), %mm0
	pinsrw		$2, 0x0000(%rbp, %rax, 2), %mm0
	movzx		%dl, %eax
#	punpckldq	0x0400(%rbp, %rbx, 4), %mm1
	pinsrw		$2, 0x0400(%rbp, %rbx, 2), %mm1
	movzx		%dh, %ebx
	punpckldq	0x0000(%rbp, %rax, 4), %mm2
	pxor		%mm0, %mm1
	punpckldq	0x0400(%rbp, %rbx, 4), %mm3
#	movd		%mm4, %edx						# prepare src bytes 3-0 for next loop
	pxor		%mm5, %mm1
	pxor		%mm2, %mm3
	psllq		$16, %mm3
#	psrlq		$32, %mm4						# align src bytes 7-4 for next loop
	pxor		%mm3, %mm1
	movq		%mm1, 0(%rdi, %r15, 1)

	#
	# done: exit MMX mode, restore regs/stack, exit
	#
	emms
	pop			%r15
#	pop			%r14
#	pop			%r13
#	pop			%r12
	pop			%rbx
#	pop			%rdi
#	pop			%rsi
	pop			%rbp
	ret
