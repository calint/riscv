#!/bin/sh
# tools:
#   iverilog: Icarus Verilog version 11.0 (stable)
#        vvp: Icarus Verilog runtime version 11.0 (stable)
set -e

SIMPTH=riscv.srcs/$1/new
TB=$2.v
SRCPTH=../../sources_1/new

cd $SIMPTH
pwd

iverilog -Wall -Winfloop -pfileline=1 -o iverilog.out \
    $TB \
    $SRCPTH/RAM.v \
    $SRCPTH/RAM_Interface.v \
    $SRCPTH/Registers.v \
    $SRCPTH/SoC.v

vvp iverilog.out
rm iverilog.out
