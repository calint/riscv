#define CPU_FREQ 50000000
#define TICKS_PER_SEC CPU_FREQ / 60

void _start() {
    volatile unsigned char* leds = (unsigned char*)0xffffffff;
    unsigned char counter = 0;
    while(1) {
        *leds = counter;
        counter++;
        for(int i = 0; i < TICKS_PER_SEC; i++);
    }
}
