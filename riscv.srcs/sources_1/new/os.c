#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60
#define TOP_OF_RAM 0x1ffff

volatile unsigned char* leds = (unsigned char*)TOP_OF_RAM;

void delay(unsigned int ticks);
void set_stack_pointer(void* stack_ptr);

void _start() {
    set_stack_pointer((void*)(TOP_OF_RAM-1)); // top of memory minus the mapped leds
    unsigned char counter = 0;
    while(1) {
        *leds = counter++;
        delay(TICKS_PER_SEC);
    }
}

void delay(volatile unsigned int ticks) {
        while(ticks--);
}

void set_stack_pointer(void* stack_ptr) {
    asm volatile ("mv sp, %0" : : "r" (stack_ptr));
}