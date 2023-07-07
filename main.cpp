extern "C" int gukasPrintf (const char *, ...);

int main()
{
    int i = -2147483648;
    
    for (int i = -2147483648; i <= 2147483647; ++i)
    {
        gukasPrintf("%d\n", i);
    }
    return 0;
}
