#!/bin/sh
#
# note: run from project root. i.e. qa/run-iverilog-all.sh
#

echo sim_4
qa/run-iverilog.sh sim_4 TB_SoC 2>&1 | grep FAILED
echo sim_3
qa/run-iverilog.sh sim_3 TB_SoC 2>&1 | grep FAILED
echo sim_2
qa/run-iverilog.sh sim_2 TB_RAM_Interface 2>&1 | grep FAILED
echo sim_1
qa/run-iverilog.sh sim_1 TB_SoC 2>&1 | grep FAILED
