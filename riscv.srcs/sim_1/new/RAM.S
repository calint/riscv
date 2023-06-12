.text
.align 2
.globl _start

_start:
	addi x0, x0, 0			# nop
	lui x10, 0x12345		# x10 = 0x1234_5678
	addi x10, x10, 0x678
	addi x11, x0, 3			# x11 = 3
	slti x12, x11, 4		# x12 = 1
	slti x12, x11, -1		# x12 = 0
	sltiu x12, x11, 4		# x12 = 1
	sltiu x12, x11, -1		# x12 = 1
	xori x13, x12, -1		# x13 = 0xffff_fffe
	ori x13, x13, 1			# x13 = 0xffff_ffff
	andi x13, x13, 2		# x13 = 2
	slli x13, x13, 3		# x13 = 16
	srli x13, x13, 3		# x13 = 2
	xori x13, x13, -1       # x13 = 0xffff_fffd == -3
	srai x13, x13, 1		# x13 = 0xffff_fffe == -2

