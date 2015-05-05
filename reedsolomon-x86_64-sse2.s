#  This file is part of par2cmdline (a PAR 2.0 compatible file verification and
#  repair tool). See http://parchive.sourceforge.net for details of PAR 2.0.
#
#  Based on code by Paul Houle (paulhoule.com) March 22, 2008.
#  Copyright (c) 2008 Paul Houle
#  Copyright (c) 2008 Vincent Tan.
#  Copyright (c) 2015 Peter Cordes <peter@cordes.ca>
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
# reedsolomon-x86_64-sse2.s
#

#
# void rs_process_x86_64_sse2(void* dst (%rdi), const void* src (%rsi), size_t size (%rdx), const u16* LH (%rcx));
#
	# TODO: use 8 or 16-byte aligned SIMD loads when src is aligned
#	movdqa		(%rsi), %xmm4
	movd		4(%rsi), %mm4
	prefetchT0      (%rdi)

	push		%rbp	# could use %r9 / %r11, but then some insns would take an extra byte to encode
#	push		%rsi
#	push		%rdi
	push		%rbx
	#r8-11 can be modified without saving
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
#	prefetchT0       128(%rsi)					# is it worth prefetching a lot, to trigger HW prefetch?
	add			%r15, %rsi						# point to last set of 8-bytes of input
	add			%r15, %rdi						# point to last set of 8-bytes of output
	neg			%r15							# convert byte size to count-up


# %rdi		# destination (function arg)
# %rsi		# source  (function arg)
# rbp: lookup table

# eax: scratch (holds %dl)
# ebx: scratch (holds %dh)

# ecx: -count, counts upward to 0.
# edx / mm4: src. (mm4 loads 64B.  edx gets 32B at a time from mm4, and is shifted by 16B for the low/high GF16)

# mm5: previous value of dest

	.align	32
loop:
# %rdx has 8 bytes of source data
	movq		%rdx, %rcx
	shr			$32, %rdx						# get two parallel dependency chains going in %ecx and %edx
	movzx		%cl, %eax
	movzx		%ch, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %r8d
#	movzwl		0x0400(%rbp, %rbx, 2), %r9d
	xor			0x0400(%rbp, %rbx, 2), %r8w		# result for src[0] (low 16bits of source)
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %r10d
#	movzwl		0x0400(%rbp, %rbx, 2), %r11d
	xor			0x0400(%rbp, %rbx, 2), %r10w	# result for src[2] (low 16 of upper 32b)
	shr			$16, %ecx
	shr			$16, %edx
	movzx		%cl, %eax
	movzx		%ch, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %ecx		# %r9d
	xor			0x0400(%rbp, %rbx, 2), %cx		# result for src[1]
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %eax		# %r11d
	xor			0x0400(%rbp, %rbx, 2), %ax		# result for src[3]

	movq		8(%rsi, %r15, 1), %rdx			# read-ahead next 8 source bytes

	movd		%r8d, 		%mm0				# movd breaks any dependency on previous value of mm0
	pinsrw		$1, %ecx,	%mm0
	pinsrw		$2, %r10d,	%mm0
	pinsrw		$3, %eax,	%mm0
	pxor		0(%rdi, %r15, 1), %mm0			# combine the result with previous contents of the buffer
	movq		%mm0, 0(%rdi, %r15, 1)

	add			$8, %r15
	jnz			loop		# 29th instruction.  One too many for the loop-stream-decoder in Intel SNB :(

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
