#!/bin/bash
set -e
set -x

TTY=/dev/ttyUSB1
SLP=1

stty -F $TTY 9600 cs8 -cstopb -parenb

cat $TTY > test1.out &

read -p "program FPGA then press Enter to continue..."

printf "i\r" > $TTY
sleep $SLP
printf "t notebook\r" > $TTY
sleep $SLP
printf "n\r" > $TTY
sleep $SLP
printf "t lighter\r" > $TTY
sleep $SLP
printf "g mirror u\r" > $TTY
sleep $SLP
printf "i\r" > $TTY
sleep $SLP
printf "i\r" > $TTY
sleep $SLP

# send SIGTERM (termination signal) to 'cat'
kill -SIGTERM %1

# wait for 'cat' to exit
wait %1 || true

if cmp -s test1.diff test1.out; then
    echo "test 1: OK"
    rm test1.out
else
    echo "test 1: FAILED"
fi
