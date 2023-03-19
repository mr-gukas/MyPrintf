asm2c: printf 

printf: main.o printf.o
	gcc -no-pie main.o printf.o -o printf.out

main.o: main.cpp
	gcc -c -g main.cpp main.o

printf.o: printf.s
	nasm -f elf64 -g printf.s -o printf.o


c2asm:
	nasm -f elf64 -o origpr.o main.s
	gcc -no-pie -o origpr.out origpr.o

