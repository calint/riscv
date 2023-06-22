# riscv
experiments implementing a simple riscv cpu to gain experience with verilog and minimalistic cpu design

most of the implementation in an "always @*" block for the sake of simplicity and overview

implements the rv32i instructions with the exception for: FENCE, ECALL, EBREAK

ad-hoc 2-stage pipeline where new instruction is fetched while previous executes

intended for Cmod S7 from digilent.com

implements UART send and receive (see riscv.srcs/sources_1/new/os.c)

how-to with Vivado v2023.1:
* to program device edit path to RAM file in "riscv.srcs/sources_1/new/Top.v"
* connect fpga board Cmod S7 from digilent.com
* run synthesis, run implementation, program device
* find out which tty is on the usb connected to the card (e.g. /dev/ttyUSB1)
* connect with terminal at 9600 baud, 8 bits, 1 stop bit, no parity 
* button 0 is reset, click it to restart and display the prompt
* "Hello World" is the prompt
* after the prompt the program enters a read / write loop (echo)