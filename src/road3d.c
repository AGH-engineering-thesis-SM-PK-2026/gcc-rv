#include <stdint.h>

// #include <stdio.h>
// #include <stdlib.h>
// #define PUTCHAR(C) putchar(C)
// #define CLS() system("cls")

#include "sysdev.h"
#define PUTCHAR(C) TERMPUT(C)

#define TODIR_L 0
#define TODIR_R 1

struct road {
    int32_t curve; /* curve amount */
    int32_t todir; /* curve direction (left/right) */
};

void star_low(int32_t azimuth) {
    uint32_t x;
    uint32_t bx = (azimuth + 24*256)>>8;
    for (x = 0; x < 49; x++) {
        if (bx == x) PUTCHAR('I');
        else PUTCHAR(' ');
    }
    PUTCHAR('\n');
}

void star_mid(int32_t azimuth) {
    uint32_t x;
    uint32_t bx = (azimuth + 24*256)>>8;
    for (x = 0; x < 49; x++) {
        if (bx - 1 == x) PUTCHAR('-');
        else if (bx == x) PUTCHAR('X');
        else if (bx + 1 == x) PUTCHAR('-');
        else PUTCHAR(' ');
    }
    PUTCHAR('\n');
}

void sunset_low(void) {
    uint32_t x;
    for (x = 0; x < 49; x++) PUTCHAR('.');
    PUTCHAR('\n');
}

void road(int32_t tt, struct road *rd) {
    int32_t width = 3;
    int32_t zint = tt&0x7;
    int32_t zcurve = rd->curve;
    int32_t x, y;
    for (y = 0; y < 6; y++) {
        int32_t zoff = zcurve>>5;
        if (rd->todir == TODIR_L) zoff = -zoff;

        for (x = -24; x <= 24; x++) {
            uint32_t c = y == zint ? 'I' : 'H';
            if (x == -width + zoff || x == width + zoff) PUTCHAR(c);
            else if (x == zoff) PUTCHAR('-');
            else PUTCHAR(' ');
        }

        width += 2;
        zcurve>>=1;
        PUTCHAR('\n');
    }
}

void sway_road(uint32_t tt, struct road *road) {
    if (tt >= 12 && tt < 20) road->curve += 32;
    if (tt >= 44 && tt < 60) road->curve -= 16;

    if (tt == 80) road->todir = TODIR_R;
    if (tt >= 80 && tt < 88) road->curve += 32;
    if (tt >= 100 && tt < 104) road->curve -= 32;
    if (tt >= 140 && tt < 156) road->curve -= 8;

    if (tt == 200) road->todir = TODIR_L;
    if (tt >= 200 && tt < 216) road->curve += 16;
    if (tt >= 240 && tt < 248) road->curve -= 32;
    if (tt == 248) road->todir = TODIR_R;
    if (tt >= 248 && tt < 256) road->curve += 32;
    if (tt >= 320 && tt < 328) road->curve -= 32;

    if (road->curve > 256) road->curve = 256;
    if (road->curve < 0) road->curve = 0;
}

int32_t rotate_sky(int32_t azimuth, struct road *rd) {
    if (rd->todir == TODIR_L) azimuth += rd->curve;
    else azimuth -= rd->curve;

    if (azimuth > +90*256) azimuth = -90*256;
    if (azimuth < -90*256) azimuth = +90*256;
    
    return azimuth;
}

void delay(uint32_t ms) {
    volatile uint32_t i;
    for (i = 0; i < (ms<<7); i++);
}

void main(void) {
    uint32_t tt = 0; /* total frame count */
    int32_t azimuth = 0; /* azimuth in 1/256 units of degrees */
    int32_t x = 0, y = 0; /* viewport position */
    struct road rd = { 0, TODIR_L };

    for (;;) {
        TERMTOX(0);
        TERMTOY(0);

        PUTCHAR('\n');

        star_low(azimuth);
        star_mid(azimuth);
        star_low(azimuth);
        
        PUTCHAR('\n');
        PUTCHAR('\n');
        PUTCHAR('\n');

        sunset_low();

        sway_road(tt, &rd);

        azimuth = rotate_sky(azimuth, &rd);
        road(tt, &rd);

        if (tt < 512) tt++; 
        else tt = 0;
        delay(100);
    }
}