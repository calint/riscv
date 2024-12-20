#!/bin/sh
#
# run from project root. i.e. qa/run-iverilog.sh
# tools used:
#   iverilog: 12.0
#        vvp: 12.0
#
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
