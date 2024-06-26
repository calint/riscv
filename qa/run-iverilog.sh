#!/bin/sh
# run from project root. i.e. qa/run-iverilog.sh
# tools:
#   iverilog: Icarus Verilog version 12.0 (stable)
#        vvp: Icarus Verilog runtime version 12.0 (stable)
set -e

SIMPTH=riscv.srcs/$1/new
TB=$2.v
SRCPTH=../../sources_1/new

cd $SIMPTH
pwd

iverilog -Wall -Winfloop -pfileline=1 -o iverilog.vvp \
    $TB \
    $SRCPTH/RAM.v \
    $SRCPTH/UartTx.v \
    $SRCPTH/UartRx.v \
    $SRCPTH/RAM_Interface.v \
    $SRCPTH/Registers.v \
    $SRCPTH/SoC.v

vvp iverilog.vvp
rm iverilog.vvp
