# riscv
experiments implementing a simple riscv cpu to gain experience with verilog and minimalistic cpu design

implements the rv32i instructions with the exception for: FENCE, FENCE.I, ECALL, EBREAK

2-stage pipeline where new instruction is fetched while previous executes
