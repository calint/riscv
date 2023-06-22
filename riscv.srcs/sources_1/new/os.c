#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60
#define TOP_OF_RAM 0x1ffff
#define TOP_OF_STACK 0x1fffc

volatile unsigned char *leds = (unsigned char *)TOP_OF_RAM;
volatile unsigned char *uart_out = (unsigned char *)TOP_OF_RAM - 1;

void delay(unsigned int ticks);
void set_stack_pointer(void *stack_ptr);

struct baba {
  char bits;
  char byte;
  short word;
  int dword;
} babas[] = {
    {0xfa, 0xfb, (short)0xfffc, 0xfffffffd},
    {0x1a, 0x1b, 0x111c, 0x1111111d},
};

static char *hello = "Hello World\r\n";

void _start() {
  // stack to top of memory minus the mapped leds
  set_stack_pointer((void *)(TOP_OF_STACK));

  char *p = hello;
  while (*p) {
    *uart_out = *p;
    while (*uart_out)
      ;
    p++;
  }

  while (1) {
    *leds = babas[0].byte++;
    delay(TICKS_PER_SEC);
  }
}

inline void delay(volatile unsigned int ticks) {
  while (ticks--)
    ;
}

inline void set_stack_pointer(void *stack_ptr) {
  asm volatile("mv sp, %0" : : "r"(stack_ptr));
}