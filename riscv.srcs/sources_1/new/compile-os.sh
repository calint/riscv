#!/bin/sh
#
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

PATH=$PATH:~/riscv/install/rv32i/bin
BIN=os

riscv64-elf-gcc \
	-march=rv32i \
	-mabi=ilp32 \
	-Os \
	-g \
	-ffreestanding \
	-nostartfiles \
	-nostdlib \
	-fno-toplevel-reorder \
	-fno-pic \
	-mstrict-align \
	-Wfatal-errors \
	-Wall -Wextra -pedantic \
	-Wconversion \
	-Wshadow \
	-Wl,-Ttext=0x0 \
	-Wl,--no-relax \
	os_start.S os.c -o $BIN

#	-Wpadded \

riscv64-elf-objcopy $BIN -O binary $BIN.bin
#riscv64-elf-objdump -Mnumeric,no-aliases --source-comment -Sr $BIN > $BIN.lst
riscv64-elf-objdump --source-comment -Sr $BIN > $BIN.lst
xxd -p -c 4 -e $BIN.bin | awk '{print $2}' > $BIN.mem
rm $BIN
ls -l $BIN.bin
