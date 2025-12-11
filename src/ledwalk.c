#include <stdint.h>

#include "sysdev.h"

void main(void) {
    for (;;) {
        GPIO0->out = PIN(4);
        GPIO0->out = PIN(5);
        GPIO0->out = PIN(6);
        GPIO0->out = PIN(7);
    }
}