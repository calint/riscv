#!/bin/sh
#
# compiles specified source to risc-v binary
# extracts 'mem' file from binary to be included by vivado
# note: assumes riscv64-elf-gcc toolchain installed
#
# tools used:
#       riscv64-elf-g++: 14.1.0
#   riscv64-elf-objcopy: 2.42
#   riscv64-elf-objdump: 2.42
#                   xxd: tinyxxd 1.3.7
#                   awk: 5.3.1
#
set -e

SRC=$1
BIN=${SRC%.*}

# -mstrict-align \
riscv64-elf-gcc \
	-march=rv32i \
	-mabi=ilp32 \
	-O2 \
	-nostartfiles \
	-ffreestanding \
	-nostdlib \
	-fno-pic \
	-Wfatal-errors \
	-Wall -Wextra -pedantic \
	-Wl,-Ttext=0x0 \
	-Wl,--no-relax \
	-fno-toplevel-reorder \
	$SRC -o $BIN

riscv64-elf-objcopy $BIN -O binary $BIN.bin
riscv64-elf-objdump -Mnumeric,no-aliases -dr $BIN > $BIN.lst
xxd -p -c 4 -e $BIN.bin | awk '{print $2}' > $BIN.mem
rm $BIN

