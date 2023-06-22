.global _start

# sets up the stack before calling c function 'run' in 'os.c'
_start:
    lui sp, 0x2         # set stack at # 0x1fff0
    addi sp, sp, -16    #
    jal ra, run         