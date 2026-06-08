%macro PRINT 2
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

section .data

    ; --- ASCII Section ---
    hdr_ascii     db  "=== ASCII Demonstration ===", 0x0A
    hdr_ascii_len equ $ - hdr_ascii

    letters       db  'A', 'B', 'C', 'D', 'E', 0x0A
    letters_len   equ $ - letters

    codes_msg     db  "Decimal codes: 65  66  67  68  69", 0x0A
    codes_msg_len equ $ - codes_msg

    hex_msg       db  "Hex codes:     41  42  43  44  45", 0x0A
    hex_msg_len   equ $ - hex_msg

    newline       db  0x0A
    newline_len   equ $ - newline

    ; --- Data Sizes Section ---
    hdr_sizes     db  "=== Data Sizes: byte / word / dword ===", 0x0A
    hdr_sizes_len equ $ - hdr_sizes

    byte_msg      db  "byte_val  = 0x41       (1 byte  = 8 bits)", 0x0A
    byte_msg_len  equ $ - byte_msg

    word_msg      db  "word_val  = 0x4142     (2 bytes = 16 bits, stored: 42 41)", 0x0A
    word_msg_len  equ $ - word_msg

    dword_msg     db  "dword_val = 0x41424344 (4 bytes = 32 bits, stored: 44 43 42 41)", 0x0A
    dword_msg_len equ $ - dword_msg

    ; --- Two's Complement Section ---
    hdr_twos      db  "=== Two's Complement ===", 0x0A
    hdr_twos_len  equ $ - hdr_twos

    twos_msg1     db  " +5  =  00000101  (0x05)", 0x0A
    twos_msg1_len equ $ - twos_msg1

    twos_msg2     db  " -5  =  11111011  (0xFB) <- flip bits of +5, add 1", 0x0A
    twos_msg2_len equ $ - twos_msg2

    twos_msg3     db  " +5 + (-5) = 100000000 -> drop carry -> 0 (correct!)", 0x0A
    twos_msg3_len equ $ - twos_msg3

    ; --- Little Endian Section ---
    hdr_endian     db  "=== Little-Endian Storage ===", 0x0A
    hdr_endian_len equ $ - hdr_endian

    endian_msg1     db  " Value 0x12345678 stored at address N:", 0x0A
    endian_msg1_len equ $ - endian_msg1

    endian_msg2     db  " N+0: 0x78  (least significant byte first)", 0x0A
    endian_msg2_len equ $ - endian_msg2

    endian_msg3     db  " N+1: 0x56", 0x0A
    endian_msg3_len equ $ - endian_msg3

    endian_msg4     db  " N+2: 0x34", 0x0A
    endian_msg4_len equ $ - endian_msg4

    endian_msg5     db  " N+3: 0x12  (most significant byte last)", 0x0A
    endian_msg5_len equ $ - endian_msg5

    endian_msg6     db  " All x86/x64 PCs are little-endian.", 0x0A
    endian_msg6_len equ $ - endian_msg6

    done_msg        db  0x0A, "Demo complete.", 0x0A
    done_msg_len    equ $ - done_msg

    ; --- Actual data values in memory (inspect with GDB) ---
    byte_val   db  0x41
    word_val   dw  0x4142
    dword_val  dd  0x41424344

section .text
    global _start

_start:
    PRINT hdr_ascii,    hdr_ascii_len
    PRINT letters,      letters_len
    PRINT codes_msg,    codes_msg_len
    PRINT hex_msg,      hex_msg_len
    PRINT newline,      newline_len

    PRINT hdr_sizes,    hdr_sizes_len
    PRINT byte_msg,     byte_msg_len
    PRINT word_msg,     word_msg_len
    PRINT dword_msg,    dword_msg_len
    PRINT newline,      newline_len

    PRINT hdr_twos,     hdr_twos_len
    PRINT twos_msg1,    twos_msg1_len
    PRINT twos_msg2,    twos_msg2_len
    PRINT twos_msg3,    twos_msg3_len
    PRINT newline,      newline_len

    PRINT hdr_endian,   hdr_endian_len
    PRINT endian_msg1,  endian_msg1_len
    PRINT endian_msg2,  endian_msg2_len
    PRINT endian_msg3,  endian_msg3_len
    PRINT endian_msg4,  endian_msg4_len
    PRINT endian_msg5,  endian_msg5_len
    PRINT endian_msg6,  endian_msg6_len

    PRINT done_msg,     done_msg_len

    mov rax, 60
    mov rdi, 0
    syscall