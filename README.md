# riscv
experiments implementing a risc-v cpu to gain experience with verilog and minimalistic cpu design

most of the implementation is in an "always @*" block for the sake of simplicity and overview

implements the rv32i instructions with the exception for: fence, ecall, ebreak

ad-hoc 2-stage pipeline where a new instruction is fetched while previous executes

intended for cmod s7 from digilent.com

128 KB dual port block ram for instructions and data

50 MHz with most instructions executing in one cycle except branches which use two cycles due to creating 'bubble' in the pipeline

implements uart for send and receive text (see ["notes/os.c"](https://github.com/calint/riscv/blob/main/notes/os.c) for example)

how-to with vivado v2023.1:
* (optional) edit path to ram file in ["riscv.srcs/sources_1/new/Top.v"](https://github.com/calint/riscv/blob/main/riscv.srcs/sources_1/new/Top.v)
* connect fpga board, run synthesis, run implementation, generate bitstream, program device
* find out which tty is on the usb connected to the card (e.g. /dev/ttyUSB1)
* connect with terminal at 9600 baud, 8 bits, 1 stop bit, no parity 
* button 0 is reset, click it to restart and display the prompt (does not reset ram)
* "welcome to adventure #3" is the prompt
