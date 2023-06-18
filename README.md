# riscv
experiments implementing a simple riscv cpu to gain experience with verilog and minimalistic cpu design

most of the implementation deliberately in an "always @*" block instead of modules and/or logic on wires for the sake of simplicity and overview

implements the rv32i instructions with the exception for: FENCE, ECALL, EBREAK

ad-hoc 2-stage pipeline where new instruction is fetched while previous executes

intended for Cmod S7 from digilent.com
