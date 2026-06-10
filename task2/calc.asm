; calc.asm – Arithmetic & Logic Calculator
; Demonstrates ADD, SUB, INC, DEC, MUL, IMUL, DIV, IDIV,
;             AND, OR, XOR, NOT, TEST with live CF/ZF/SF/OF display.

%macro PRINT 2
    mov  rax, 1
    mov  rdi, 1
    mov  rsi, %1
    mov  rdx, %2
    syscall
%endmacro

%macro READ 2
    mov  rax, 0
    mov  rdi, 0
    mov  rsi, %1
    mov  rdx, %2
    syscall
%endmacro

section .data

msg_banner   db 0x0A, "=== Arithmetic & Logic Calculator ===", 0x0A
msg_banner_l equ $ - msg_banner

msg_p1       db "Enter first number  (0-9): "
msg_p1_l     equ $ - msg_p1

msg_p2       db "Enter second number (0-9): "
msg_p2_l     equ $ - msg_p2

msg_menu     db 0x0A
             db "  1. ADD    2. SUB    3. INC(a)  4. DEC(a)", 0x0A
             db "  5. MUL    6. IMUL   7. DIV     8. IDIV",   0x0A
             db "  9. AND    a. OR     b. XOR     c. NOT(a)",  0x0A
             db "  d. TEST   q. Quit", 0x0A
msg_menu_l   equ $ - msg_menu

msg_choice   db "Choice: "
msg_choice_l equ $ - msg_choice

msg_op       db 0x0A, "Op     : "
msg_op_l     equ $ - msg_op

msg_res      db "Result : "
msg_res_l    equ $ - msg_res

msg_flg      db "Flags  : "
msg_flg_l    equ $ - msg_flg

msg_inv      db 0x0A, "[!] Invalid choice.", 0x0A
msg_inv_l    equ $ - msg_inv

msg_divz     db 0x0A, "[!] Division by zero.", 0x0A
msg_divz_l   equ $ - msg_divz

msg_badinp   db "[!] Enter a single digit 0-9.", 0x0A
msg_badinp_l equ $ - msg_badinp

msg_bye      db 0x0A, "Goodbye!", 0x0A
msg_bye_l    equ $ - msg_bye

; operation name strings (printed after "Op     : ")
op_add    db "ADD", 0x0A
op_add_l  equ $ - op_add
op_sub    db "SUB", 0x0A
op_sub_l  equ $ - op_sub
op_inc    db "INC(a)", 0x0A
op_inc_l  equ $ - op_inc
op_dec    db "DEC(a)", 0x0A
op_dec_l  equ $ - op_dec
op_mul    db "MUL  (unsigned, AX = AL * BL)", 0x0A
op_mul_l  equ $ - op_mul
op_imul   db "IMUL (signed,   rax = rax * rbx)", 0x0A
op_imul_l equ $ - op_imul
op_div    db "DIV  (unsigned, AL = AX / BL)", 0x0A
op_div_l  equ $ - op_div
op_idiv   db "IDIV (signed,   AL = AX / BL)", 0x0A
op_idiv_l equ $ - op_idiv
op_and    db "AND", 0x0A
op_and_l  equ $ - op_and
op_or     db "OR", 0x0A
op_or_l   equ $ - op_or
op_xor    db "XOR", 0x0A
op_xor_l  equ $ - op_xor
op_not    db "NOT(a)  -- does not modify flags", 0x0A
op_not_l  equ $ - op_not
op_test   db "TEST a,b  (a AND b; flags only, result discarded)", 0x0A
op_test_l equ $ - op_test

; flag indicator strings
s_cf1  db "CF=1 "
s_cf0  db "CF=0 "
s_zf1  db "ZF=1 "
s_zf0  db "ZF=0 "
s_sf1  db "SF=1 "
s_sf0  db "SF=0 "
s_of1  db "OF=1"
s_of0  db "OF=0"

minus_sign  db "-"
newline     db 0x0A

section .bss
    num1   resb 1
    num2   resb 1
    inbuf  resb 4
    nbuf   resb 12      ; scratch buffer for int-to-string conversion

section .text
    global _start

; ── entry ──────────────────────────────────────────────────────────────────────
_start:
    PRINT msg_banner, msg_banner_l

.get_a:
    PRINT msg_p1, msg_p1_l
    READ  inbuf, 4
    movzx rax, byte [inbuf]
    cmp al, '0'
    jl  .bad_a
    cmp al, '9'
    jg  .bad_a
    sub al, '0'             ; ASCII digit → numeric value
    mov [num1], al
    jmp .get_b
.bad_a:
    PRINT msg_badinp, msg_badinp_l
    jmp .get_a

.get_b:
    PRINT msg_p2, msg_p2_l
    READ  inbuf, 4
    movzx rax, byte [inbuf]
    cmp al, '0'
    jl  .bad_b
    cmp al, '9'
    jg  .bad_b
    sub al, '0'
    mov [num2], al
    jmp menu_loop
.bad_b:
    PRINT msg_badinp, msg_badinp_l
    jmp .get_b

; ── menu loop ──────────────────────────────────────────────────────────────────
menu_loop:
    PRINT msg_menu,   msg_menu_l
    PRINT msg_choice, msg_choice_l
    READ  inbuf, 4
    movzx rax, byte [inbuf]

    cmp al, '1'
    je  do_add
    cmp al, '2'
    je  do_sub
    cmp al, '3'
    je  do_inc
    cmp al, '4'
    je  do_dec
    cmp al, '5'
    je  do_mul
    cmp al, '6'
    je  do_imul
    cmp al, '7'
    je  do_div
    cmp al, '8'
    je  do_idiv
    cmp al, '9'
    je  do_and
    cmp al, 'a'
    je  do_or
    cmp al, 'b'
    je  do_xor
    cmp al, 'c'
    je  do_not
    cmp al, 'd'
    je  do_test
    cmp al, 'q'
    je  do_quit
    PRINT msg_inv, msg_inv_l    ; invalid choice – re-prompt
    jmp menu_loop

; ── arithmetic operations ──────────────────────────────────────────────────────

do_add:
    PRINT msg_op, msg_op_l
    PRINT op_add, op_add_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    add   al, bl
    pushfq
    pop   r12               ; snapshot flags before any other instruction
    movzx rax, al
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_sub:
    PRINT msg_op, msg_op_l
    PRINT op_sub, op_sub_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    sub   al, bl
    pushfq
    pop   r12
    movsx rax, al           ; sign-extend so negatives print correctly
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_inc:
    PRINT msg_op, msg_op_l
    PRINT op_inc, op_inc_l
    movzx rax, byte [num1]
    inc   al                ; INC does not modify CF
    pushfq
    pop   r12
    movzx rax, al
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_dec:
    PRINT msg_op, msg_op_l
    PRINT op_dec, op_dec_l
    movzx rax, byte [num1]
    dec   al                ; DEC does not modify CF
    pushfq
    pop   r12
    movsx rax, al
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_mul:
    PRINT msg_op, msg_op_l
    PRINT op_mul, op_mul_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    mul   bl                ; unsigned: AX = AL * BL; sets CF/OF if AH != 0
    pushfq
    pop   r12
    movzx rax, ax           ; result is in AX
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_imul:
    PRINT msg_op, msg_op_l
    PRINT op_imul, op_imul_l
    movsx rax, byte [num1]
    movsx rbx, byte [num2]
    imul  rax, rbx          ; signed: rax = rax * rbx; sets CF/OF on overflow
    pushfq
    pop   r12
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_div:
    PRINT msg_op, msg_op_l
    PRINT op_div, op_div_l
    movzx rbx, byte [num2]
    test  rbx, rbx
    jz    .zero
    movzx rax, byte [num1]  ; AX = 0x00nn (high byte clear)
    div   bl                 ; unsigned: AL = AX / BL, AH = remainder
    pushfq
    pop   r12
    movzx rax, al
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop
.zero:
    PRINT msg_divz, msg_divz_l
    jmp   menu_loop

do_idiv:
    PRINT msg_op, msg_op_l
    PRINT op_idiv, op_idiv_l
    movzx rbx, byte [num2]
    test  rbx, rbx
    jz    .zero
    movsx ax, byte [num1]   ; sign-extend byte → AX for 8-bit idiv
    idiv  bl                 ; signed: AL = AX / BL, AH = remainder
    pushfq
    pop   r12
    movsx rax, al
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop
.zero:
    PRINT msg_divz, msg_divz_l
    jmp   menu_loop

; ── logical operations ─────────────────────────────────────────────────────────

do_and:
    PRINT msg_op, msg_op_l
    PRINT op_and, op_and_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    and   rax, rbx          ; clears CF and OF; sets ZF/SF/PF
    pushfq
    pop   r12
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_or:
    PRINT msg_op, msg_op_l
    PRINT op_or, op_or_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    or    rax, rbx
    pushfq
    pop   r12
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_xor:
    PRINT msg_op, msg_op_l
    PRINT op_xor, op_xor_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    xor   rax, rbx
    pushfq
    pop   r12
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_not:
    PRINT msg_op, msg_op_l
    PRINT op_not, op_not_l
    movzx rax, byte [num1]
    not   al                ; NOT does not affect any flags
    pushfq
    pop   r12
    movzx rax, al
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_test:
    PRINT msg_op, msg_op_l
    PRINT op_test, op_test_l
    movzx rax, byte [num1]
    movzx rbx, byte [num2]
    test  rax, rbx          ; sets ZF/SF/PF; clears CF,OF; result not stored
    pushfq
    pop   r12
    and   rax, rbx          ; recompute same value for display only
    call  show_result
    mov   rdi, r12
    call  show_flags
    jmp   menu_loop

do_quit:
    PRINT msg_bye, msg_bye_l
    mov   rax, 60
    xor   rdi, rdi
    syscall

; ── show_result(rax = signed 64-bit value) ─────────────────────────────────────
; Prints "Result : <decimal>\n"
show_result:
    push rbp
    push rbx
    push rcx
    push rdx
    push rax                ; save argument across PRINT call below

    PRINT msg_res, msg_res_l

    pop  rax                ; restore argument
    test rax, rax
    jns  .positive
    push rax
    PRINT minus_sign, 1     ; print leading '-' for negative values
    pop  rax
    neg  rax
.positive:
    lea  rsi, [nbuf + 11]   ; build decimal string right-to-left
    mov  byte [rsi], 0x0A
    dec  rsi
    xor  ecx, ecx
    mov  rbx, 10
.loop:
    xor  edx, edx
    div  rbx                ; rax = quotient, rdx = next digit
    add  dl, '0'
    mov  [rsi], dl
    dec  rsi
    inc  ecx
    test rax, rax
    jnz  .loop

    inc  rsi                ; advance to first digit
    inc  ecx                ; +1 to include the newline
    mov  rax, 1
    mov  rdi, 1
    mov  rdx, rcx
    syscall

    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

; ── show_flags(rdi = saved rflags) ────────────────────────────────────────────
; Prints "Flags  : CF=? ZF=? SF=? OF=?\n"
show_flags:
    push rbx
    mov  rbx, rdi

    PRINT msg_flg, msg_flg_l

    bt   rbx, 0             ; CF = bit 0
    jc   .cf1
    PRINT s_cf0, 5
    jmp  .zf
.cf1:
    PRINT s_cf1, 5

.zf:
    bt   rbx, 6             ; ZF = bit 6
    jc   .zf1
    PRINT s_zf0, 5
    jmp  .sf
.zf1:
    PRINT s_zf1, 5

.sf:
    bt   rbx, 7             ; SF = bit 7
    jc   .sf1
    PRINT s_sf0, 5
    jmp  .of
.sf1:
    PRINT s_sf1, 5

.of:
    bt   rbx, 11            ; OF = bit 11
    jc   .of1
    PRINT s_of0, 4
    jmp  .done
.of1:
    PRINT s_of1, 4

.done:
    PRINT newline, 1
    pop  rbx
    ret
