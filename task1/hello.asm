section .data
    msg         db "Hello world! Welcome to Assembly Programming", 0x0A
    msglen      equ $ - msg

section .text
    global _start
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msglen
    syscall

    mov rax, 60
    mov rdi, 0
    syscall