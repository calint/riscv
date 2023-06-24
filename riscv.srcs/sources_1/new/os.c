#define CPU_FREQ_HZ 50000000
#define TICKS_PER_SEC CPU_FREQ_HZ / 60
#define TOP_OF_RAM 0x1ffff
#define TOP_OF_STACK 0x1fff0 // note. update 'os_start.S' when changed
#define CHAR_BACKSPACE 0x7f
#define CHAR_CARRIAGE_RETURN 0x0d
#define LOCATION_MAX_OBJECTS 128
#define LOCATION_MAX_ENTITIES 8
#define LOCATION_MAX_EXITS 6
#define ENTITY_MAX_OBJECTS 32
#define TRUE 1
#define FALSE 0

typedef unsigned char bool;
typedef unsigned char location_id;
typedef unsigned char object_id;
typedef unsigned char entity_id;

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
  const char *name;
  object_id objects[LOCATION_MAX_OBJECTS];
  entity_id entities[LOCATION_MAX_ENTITIES];
  location_id exits[LOCATION_MAX_EXITS];
} location;

static const char *exit_names[] = {"north", "east", "south",
                                   "west",  "up",   "down"};

static location locations[] = {{"", {0}, {0}, {0}},
                               {"roome", {0}, {1}, {2, 3}},
                               {"office", {3, 1}, {2}, {0, 0, 1}},
                               {"bathroom", {0}, {0}, {0}}};

typedef struct entity {
  const char *name;
  location_id location;
  object_id inventory[ENTITY_MAX_OBJECTS];
} entity;

static entity entities[] = {{"", 0, {0}}, {"me", 1, {2}}, {"u", 2, {0}}};

typedef struct object {
  const char *name;
} object;

static object objects[] = {{""}, {"notebook"}, {"mirror"}, {"lighter"}};

bool strings_equal(const char *s1, const char *s2);
void add_object_to_list(object_id list[], unsigned list_max_size, object_id id);
void remove_object_from_list(object_id list[], object_id id);
void add_entity_to_list(entity_id list[], entity_id id);
void remove_entity_from_list(entity_id list[], entity_id id);

void describe_inventory();
void describe_current_location();
void input_inbuf();
void handle_inbuf();

unsigned char active_entity = 1;

void run() {
  uart_send_str(hello);
  while (1) {
    describe_current_location();
    uart_send_str("> ");
    input_inbuf();
    handle_inbuf();
  }
}

bool strings_equal(const char *s1, const char *s2) {
  while (1) {
    char diff = *s1 - *s2;
    if (diff)
      return FALSE;
    if (!*s1 && !*s2)
      return TRUE;
    if (!*s1 || !*s2)
      return FALSE;
    s1++;
    s2++;
  }
}

void describe_current_location() {
  uart_send_str("u r in ");
  const location_id current_location = entities[active_entity].location;
  uart_send_str(locations[current_location].name);
  uart_send_str("\r\nu c: ");
  // print entities in current location
  unsigned char add_list_sep = 0;
  const entity_id *ents = locations[current_location].entities;
  for (unsigned i = 0; i < LOCATION_MAX_ENTITIES; i++) {
    const entity_id id = ents[i];
    if (!id)
      break;
    if (id != active_entity) {
      if (add_list_sep) {
        uart_send_str(", ");
      } else {
        add_list_sep = 1;
      }
      uart_send_str(entities[id].name);
    }
  }
  // print objects in current location
  const object_id *objs = locations[current_location].objects;
  for (unsigned i = 0; i < LOCATION_MAX_OBJECTS; i++) {
    const object_id id = objs[i];
    if (!id)
      break;
    if (add_list_sep) {
      uart_send_str(", ");
    } else {
      add_list_sep = 1;
    }
    uart_send_str(objects[id].name);
  }
  if (!add_list_sep) {
    uart_send_str("no one");
  }
  // print exits from current location
  add_list_sep = 0;
  uart_send_str("\r\nexits: ");
  for (unsigned i = 0; i < LOCATION_MAX_EXITS; i++) {
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
  uart_send_str("\r\n");
}

void remove_object_from_list_by_index(object_id list[], unsigned ix) {
  object_id *ptr = &list[ix];
  while (1) {
    object_id *nxt = ptr + 1;
    *ptr = *nxt;
    if (!*nxt)
      return;
    ptr++;
  }
}

void add_object_to_list(object_id list[], unsigned list_max_size,
                        object_id id) {
  for (unsigned i = 0; i < list_max_size - 1; i++) {
    if (!list[i]) {
      list[i] = id;
      list[i + 1] = 0;
      return;
    }
  }
  uart_send_str("inventory full\r\n");
}

void action_take(const char *object_name) {
  const location_id current_location = entities[active_entity].location;
  object_id *objs = locations[current_location].objects;
  for (unsigned i = 0; i < LOCATION_MAX_OBJECTS; i++) {
    const object_id id = objs[i];
    if (!id)
      break;
    if (!strings_equal(objects[id].name, object_name))
      continue;
    remove_object_from_list_by_index(objs, i);
    add_object_to_list(entities[active_entity].inventory, ENTITY_MAX_OBJECTS,
                       id);
    return;
  }
  uart_send_str(object_name);
  uart_send_str(" not here\r\n");
}

void action_drop(const char *object_name) {
  object_id *objs = entities[active_entity].inventory;
  for (unsigned i = 0; i < ENTITY_MAX_OBJECTS; i++) {
    const object_id id = objs[i];
    if (!id)
      break;
    if (!strings_equal(objects[id].name, object_name))
      continue;
    remove_object_from_list_by_index(objs, i);
    return;
  }
  uart_send_str("u don't have ");
  uart_send_str(object_name);
  uart_send_str("\r\n");
}

void handle_inbuf() {
  uart_send_str("\r\n");
  if (strings_equal(inbuf.line, "i")) {
    describe_inventory();
    uart_send_str("\r\n");
    return;
  }
  if (strings_equal(inbuf.line, "t")) {
    action_take("notebook");
    uart_send_str("\r\n");
    return;
  }
  if (strings_equal(inbuf.line, "d")) {
    action_drop("notebook");
    uart_send_str("\r\n");
    return;
  }

  entities[active_entity].location++;
  if (entities[active_entity].location > 3) {
    entities[active_entity].location = 1;
  }
}

void describe_inventory() {
  uart_send_str("u have: ");
  bool add_list_sep = FALSE;
  const object_id *inv = entities[active_entity].inventory;
  for (unsigned i = 0; i < ENTITY_MAX_OBJECTS; i++) {
    const object_id id = inv[i];
    if (!id)
      break;
    if (add_list_sep) {
      uart_send_str(", ");
    } else {
      add_list_sep = TRUE;
    }
    uart_send_str(objects[id].name);
  }
  if (!add_list_sep) {
    uart_send_str("nothing");
  }
  uart_send_str("\r\n");
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
