#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60
#define TOP_OF_RAM 0x1ffff

volatile unsigned char* leds = (unsigned char*)TOP_OF_RAM;

void delay(unsigned int ticks);
void set_stack_pointer(void* stack_ptr);

struct baba {
    char bits;
    char byte;
    short word;
    int dword;
} babas[] = {
    {0xfa,0xfb,(short)0xfffc,0xfffffffd},
    {0x1a,0x1b,0x111c,0x1111111d},
};

void _start() {
    set_stack_pointer((void*)(TOP_OF_RAM-1)); // top of memory minus the mapped leds
    while(1) {
        *leds = babas[0].byte++;
        delay(TICKS_PER_SEC);
    }
}

inline void delay(volatile unsigned int ticks) {
        while(ticks--);
}

inline void set_stack_pointer(void* stack_ptr) {
    asm volatile ("mv sp, %0" : : "r" (stack_ptr));
}