void _start() {
    char* leds = (char*)0xffffffff;
    *leds = 0xfa;
    while(1);
}