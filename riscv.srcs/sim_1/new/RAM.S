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
	add x14, x13, x12		# x14 = -2 + 1 == -1
	sub x14, x14, x12		# x14 = -1 - 1 == -2
	sll x15, x12, x12		# x15 = 1 << 1 == 2
	slt x16, x12, x15		# x16 = 1 (1 < 2)
	slt x16, x12, x12		# x16 = 0 (1 < 1)
	sltu x16, x16, x13		# x16 = 1 (0 < 0xfff_ffe)
	xor x17, x16, x13		# x17 = -1 (1 ^ 0xffff_fffe)
	srl x18, x11, x16		# x18 = 3 >> 1 == 1
	sra x18, x17, x16		# x18 = 0xffff_fffe >>> 1 == -1
	or x19, x16, x11		# x19 = 1 | 3 == 3
	and x19, x19, x16		# x19 = 3 & 1 == 1
	lui x20, 0x1			# x20 = 0x0000_1000
	sw x19, 4(x20)			# ram[0x100 + 4] = 0x0000_0001
	sh x19, 6(x20)			# ram[0x100 + 6] = 0x0001
	sb x19, 7(x20)			# ram[0x100 + 7] = 0x01
