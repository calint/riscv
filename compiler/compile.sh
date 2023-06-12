#!/bin/sh
set -e

PATH=$PATH:~/riscv/install/rv32i/bin
SRC=$1
BIN=${SRC%.*}

#	-mstrict-align \

riscv32-unknown-elf-gcc \
	-ffreestanding \
	-fno-pic \
	-march=rv32i \
	-mabi=ilp32 \
	-nostdlib \
	-Wl,-Ttext=0x0 -Wl,--no-relax $1 -o $BIN

riscv32-unknown-elf-objcopy $BIN -O binary $BIN.bin
riscv32-unknown-elf-objdump -Mnumeric,no-aliases -dr $BIN > $BIN.lst
xxd -p -c 4 tb.bin > tb.mem
rm $BIN

