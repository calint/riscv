#!/bin/sh
# run from project root. i.e. qa/run-iverilog-all.sh
set -e

echo "-------------------------------------------------------------------------"
qa/run-iverilog.sh sim_4 TB_SoC | grep -v passed
echo "-------------------------------------------------------------------------"
qa/run-iverilog.sh sim_3 TB_SoC | grep -v passed
echo "-------------------------------------------------------------------------"
qa/run-iverilog.sh sim_2 TB_RAM_Interface | grep -v passed
echo "-------------------------------------------------------------------------"
qa/run-iverilog.sh sim_1 TB_SoC | grep -v passed
echo "-------------------------------------------------------------------------"
