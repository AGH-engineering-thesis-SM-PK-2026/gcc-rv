#include <stdint.h>

#include "sysdev.h"

void main(void) {
    uint32_t c = 0x20;
    for (;;) {
        TERM0->put = c++;
        if (c >= 0x60) c = 0x20;
    }
}