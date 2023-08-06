#!/bin/sh
# installing toolchain
#   RISC-V Assembly Language Programming: A.1 The GNU Toolchain
#   https://github.com/johnwinans/rvalp/releases/download/v0.14/rvalp.pdf
#
#   Compiling Freestanding RISC-V Programs
#   https://www.youtube.com/watch?v=ODn7vnWOptM
#
# tools used:
#       riscv32-unknown-elf-gcc: (g2ee5e430018) 12.2.0
#   riscv32-unknown-elf-objcopy: GNU objcopy (GNU Binutils) 2.40.0.20230214
#   riscv32-unknown-elf-objdump: GNU objdump (GNU Binutils) 2.40.0.2023021
#
set -e

PATH=$PATH:~/riscv/install/rv32i/bin
BIN=os

riscv32-unknown-elf-gcc \
	-Os \
	-g \
	-nostartfiles \
	-ffreestanding \
	-nostdlib \
	-fno-toplevel-reorder \
	-fno-pic \
	-march=rv32i \
	-mabi=ilp32 \
	-mstrict-align \
	-Wfatal-errors \
	-Wall -Wextra -pedantic \
	-Wconversion \
	-Wshadow \
	-Wl,-Ttext=0x0 \
	-Wl,--no-relax \
	os_start.S os.c -o $BIN

#	-Wpadded \

riscv32-unknown-elf-objcopy $BIN -O binary $BIN.bin
#riscv32-unknown-elf-objdump -Mnumeric,no-aliases --source-comment -Sr $BIN > $BIN.lst
riscv32-unknown-elf-objdump --source-comment -Sr $BIN > $BIN.lst
xxd -p -c 4 -e $BIN.bin | awk '{print $2}' > $BIN.mem
rm $BIN
ls -l $BIN.bin
