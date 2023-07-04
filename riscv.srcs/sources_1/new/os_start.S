.global _start

# sets up the stack before calling c function 'run' in 'os.c'
_start:
    li sp, 0x1fff0
    jal ra, run         # run program