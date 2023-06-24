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
  unsigned char ix;
} input_buffer;

static input_buffer inbuf;

typedef struct location {
  const char *description;
  unsigned char objects[256];
  unsigned char entities[8];
  unsigned char exits[6];
} location;

static const char *exit_names[] = {"north", "east", "south",
                                   "west",  "up",   "down"};

static location locations[] = {{"", {0}, {0}, {0}},
                               {"roome", {0}, {1}, {2, 3}},
                               {"office", {0}, {2}, {0, 0, 1}},
                               {"bathroom", {0}, {0}, {0}}};

typedef struct entity {
  const char *name;
  unsigned char location;
} entity;

static entity entities[] = {{"", 0}, {"me", 1}, {"u", 2}};

void input_inbuf();
void handle_inbuf();

unsigned char active_entity = 1;

void run() {
  uart_send_str(hello);
  while (1) {
    uart_send_str("u r in ");
    unsigned char current_location = entities[active_entity].location;
    uart_send_str(locations[current_location].description);
    uart_send_str("\r\nu c: ");
    unsigned char add_list_sep = 0;
    for (unsigned char i = 0; i < sizeof(entities) / sizeof(entity); i++) {
      if (i != active_entity && entities[i].location == current_location) {
        if (add_list_sep) {
          uart_send_str(", ");
        } else {
          add_list_sep = 1;
        }
        uart_send_str(entities[i].name);
      }
    }
    if (!add_list_sep) {
      uart_send_str("no one");
    }
    add_list_sep = 0;
    uart_send_str("\r\nexits: ");
    for (unsigned char i = 0; i < 6; i++) {
      if (locations[current_location].exits[i]) {
        if (add_list_sep) {
          uart_send_str(", ");
        } else {
          add_list_sep = 1;
        }
        uart_send_str(exit_names[i]);
      }
    }
    if (!add_list_sep) {
      uart_send_str("none");
    }
    uart_send_str("\r\n> ");
    input_inbuf();
    handle_inbuf();
  }
}

void handle_inbuf() {
  uart_send_str("\r\n");
  entities[active_entity].location++;
  if (entities[active_entity].location > 3) {
    entities[active_entity].location = 1;
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
