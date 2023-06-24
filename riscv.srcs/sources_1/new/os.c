#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60
#define TOP_OF_RAM 0x1ffff
#define TOP_OF_STACK 0x1fff0 // note. update 'os_start.S' when changed
#define CHAR_BACKSPACE 0x7f
#define CHAR_CARRIAGE_RETURN 0x0d

volatile unsigned char *leds = (unsigned char *)TOP_OF_RAM;
volatile unsigned char *uart_out = (unsigned char *)TOP_OF_RAM - 1;
volatile unsigned char *uart_in = (unsigned char *)TOP_OF_RAM - 2;

void delay(unsigned int ticks);
void uart_send_str(const char *str);
void uart_send_char(char ch);
char uart_read_char();
void uart_send_hex_byte(char ch);
void uart_send_hex_nibble(char nibble);

static char *hello = "welcome to adventure #3\r\n\r\n";

typedef struct input_buffer {
  char line[80];
  char ix;
} input_buffer;

static input_buffer inbuf;

typedef struct location {
  const char *description;
  char objects[256];
  char exits[8];
} location;

static location locations[] = {{"", {0}, {0}},
                               {"u r in roome", {0}, {2}},
                               {"office", {0}, {0, 0, 0, 0, 1}}};

typedef struct entity {
  const char *name;
  char location;
} entity;

static entity entities[] = {{"me", 1}, {"u", 2}};

void input_inbuf();
void handle_inbuf();

void run() {
  uart_send_str(hello);

  while (1) {
    uart_send_str(locations[entities[0].location].description);
    uart_send_str("\r\n> ");
    input_inbuf();
    handle_inbuf();
  }
}

void input_inbuf() {
  while (1) {
    const char ch = uart_read_char();
    uart_send_char(ch);
    if (ch == CHAR_BACKSPACE) {
      if (inbuf.ix > 0) {
        inbuf.ix--;
      }
    } else if (ch == CHAR_CARRIAGE_RETURN ||
               inbuf.ix == sizeof(inbuf.line) - 1) {
      inbuf.line[inbuf.ix] = 0;
      inbuf.ix = 0;
      return;
    } else {
      inbuf.line[inbuf.ix] = ch;
      inbuf.ix++;
    }
    *leds = inbuf.ix;
  }
}

void handle_inbuf() {
  uart_send_str("\r\n< ");
  uart_send_str(inbuf.line);
  uart_send_str("\r\n");
}

void uart_send_str(const char *str) {
  while (*str) {
    while (*uart_out)
      ;
    *uart_out = *str++;
  }
}

void uart_send_hex_byte(char ch) {
  uart_send_hex_nibble((ch & 0xf0) >> 4);
  uart_send_hex_nibble(ch & 0x0f);
}

void uart_send_hex_nibble(char nibble) {
  if (nibble < 10) {
    uart_send_char('0' + nibble);
  } else {
    uart_send_char('A' + (nibble - 10));
  }
}

void uart_send_char(char ch) {
  while (*uart_out)
    ;
  *uart_out = ch;
}

char uart_read_char() {
  char ch;
  while ((ch = *uart_in) == 0)
    ;
  return ch;
}

inline void delay(volatile unsigned int ticks) {
  while (ticks--)
    ;
}
