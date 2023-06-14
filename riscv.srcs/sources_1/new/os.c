#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60

void delay(unsigned int ticks);
void set_stack_pointer(void* stack_ptr);

void _start() {
    set_stack_pointer((void*)0x1fffe); // top of memory minus the mapped leds
    volatile unsigned char* leds = (unsigned char*)0x1ffff; // address of leds mapped to ram
    
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