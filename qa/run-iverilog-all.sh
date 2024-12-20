#!/bin/sh
#
# note: run from project root. i.e. qa/run-iverilog-all.sh
#
set -e

qa/run-iverilog.sh sim_4 TB_SoC
qa/run-iverilog.sh sim_3 TB_SoC
qa/run-iverilog.sh sim_2 TB_RAM_Interface
qa/run-iverilog.sh sim_1 TB_SoC
