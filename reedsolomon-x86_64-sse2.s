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
# void rs_process_x86_64_sse2(void* dst (%rdi), const void* src (%rsi), const u16* LH (%rcx), size_t size (%rdx));
#
#  we potentially read several bytes beyond the end of LH[511]
	# TODO: use 8 or 16-byte aligned SIMD loads when src is aligned
#	movdqa		(%rsi), %xmm4
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

	mov			%rdx, %rbp						# combined multiplication table
	mov			%rcx, %r15						# number of bytes to process (multiple of 4)

#	mov			(%rsi), %edx					# load 1st 8 source bytes
#	movq		%xmm4, %rdx
	movq		(%rsi), %rdx

	# TODO: add an extra -2 byte offset to get the results for high 16 of a 32b pair into the upper 16
	# lea			-2(%rbp), %r11		# store offset lookup table in a reg to allow 0-offset addressing mode for L

	add			%rdi, %r15			# points to one past the end of output buffer.

#	sub			$8, %r15						# reduce # of loop iterations by 1
#	jz			last8

#	prefetchT0       64(%rdi)
#	prefetchT0       64(%rsi)
#	prefetchT0       128(%rsi)					# is it worth prefetching a lot, to trigger HW prefetch?
#	add			%r15, %rsi						# point to last set of 8-bytes of input
#	add			%r15, %rdi						# point to last set of 8-bytes of output
#	neg			%r15							# convert byte size to count-up

# %rdi		# destination (function arg)
# %rsi		# source  (function arg)
# %rbp: lookup table: 0-0x199: lookup for lower bytes.  0x200-0x399: lookup for upper bytes
#   TODO: save %rbp + 0x200 in a register, to reduce AGU pressure?  nope, AGUs are fine
#		It's only LEA that's slower with complex addressing modes.
#		The offset makes the insn bigger, but we're probably fine when decoding from uop cache

# eax: scratch (holds %dl)
# ebx: scratch (holds %dh)

# ecx: -count, counts upward to 0.
# edx / mm4: src. (mm4 loads 64B.  edx gets 32B at a time from mm4, and is shifted by 16B for the low/high GF16)

# mm5: previous value of dest

	.align	16
loop:
### %rdx has 8 bytes data from (%rsi)
# %rsi points to source data
# %rdi points to the location in the output buffer to modify
	movq		(%rsi), %rdx			 # TODO: read-ahead next 8 source bytes to avoid potential false dep on store that's a multiple of 4k away
	movzx		%dl, %eax
	movzx		%dh, %ebx

	movq		%rdx, %rcx						# get two parallel dependency chains going in %ecx and %edx.
	shr			$32, %rdx						# (costs one extra movq)

	movzwl		0x0000(%rbp, %rax, 2), %eax
	# 16b xor: pre-Ivy Bridge, stall or extra uop when wider reg is read before the partial-reg write fully retires
	# also, huge decode penalty for 16bit ops, before the loop is in the uop cache
#	xor			0x0200(%rbp, %rbx, 2), %r8d		# result for src[0] (low 16bits of source).
	movzwl		0x0200(%rbp, %rbx, 2), %ebx
	xor			%ebx, %eax
	movd		%eax, %mm0						# breaks dependency on previous iteration
#	movd		0x0000(%rbp, %rax, 2), %mm0		# go directly to the mm reg.
#	movd		0x0200(%rbp, %rbx, 2), %mm1		# PXOR from the LUT is unaligned, and bigger chance to cacheline split
#	pxor		%mm1, %mm0
		# 32bit xor (or 64bit pxor) xor will leave garbage in the upper bits.
		# movd will copy the garbage into a vector reg, but the following pinsrw will overwrite it
		# Problem with this approach: wider loads -> cacheline splits.  Also unaligned loads, if that matters
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %eax
#	xor			0x0200(%rbp, %rbx, 2), %r10d	# result for src[2] (low 16 of upper 32b)
	movzwl		0x0200(%rbp, %rbx, 2), %ebx
	xor			%ebx, %eax			# One (fused) uop even with a memory operand
	pinsrw		$2, %eax, %mm0		# PINSRW takes two uops.  MOVD / PUNPCKLDQ only take one

	movq		(%rdi), %mm4

	shr			$16, %ecx
	shr			$16, %edx
# first4_entry:  # not usable, would write before the beginning of the buffer.  Just make sure buffers are aligned!
	movzx		%cl, %eax
	movzx		%ch, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %eax		# %r9d, but using %ecx saves a REX byte
#	xor			0x0200(%rbp, %rbx, 2), %ecx		# result for src[1]
	movzwl		0x0200(%rbp, %rbx, 2), %ebx
	xor			%ebx, %eax
	pinsrw		$1, %eax, %mm0

	movzx		%dl, %eax
	movzx		%dh, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %eax		# %r11d
#	xor			0x0200(%rbp, %rbx, 2), %eax		# result for src[3].
	movzwl		0x0200(%rbp, %rbx, 2), %ebx
	xor			%ebx, %eax
	pinsrw		$3, %eax, %mm0

#	movd		%r8d, 		%mm0				# movd breaks any dependency on previous value of mm0
#	pinsrw		$1, %ecx,	%mm0
#	pinsrw		$2, %r10d,	%mm0
#	pinsrw		$3, %eax,	%mm0
#	pxor		0(%rdi, %r15, 1), %mm0			# combine the result with previous contents of the buffer
	pxor		%mm4, %mm0
	movq		%mm0, 0(%rdi)

	add			$8, %rsi
	add			$8, %rdi
	cmp			%rdi, %r15
	ja			loop		# 29th instruction.  One too many for the loop-stream-decoder in Intel SNB :(

	#
	# handle final iteration separately (so that a read beyond the end of the input/output buffer is avoided)
	#
last8:
	# %rdx has 8 or 4 bytes of data
	# The loop is probably correct.  The trailer is just a copy/paste of loop body
	# and probably does the wrong # of iterations

	movq		%rdx, %rcx
	shr			$32, %rdx						# get two parallel dependency chains going in %ecx and %edx
	movzx		%cl, %eax
	movzx		%ch, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %r8d
#	xor			0x0200(%rbp, %rbx, 2), %r8d		# result for src[0] (low 16bits of source).
	movzwl		0x0200(%rbp, %rbx, 2), %eax
	xor			%eax, %r8d
		# 32bit xor will leave garbage in the upper 16 bits.
		# movd will copy the garbage into a vector reg,
		# but the following pinsrw will overwrite it
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %r10d
	xor			0x0200(%rbp, %rbx, 2), %r10d	# result for src[2] (low 16 of upper 32b)
	shr			$16, %ecx
	shr			$16, %edx
	movzx		%cl, %eax
	movzx		%ch, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %ecx		# %r9d, but using %ecx saves a REX byte
	xor			0x0200(%rbp, %rbx, 2), %ecx		# result for src[1]
	movzx		%dl, %eax
	movzx		%dh, %ebx
	movzwl		0x0000(%rbp, %rax, 2), %eax		# %r11d
	xor			0x0200(%rbp, %rbx, 2), %eax		# result for src[3].

#	movq		(%rdi), %#mm4
#	add			$8, %rsi
#	movq		(%rsi), %rdx			# read-ahead next 8 source bytes

	movd		%r8d, 		%mm0				# movd breaks any dependency on previous value of mm0
	pinsrw		$1, %ecx,	%mm0
	pinsrw		$2, %r10d,	%mm0
	pinsrw		$3, %eax,	%mm0
#	pxor		0(%rdi, %r15, 1), %mm0			# combine the result with previous contents of the buffer
	pxor		%mm4, %mm0
#	movq		%mm0, 0(%rdi)


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
