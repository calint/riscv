#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60

void _start() {
    volatile unsigned char* leds = (unsigned char*)0xffffffff;
    unsigned char counter = 0;
    while(1) {
        *leds = counter++;
        for(int i = 0; i < TICKS_PER_SEC; i++);
    }
}
