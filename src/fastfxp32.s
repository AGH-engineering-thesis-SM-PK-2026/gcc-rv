.section .text, "ax", @progbits

#/* fast fxp32_mul */
# * a0 : fxp32_t a, a1 : fxp32_t b -> return a0 : fxp32_t
# * register usage: TODO
# */
.global fxp32_mul
fxp32_mul:
    #/* sign masks are: 
    # * - 0xFFFFFFFF for negative numbers
    # * - 0x00000000 for positive numbers 
    # */

    srai    t0, a0, 31 #/* sign mask for a */
    srai    t1, a1, 31 #/* sign mask for b */
    xor     a4, t1, t0 #/* sign mask for m */

    xor     a0, a0, t0 
    sub     a0, a0, t0 #/* abs(a) (lower) */
    xor     a1, a1, t1
    sub     a1, a1, t1 #/* abs(b) */

    li      a3, 0 #/* a (upper) */
    li      a6, 0 #/* m (lower) */
    li      a7, 0 #/* m (upper) */
    li      t5, 0 #/* iter */
    li      t6, 32 #/* iter end */
#/* loop start */
.L_mul_loop:
    andi    t4, a1, 1 #/* bit */
    beq     t4, zero, .L_mul_next #/* bit clear, do not add */

    add     a6, a6, a0
    add     t0, a7, a3 #/* m += a */
    sltu    t1, a6, a0
    add     a7, t0, t1
.L_mul_next:
    srli    a1, a1, 1 #/* shift b right */

    slli    t0, a0, 1
    slli    a3, a3, 1 #/* shitf a left */
    sltu    t1, t0, a0 #/* if t0 < a0 then set carry bit */
    mv      a0, t0 #/* save a (lower) */
    add     a3, a3, t1 #/* add carry bit */

    addi    t5, t5, 1 #/* add iter */
    ble     t5, t6, .L_mul_loop
.L_mul_end:
    xor     a6, a6, a4
    xor     a7, a7, a4 #/* unabs(m) (xor step) */
    sub     a6, a6, a4
    sltu    t1, a6, a4 #/* if a6 < a4 then set borrow bit */
    sub     a7, a7, a4 
    sub     a7, a7, t1 #/* unabs(m) (sub step) */

    slli    t0, a7, 16 #/* get bits 47:32 and make them 31:15 */
    srli    a0, a6, 16
    or      a0, a0, t0 #/* shift m by 16 to truncate to fxp32_t */
    ret

#/* fast fxp32_sphsqrt
# * a0 : fxp32_t a -> return a0 : fxp32_t */
.global fxp32_sphsqrt
fxp32_sphsqrt:
    li      t0, 16
    li      t1, 24
    li      t2, 64
    li      t3, 0xffff
    and     a1, a0, t3 #/* extract fraction */
    srli    a0, a0, 16 #/* to uint32_t */
    blt     a0, t0, .L_sphsqrt_min #/* less than radius, return 0 */
    bge     a0, t2, .L_sphsqrt_max
.L_sphsqrt_approx_init:
    bge     a0, t1, .L_sphsqrt_approx4u_init
.L_sphsqrt_approx1a_init:
    srli    a1, a1, 4 #/* get linear approximation 0x0000:0x1fff */
    addi    a0, a0, -16
    slli    a0, a0, 4 #/* obtain program offset from approx table start */
    la      a4, .L_sphsqrt_approx1a
    add     a4, a4, a0
    jalr    zero, a4, 0 #/* jump */
.L_sphsqrt_approx1a:
    li      a0, 0x00040000 #/* 16 -> 4.0000 */
    add     a0, a0, a1 #/* apply linearization */
    ret  
    nop     #/* padding */
    li      a0, 0x00041f83 #/* 17 -> 4.1231 */
    add     a0, a0, a1 #/* apply linearization */
    ret
    li      a0, 0x00043e1b #/* 18 -> 4.2426 */
    add     a0, a0, a1 #/* apply linearization */
    ret
    li      a0, 0x00045bda #/* 19 -> 4.3588 */
    add     a0, a0, a1 #/* apply linearization */
    ret
    li      a0, 0x000478dc #/* 20 -> 4.4721 */
    add     a0, a0, a1 #/* apply linearization */
    ret
    li      a0, 0x0004951f #/* 21 -> 4.5825 */
    add     a0, a0, a1 #/* apply linearization */
    ret
    li      a0, 0x0004b0be #/* 22 -> 4.6904 */
    add     a0, a0, a1 #/* apply linearization */
    ret
    li      a0, 0x0004cbba #/* 23 -> 4.7958 */
    add     a0, a0, a1 #/* apply linearization */
    ret
.L_sphsqrt_approx4u_init:
    addi    a0, a0, -24
    srli    a0, a0, 2 #/* reduce precision by 2 bits (step by 4) */
    slli    a0, a0, 4 #/* obtain program offset from approx table start */
    la      a4, .L_sphsqrt_approx4u
    add     a4, a4, a0
    jalr    zero, a4, 0 #/* jump */
.L_sphsqrt_approx4u:
    li      a0, 0x0004e61e #/* 24 -> 4.8989 */
    ret
    nop     #/* padding */
    li      a0, 0x00054aa0 #/* 28 -> 5.2915 */
    ret
    nop     #/* padding */
    li      a0, 0x0005a824 #/* 32 -> 5.6568 */
    ret
    nop     #/* padding */
    li      a0, 0x00060000 #/* 36 -> 6.0000 */
    ret
    nop
    nop     #/* padding */
    li      a0, 0x00065312 #/* 40 -> 6.3245 */
    ret
    nop     #/* padding */
    li      a0, 0x0006a219 #/* 44 -> 6.6332 */
    ret
    nop     #/* padding */
    li      a0, 0x0006ed9f #/* 48 -> 6.9282 */
    ret
    nop     #/* padding */
    li      a0, 0x0007360b #/* 52 -> 7.2111 */
    ret
    nop     #/* padding */
    li      a0, 0x00077bba #/* 56 -> 7.4833 */
    ret
    nop     #/* padding */
    li      a0, 0x0007bef3 #/* 60 -> 7.7459 */
    ret     #/* padding redudant */
.L_sphsqrt_min:
    li      a0, 0x00000000 #/* inside of the sphere -> 0.0000 */
    ret
.L_sphsqrt_max:
    li      a0, 0x00080000 #/* clamp to 64 -> 8.0000 */
    ret
