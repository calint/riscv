#define TOP_OF_RAM 0x1ffff

volatile unsigned char *leds = (unsigned char *)TOP_OF_RAM;
volatile unsigned char *uart_out = (unsigned char *)TOP_OF_RAM - 1;
volatile unsigned char *uart_in = (unsigned char *)TOP_OF_RAM - 2;

static char *hello = "Hello World\r\n";

void uart_send_str(const char *str);
void uart_send_char(char ch);
char uart_read_char();

void run() {
  uart_send_str(hello);

  while (1) {
    const char ch = uart_read_char();
    uart_send_char(ch);
    *leds = ch;
  }
}

void uart_send_str(const char *str) {
  while (*str) {
    while (*uart_out)
      ;
    *uart_out = *str;
    str++;
  }
}

void uart_send_char(const char ch) {
  while (*uart_out)
    ;
  *uart_out = ch;
}

char uart_read_char() {
  char ch = 0;
  while ((ch = *uart_in) == 0)
    ;
  return ch;
}
