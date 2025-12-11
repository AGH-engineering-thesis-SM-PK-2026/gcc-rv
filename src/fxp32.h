#ifndef _FXP32_H_
#define _FXP32_H_

#include <stdint.h>

typedef int32_t fxp32_t;
typedef int64_t fxp64_t;

/* upper 16 bits: decimal part
 * lower 16 bits: fractional part */
#define FXP32(D, F) (((D&0xffff)<<16) + (F))
#define FRA32(E) ((const fxp32_t)((E) * 65536.0f))

/* operates on fixed point, not exactly '__muldi3' compatible */
extern fxp32_t fxp32_mul(fxp32_t a, fxp32_t b);
/* sphere sqrt: very rough and limited approximation:
 * - 0.0..16.0 returns 0, inside of sphere
 * - 16.0..24.0 returns approx1 approximation + 1/16th of (input mod 1)
 * - 24.0..64.0 returns approx4 approximation
 * - inputs above 64.0 are clamped to 64.0
 * useful for obtaining non-squared distance, also sphsqrt(x) < sqrt(x) */
extern fxp32_t fxp32_sphsqrt(fxp32_t a);

#endif/*_FXP32_H_*/