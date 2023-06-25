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
                               {"roome", {0}, {1}, {2, 3, 0, 4}},
                               {"office", {1, 3}, {2}, {0, 0, 1}},
                               {"bathroom", {0}, {0}, {0}},
                               {"kitchen", {0}, {0}, {0, 1}}};

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
bool add_object_to_list(object_id list[], unsigned list_max_size, object_id id);
void remove_object_from_list_by_index(object_id list[], unsigned ix);
bool add_entity_to_list(entity_id list[], unsigned list_max_size, entity_id id);
void remove_entity_from_list_by_index(entity_id list[], unsigned ix);
void remove_entity_from_list(entity_id list[], unsigned list_max_size,
                             entity_id ix);
void action_give(const char *entity_name, const char *object_name);
void action_go(unsigned char dir);
void action_drop(const char *object_name);
void action_take(const char *object_name);
void describe_inventory();
void describe_current_location();
void input_inbuf();
void handle_inbuf();

unsigned char active_entity = 1;

void run() {
  uart_send_str(hello);
  while (1) {
    describe_current_location();
    uart_send_str(entities[active_entity].name);
    uart_send_str(" > ");
    input_inbuf();
    uart_send_str("\r\n");
    handle_inbuf();
    if (active_entity == 1)
      active_entity = 2;
    else
      active_entity = 1;
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

  // print objects in current location
  unsigned char add_list_sep = 0;
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
    uart_send_str("nothing");
  }
  uart_send_str("\r\n");

  // print entities in current location
  add_list_sep = 0;
  const entity_id *ents = locations[current_location].entities;
  for (unsigned i = 0; i < LOCATION_MAX_ENTITIES; i++) {
    const entity_id id = ents[i];
    if (!id)
      break;
    if (id == active_entity)
      continue;
    if (add_list_sep) {
      uart_send_str(", ");
    } else {
      add_list_sep = 1;
    }
    uart_send_str(entities[id].name);
  }
  if (add_list_sep) {
    uart_send_str(" is here\r\n");
  }

  // print exits from current location
  add_list_sep = 0;
  uart_send_str("exits: ");
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

bool add_object_to_list(object_id list[], unsigned list_max_size,
                        object_id id) {
  for (unsigned i = 0; i < list_max_size - 1; i++) {
    if (!list[i]) {
      list[i] = id;
      list[i + 1] = 0;
      return TRUE;
    }
  }
  uart_send_str("space full\r\n");
  return FALSE;
}

bool add_entity_to_list(entity_id list[], unsigned list_max_size,
                        entity_id id) {
  for (unsigned i = 0; i < list_max_size - 1; i++) {
    if (list[i])
      continue;
    list[i] = id;
    list[i + 1] = 0;
    return TRUE;
  }
  uart_send_str("location full\r\n");
  return FALSE;
}

void remove_entity_from_list(entity_id list[], unsigned list_max_size,
                             entity_id id) {
  for (unsigned i = 0; i < list_max_size - 1; i++) {
    if (list[i] != id)
      continue;
    for (unsigned j = i; j < list_max_size - 1; j++) {
      list[j] = list[j + 1];
      if (!list[j])
        return;
    }
  }
  uart_send_str("entity not here\r\n");
}

void remove_entity_from_list_by_index(entity_id list[], unsigned ix) {
  entity_id *ptr = &list[ix];
  while (1) {
    entity_id *nxt = ptr + 1;
    *ptr = *nxt;
    if (!*nxt)
      return;
    ptr++;
  }
}

void action_take(const char *object_name) {
  entity *ent = &entities[active_entity];
  object_id *objs = locations[ent->location].objects;
  for (unsigned i = 0; i < LOCATION_MAX_OBJECTS; i++) {
    const object_id id = objs[i];
    if (!id)
      break;
    if (!strings_equal(objects[id].name, object_name))
      continue;
    if (add_object_to_list(ent->inventory, ENTITY_MAX_OBJECTS, id)) {
      remove_object_from_list_by_index(objs, i);
    }
    return;
  }
  uart_send_str(object_name);
  uart_send_str(" not here\r\n\r\n");
}

void action_drop(const char *object_name) {
  entity *ent = &entities[active_entity];
  object_id *objs = ent->inventory;
  for (unsigned i = 0; i < ENTITY_MAX_OBJECTS; i++) {
    const object_id id = objs[i];
    if (!id)
      break;
    if (!strings_equal(objects[id].name, object_name))
      continue;
    if (add_object_to_list(locations[ent->location].objects,
                           LOCATION_MAX_OBJECTS, id)) {
      remove_object_from_list_by_index(objs, i);
    }
    return;
  }
  uart_send_str("u don't have ");
  uart_send_str(object_name);
  uart_send_str("\r\n\r\n");
}

void action_go(unsigned char dir) {
  entity *ent = &entities[active_entity];
  location *loc = &locations[ent->location];
  location_id to = loc->exits[dir];
  if (!to) {
    uart_send_str("cannot go there\r\n\r\n");
    return;
  }
  if (add_entity_to_list(locations[to].entities, LOCATION_MAX_ENTITIES,
                         active_entity)) {
    remove_entity_from_list(loc->entities, LOCATION_MAX_ENTITIES,
                            active_entity);
  }
  ent->location = to;
}

void action_give(const char *entity_name, const char *object_name) {
  entity *ent = &entities[active_entity];
  location *loc = &locations[ent->location];
  entity_id *ents = loc->entities;
  for (unsigned i = 0; i < LOCATION_MAX_ENTITIES; i++) {
    if (!ents[i])
      break;
    entity *to = &entities[ents[i]];
    if (!strings_equal(to->name, entity_name))
      continue;
    object_id *objs = ent->inventory;
    for (unsigned j = 0; j < ENTITY_MAX_OBJECTS; j++) {
      const object_id oid = objs[j];
      if (!oid)
        break;
      if (!strings_equal(objects[oid].name, object_name))
        continue;
      if (add_object_to_list(to->inventory, ENTITY_MAX_OBJECTS, oid)) {
        remove_object_from_list_by_index(objs, j);
      }
      return;
    }
    uart_send_str(object_name);
    uart_send_str(" not in inventory\r\n\r\n");
    return;
  }
  uart_send_str(entity_name);
  uart_send_str(" is not here\r\n\r\n");
}

void handle_inbuf() {
  const char *words[8];
  char *ptr = inbuf.line;
  unsigned nwords = 0;
  while (1) {
    words[nwords++] = ptr;
    while (*ptr && *ptr != ' ') {
      ptr++;
    }
    if (!*ptr)
      break;
    *ptr = 0;
    ptr++;
    if (nwords == sizeof(words) / sizeof(const char *)) {
      uart_send_str("too many words, some ignored\r\n\r\n");
      break;
    }
  }
  //  for (unsigned i = 0; i < nwords; i++) {
  //    uart_send_str(words[i]);
  //    uart_send_str("\r\n");
  //  }
  if (strings_equal(words[0], "i")) {
    describe_inventory();
    uart_send_str("\r\n");
  } else if (strings_equal(words[0], "t")) {
    if (nwords < 2) {
      uart_send_str("take what\r\n\r\n");
      return;
    }
    action_take(words[1]);
  } else if (strings_equal(words[0], "d")) {
    if (nwords < 2) {
      uart_send_str("drop what\r\n\r\n");
      return;
    }
    action_drop(words[1]);
  } else if (strings_equal(words[0], "n")) {
    action_go(0);
  } else if (strings_equal(words[0], "e")) {
    action_go(1);
  } else if (strings_equal(words[0], "s")) {
    action_go(2);
  } else if (strings_equal(words[0], "w")) {
    action_go(3);
  } else if (strings_equal(words[0], "g")) {
    if (nwords < 2) {
      uart_send_str("give to who\r\n\r\n");
      return;
    }
    if (nwords < 3) {
      uart_send_str("give what\r\n\r\n");
      return;
    }
    action_give(words[1], words[2]);
  } else {
    uart_send_str("not understood\r\n\r\n");
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
    if (ch == CHAR_BACKSPACE) {
      if (inbuf.ix > 0) {
        inbuf.ix--;
        uart_send_char(ch);
      }
    } else if (ch == CHAR_CARRIAGE_RETURN ||
               inbuf.ix == sizeof(inbuf.line) - 1) {
      inbuf.line[inbuf.ix] = 0;
      inbuf.ix = 0;
      return;
    } else {
      inbuf.line[inbuf.ix] = ch;
      inbuf.ix++;
      uart_send_char(ch);
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
