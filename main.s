section .data
    line db "My name is %s and I am %d years old.", 10, 0
    old  dd 18 
    name db "Mr. Gukas", 0

section .text
    global main

extern printf

main:
    push rbp
    mov rbp, rsp

    mov edi, line
    mov esi, name
    mov edx, [old]
    xor eax, eax
    call printf

    xor eax, eax
    pop rbp
    ret

