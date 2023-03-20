extern "C" int gukasPrintf (const char *, ...);

int main()
{
    gukasPrintf("My name is %s, I am %d y.o, in hex: %x, in oct: %o, in bin: %b\n also i can do %%, %t, and i love %c\n", "Vladimir", -1, 18, 18, 18, 'u');

    return 0;
}
