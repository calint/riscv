#!/bin/sh
# tools used:
#       riscv32-unknown-elf-gcc: (g2ee5e430018) 12.2.0
#   riscv32-unknown-elf-objcopy: GNU objcopy (GNU Binutils) 2.40.0.20230214
#   riscv32-unknown-elf-objdump: GNU objdump (GNU Binutils) 2.40.0.2023021
set -e

PATH=$PATH:~/riscv/install/rv32i/bin
SRC=$1
BIN=${SRC%.*}

# -mstrict-align \
riscv32-unknown-elf-gcc \
	-O2 \
	-nostartfiles \
	-ffreestanding \
	-nostdlib \
	-fno-pic \
	-march=rv32i \
	-mabi=ilp32 \
	-Wfatal-errors \
	-Wall -Wextra -pedantic \
	-Wl,-Ttext=0x0 \
	-Wl,--no-relax \
	-fno-toplevel-reorder \
	$SRC -o $BIN

riscv32-unknown-elf-objcopy $BIN -O binary $BIN.bin
riscv32-unknown-elf-objdump -Mnumeric,no-aliases -dr $BIN > $BIN.lst
xxd -p -c 4 -e $BIN.bin | awk '{print $2}' > $BIN.mem
rm $BIN

