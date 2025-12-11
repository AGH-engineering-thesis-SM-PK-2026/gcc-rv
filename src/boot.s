.extern main

.set RAMEND, 0x00002000

.section .text.boot, "ax", @progbits
.global _start
_start:
    li sp, RAMEND
    call main
_end:
    j _end
