#include <stdint.h>

#include "sysdev.h"

void main(void) {
    TERM0->put = 'h';
    TERM0->put = 'e';
    TERM0->put = 'l';
    TERM0->put = 'l';
    TERM0->put = 'o';
    TERM0->put = '\n';
    TERM0->put = 'w';
    TERM0->put = 'o';
    TERM0->put = 'r';
    TERM0->put = 'l';
    TERM0->put = 'd';
    TERM0->put = '!';
}