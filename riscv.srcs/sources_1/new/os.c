#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60
#define TOP_OF_RAM 0x1ffff
#define TOP_OF_STACK 0x1fff0

volatile unsigned char *leds = (unsigned char *)TOP_OF_RAM;
volatile unsigned char *uart_out = (unsigned char *)TOP_OF_RAM - 1;
volatile unsigned char *uart_in = (unsigned char *)TOP_OF_RAM - 2;

void delay(unsigned int ticks);
void uart_send(char *str);

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

void run() {
  uart_send(hello);

  while (1) {
    unsigned char ch;
    while ((ch = *uart_in) == 0)
      ;
    *uart_out = ch;
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

void uart_send(char *str) {
  while (*str) {
    *uart_out = *str;
    while (*uart_out)
      ;
    str++;
  }
}
