#ifndef _SYSDEV_H_
#define _SYSDEV_H_

#include "stdint.h"

#define DEV_GPIO0  0x00000010
#define DEV_TERM0  0x00000050
#define DEV_MEM    0x00001000
#define DEV_MEMEND 0x00001fff

struct gpio {
    uint32_t out;
    uint32_t in;
    //uint8_t out;
    //uint8_t in;
};

struct term {
    uint32_t put;
    uint32_t x;
    uint32_t y;
    //uint8_t put;
    //uint8_t x;
    //uint8_t y;
    //uint8_t attr;

};

#define GPIO0 ((volatile struct gpio *) DEV_GPIO0)
#define TERM0 ((volatile struct term *) DEV_TERM0)
#define MEM32 ((volatile uint32_t *) DEV_MEM)

#define PIN(N) (1<<N)
#define TERMPUT(C) (TERM0->put = C)
#define TERMTOX(X) (TERM0->x = X)
#define TERMTOY(Y) (TERM0->y = Y)

#endif/*_SYSDEV_H_*/
