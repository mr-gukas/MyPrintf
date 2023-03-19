; nasm -f elf64 -l printf.lst printf.s
; ld -s -o printf printf.o 
;
;


section .text 

global _printf, gukasPrintf

%if 0

_start:
    mov rdx, 0x6f 
;    mov rsi, tmp_str 
    mov rdi, msg
    
    push rdx 
;    push rsi
    push rdi
    
    mov rbp, rsp

    call _printf

    mov rax, 0x3c
    xor rdi, rdi 
    syscall


section .data 

tmp_str db "hello world", 0x00
msg     db "i can say: in oct %c is: %t", 0x0a, 0x0d, 0x00
%endif

section .text    
;==============================================================================
; displays the current state of the buffer, and then clears it 
;==============================================================================
; ENTRY: printfBuf - buffer for printf 
;        rdi       - position of last byte;
;
; EXIT:  rdi = printfBuf  

; DESTROY: 
;==============================================================================
resetBuf:
        push rax
        push rdx
        push rsi
        
        mov rdx, rdi
        mov rax, 0x01 
        mov rdi, 1
        mov rsi, printfBuf
        sub rdx, printfBuf
        syscall

        pop rsi
        pop rdx
        pop rax

        mov rdi, printfBuf 

        ret
;==============================================================================
; copy string into buffer
;==============================================================================
; ENTRY: rdi - buffer for write into;
;        rsi - string pointer
;
; EXIT:  none  

; DESTROY: rax, rdi, rsi
;==============================================================================
cpy2buf:

.cpy_loop:
        cmp rdi, printfBuf + buf_size - 1
        jbe .next 
        call resetBuf
.next:
        lodsb 

        cmp al, 0x00 
        je .done 

        stosb
        jmp .cpy_loop

.done:
        mov byte [rdi], 0x00 
        ret
;==============================================================================

;==============================================================================
; adapter inserting the first 6 arguments into the stack
;==============================================================================
; ENTRY: printfBuf - buffer for write into;
;        stack    - format str, args
;
; EXIT:  none  

; DESTROY: r10, rax, rcx
;==============================================================================
gukasPrintf:
        pop r10         ; save ret addr 
        
        push r9         ; save first 6 args
        push r8
        push rcx
        push rdx 
        push rsi 
        push rdi

        push rbp        ; save old rbp value 

        mov rbp, rsp    
        add rbp, 8      ; set rbp on ret addr
        
        call _printf

        pop rbp         ; return rbp to old value
        add rsp, 8*6    ; return rsp to old value

        push r10 
        ret

;==============================================================================

;==============================================================================
; outputs the string in the format specified by the user
;==============================================================================
; ENTRY: printfBuf - buffer for write into;
;        stack    - format str, args
;
; EXIT:  none  

; DESTROY: rax, rcx
;==============================================================================
_printf: 
        mov rsi, [rbp]
        mov rdi, printfBuf
        mov rbx, 0

loop:
        xor rax, rax
        lodsb 

        cmp al, '%'
        je .perc

        cmp al, 0x00 
        je finish 

        mov [rdi], al 
        inc rdi
        
        cmp rdi, printfBuf + buf_size - 1
        jbe .next 
        call resetBuf
.next:

        jmp loop

.perc:
        xor rax, rax
        lodsb 

        cmp al, '%' 
        je dbl_perc

        cmp al, 'b' 
        jb dflt 

        cmp al, 'x'
        ja dflt 
        
        sub al, 'b'

        mov rax, [switch_table + rax * 8]
        jmp rax

b_bin:
        mov cl, 1
        jmp set_num

c_chr:
        inc rbx
        mov ax, [rbp + 8*rbx]

        stosb 

        jmp end

d_dec:
        mov cl, 0
        jmp set_num

o_oct:
        mov cl, 3
        jmp set_num

s_str: 
        push rsi

        inc rbx
        mov rsi, [rbp + 8*rbx]

        call cpy2buf

        pop rsi
        
        jmp end

h_hex:
        mov cl, 4

set_num:
        inc rbx

        mov rdx, [rbp + 8*rbx]

        push rdi
        mov rdi, itoaBuf

        cmp cl, 0
        je  .write_dec

        call itoa
        jmp .num_done

.write_dec:
        call itoa10

.num_done:
        pop rdi

        push rsi

        mov rsi, itoaBuf
        call cpy2buf

        pop rsi

        jmp end

dbl_perc:
        stosb
        jmp end
dflt:
        mov byte [rdi], '%'
        inc rdi 
        mov al, byte [rsi - 1] 
        stosb

        jmp end
end:
        jmp loop
finish:
        call resetBuf
        
        ret
;==============================================================================
section .data

hex      db  "0123456789abcdef"

section .bss 

itoaBuf resb 0x100

section .text
;==============================================================================
; converts numbr into string (in base 2^n), write it in buf
;==============================================================================
; ENTRY: rdx - int value;
;        rdi - buf to write into
;         cl - base to write in (2^cl)
;
; EXIT:  rax - the count of written symbols

; DESTROY: rax, rcx
;==============================================================================
itoa:
        push rbx
        push r12

        mov rbx, rdx     
        mov r12, 1     
        shl r12, cl
        dec r12 

        xor rax, rax     
        mov rdx, rbx     

.count_loop:
        inc rax          
        shr rbx, cl      
        test rbx, rbx    
        jnz .count_loop  

        add rdi, rax
        mov byte [rdi], 0

        mov r12, 1
        shl r12, cl
        dec r12

.convert_loop:
        dec rdi               
        mov rbx, rdx
        and rbx, r12      
        mov al, [hex + rbx]   
        mov byte [rdi], al   
        shr rdx, cl           
        test rdx, rdx         
        jnz .convert_loop     

        pop r12
        pop rbx
        ret
;==============================================================================

;==============================================================================
; converts numbr into string (in base 10), write it in buf
;==============================================================================
; ENTRY: rdx - int value;
;        rdi - buf to write into
;
; EXIT:  r12 - the count of written symbols

; DESTROY: r8, r9, rdx
;==============================================================================
itoa10:
        xor r12, r12
        mov r8, rdx
        mov rax, rdx 
        mov r9, 0x0a

.count_len:
        xor rdx, rdx
        div r9

        inc rdi
        inc r12
        
        cmp rax, 0x00 
        ja .count_len

        mov rax, r8 
        mov byte [rdi], 0x00 
        dec rdi 

.write_num: 
        xor rdx, rdx
        div r9

        add dl, '0'
        mov [rdi], dl
        dec rdi 

        cmp rax, 0x00 
        ja .write_num 

        inc rdi

        ret
;==============================================================================

section .data

switch_table:
    dq b_bin
    dq c_chr
    dq d_dec
    times (10) dq dflt
    dq o_oct
    times (3)  dq dflt
    dq s_str
    times (4)  dq dflt
    dq h_hex


section .bss
buf_size equ 256

printfBuf resb buf_size





