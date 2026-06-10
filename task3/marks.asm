; marks.asm – Mark Statistics
;
; Computes total, average, highest, lowest and grade-band counts
; for a twelve-element byte array of marks.
;
; Addressing modes (search [MODE-n]):
;   [MODE-1] Immediate         – constant embedded in the instruction
;   [MODE-2] Direct (label)    – EA is the fixed address of a named variable
;   [MODE-3] Register indirect – EA = [reg]         pointer-based array walk
;   [MODE-4] Base+displacement – EA = [reg + const]  offset from pointer
;   [MODE-5] Base+index        – EA = [label + reg]  C-style array indexing
;
; Register allocation (r12-r15 and r8-r10 are preserved by Linux syscall):
;   r8d  – running total (dword; max 12×100 = 1200)
;   r9b  – highest mark
;   r10b – lowest mark
;   r12b – count: fail
;   r13b – count: pass
;   r14b – count: credit    (r14d also used as print-loop counter)
;   r15  – count: distinction / print-loop pointer (reused in sequence)
;   rbx  – average (preserved by print_uint and syscall)

%macro PRINT 2
    mov  rax, 1
    mov  rdi, 1
    mov  rsi, %1
    mov  rdx, %2
    syscall
%endmacro

; ─── data ─────────────────────────────────────────────────────────────────────
section .data

; Twelve marks stored as bytes (0-100 fits in one byte).
; Boundary test values are embedded directly in the array:
;   marks[2]  =   0  (absolute minimum)
;   marks[7]  =  39  (highest fail)
;   marks[8]  =  40  (lowest pass)
;   marks[11] =  69  (highest credit)
;   marks[10] =  70  (lowest distinction)
;   marks[4]  = 100  (absolute maximum)
marks     db  45, 72, 38, 91, 100, 67, 40, 39, 0, 55, 70, 69
MCOUNT    equ 12

DIST_MIN  equ 70          ; [MODE-1] compile-time constants used as immediates
CRED_MIN  equ 60
PASS_MIN  equ 40

msg_hdr    db  0x0A, "=== Mark Statistics ===", 0x0A
msg_hdr_l  equ $ - msg_hdr

msg_marks  db  "Marks      : "
msg_marks_l equ $ - msg_marks

msg_total  db  "Total      : "
msg_total_l equ $ - msg_total

msg_avg    db  "Average    : "
msg_avg_l  equ $ - msg_avg

msg_high   db  "Highest    : "
msg_high_l equ $ - msg_high

msg_low    db  "Lowest     : "
msg_low_l  equ $ - msg_low

msg_grade  db  0x0A, "--- Grade Bands ---", 0x0A
msg_grade_l equ $ - msg_grade

msg_dist   db  "Distinction (70-100) : "
msg_dist_l equ $ - msg_dist

msg_cred   db  "Credit      (60-69)  : "
msg_cred_l equ $ - msg_cred

msg_pass   db  "Pass        (40-59)  : "
msg_pass_l equ $ - msg_pass

msg_fail   db  "Fail        ( 0-39)  : "
msg_fail_l equ $ - msg_fail

comma_sp   db  ", "
newline    db  0x0A

; ─── bss ──────────────────────────────────────────────────────────────────────
section .bss
    nbuf  resb 12         ; scratch: integer → decimal string conversion

; ─── text ─────────────────────────────────────────────────────────────────────
section .text
    global _start

_start:
    PRINT msg_hdr, msg_hdr_l

    ; ── 1. Print marks array ──────────────────────────────────────────────────
    PRINT msg_marks, msg_marks_l

    lea   r15, [marks]           ; r15 = base pointer (r12-r15 survive syscall)
    mov   r14d, MCOUNT           ; [MODE-1] immediate count → r14d

.print_mark:
    movzx eax, byte [r15]        ; [MODE-3] register indirect: load *r15
    call  print_uint             ; prints eax without newline
    dec   r14d
    jz    .print_done
    PRINT comma_sp, 2            ; r14d/r15 are syscall-safe (not rcx/r11)
    inc   r15                    ; advance pointer one byte
    jmp   .print_mark
.print_done:
    PRINT newline, 1

    ; ── 2. Compute statistics ─────────────────────────────────────────────────

    ; [MODE-2] direct: use label address to seed highest and lowest with marks[0]
    movzx r9d,  byte [marks]     ; [MODE-2] r9b  = initial highest
    movzx r10d, byte [marks]     ; [MODE-2] r10b = initial lowest

    lea   rsi, [marks]           ; rsi = loop pointer
    mov   ecx, MCOUNT            ; [MODE-1] loop counter (no PRINT inside loop)
    xor   r8d,  r8d              ; total = 0 (dword accumulator)
    xor   r12d, r12d             ; cnt_fail        = 0
    xor   r13d, r13d             ; cnt_pass        = 0
    xor   r14d, r14d             ; cnt_credit      = 0 (r14d reused from print loop)
    xor   r15d, r15d             ; cnt_distinction = 0 (r15d reused from pointer)

.stat_loop:
    ; [MODE-3] register indirect — C equivalent: marks[i]  i = MCOUNT - ecx
    movzx eax, byte [rsi]        ; zero-extend byte → dword (prevents size mismatch)
    add   r8d, eax               ; total += mark (dword arithmetic, no byte overflow)

    cmp   al, r9b                ; byte compare: update highest
    jle   .chk_low
    mov   r9b, al
.chk_low:
    cmp   al, r10b               ; byte compare: update lowest
    jge   .classify
    mov   r10b, al

.classify:
    cmp   al, DIST_MIN           ; [MODE-1] immediate threshold comparisons
    jge   .is_dist
    cmp   al, CRED_MIN
    jge   .is_cred
    cmp   al, PASS_MIN
    jge   .is_pass
    inc   r12b                   ; fail
    jmp   .next_mark
.is_dist:
    inc   r15b
    jmp   .next_mark
.is_cred:
    inc   r14b
    jmp   .next_mark
.is_pass:
    inc   r13b
.next_mark:
    inc   rsi                    ; pointer += 1 (byte stride)
    dec   ecx
    jnz   .stat_loop

    ; ── 3. Addressing mode demonstrations ────────────────────────────────────
    ;
    ; [MODE-4] base+displacement: access marks[4] as *(base + 4)
    ; C: int v = *(ptr + 4);   equivalent to  ptr[4]
    lea   rsi, [marks]
    movzx eax, byte [rsi + 4]    ; [MODE-4] EA = rsi + 4  → marks[4] = 100

    ; [MODE-5] base+index: access marks[rbx] with label as the base
    ; C: int v = marks[idx];
    mov   rbx, 4                 ; index = 4
    movzx eax, byte [marks + rbx] ; [MODE-5] EA = &marks + rbx  → marks[4] = 100

    ; Both modes loaded the same value (100); demonstrates that
    ; [rsi+4] and [marks+rbx] (with rbx=4) are equivalent when rsi=&marks.

    ; ── 4. Compute integer average ───────────────────────────────────────────
    mov   eax, r8d               ; eax = total (dword)
    xor   edx, edx               ; zero EDX for 32-bit division (EDX:EAX ÷ ECX)
    mov   ecx, MCOUNT            ; [MODE-1] immediate divisor
    div   ecx                    ; EAX = average (truncated), EDX = remainder
    mov   ebx, eax               ; stash average in rbx (preserved by print_uint)

    ; ── 5. Print results ─────────────────────────────────────────────────────
    PRINT msg_total, msg_total_l
    mov   eax, r8d               ; dword total — demonstrating dword data movement
    call  print_uint
    PRINT newline, 1

    PRINT msg_avg, msg_avg_l
    mov   eax, ebx               ; rbx preserved across PRINT (not a syscall arg reg)
    call  print_uint
    PRINT newline, 1

    PRINT msg_high, msg_high_l
    movzx eax, r9b               ; byte → dword zero-extend (avoids size mismatch)
    call  print_uint
    PRINT newline, 1

    PRINT msg_low, msg_low_l
    movzx eax, r10b
    call  print_uint
    PRINT newline, 1

    PRINT msg_grade, msg_grade_l

    PRINT msg_dist, msg_dist_l
    movzx eax, r15b
    call  print_uint
    PRINT newline, 1

    PRINT msg_cred, msg_cred_l
    movzx eax, r14b
    call  print_uint
    PRINT newline, 1

    PRINT msg_pass, msg_pass_l
    movzx eax, r13b
    call  print_uint
    PRINT newline, 1

    PRINT msg_fail, msg_fail_l
    movzx eax, r12b
    call  print_uint
    PRINT newline, 1

    mov   rax, 60
    xor   rdi, rdi
    syscall

; ── print_uint(eax = unsigned value) ──────────────────────────────────────────
; Prints the decimal digits of eax to stdout. No newline.
; Saves and restores rbx, rcx, rdx, rsi.  Clobbers rax, rdi (via syscall).
print_uint:
    push  rbx
    push  rcx
    push  rdx
    push  rsi

    lea   rsi, [nbuf + 11]  ; point to end of scratch buffer; build right-to-left
    xor   ecx, ecx          ; digit count
    mov   rbx, 10           ; divisor
.conv:
    xor   edx, edx          ; zero RDX before each div (RDX:RAX ÷ RBX)
    div   rbx               ; RAX = quotient, RDX = remainder (0-9)
    add   dl, '0'           ; digit → ASCII
    mov   [rsi], dl         ; store in buffer
    dec   rsi
    inc   ecx
    test  eax, eax
    jnz   .conv

    inc   rsi               ; rsi → first (most-significant) digit
    mov   rax, 1            ; sys_write
    mov   rdi, 1            ; stdout
    mov   rdx, rcx          ; byte count (saved before syscall clobbers rcx)
    syscall

    pop   rsi
    pop   rdx
    pop   rcx
    pop   rbx
    ret
