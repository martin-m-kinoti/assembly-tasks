# Memory Map — `marks.asm`

This document lists every variable, array, and buffer declared in `marks.asm`,
its size, and its byte offset within its section — plus the registers used as
"variables" during execution.

## `.data` section

Offsets are byte offsets from the start of the `.data` section (i.e. from the
address of `marks`, the first label declared).

| Label | Type | Size (bytes) | Offset | End | Contents |
|-------|------|--------------|-------:|----:|----------|
| `marks` | `db` ×12 | 12 | 0 | 12 | The mark array (see breakdown below) |
| `msg_hdr` | `db` | 25 | 12 | 37 | `"\n=== Mark Statistics ===\n"` |
| `msg_marks` | `db` | 13 | 37 | 50 | `"Marks      : "` |
| `msg_total` | `db` | 13 | 50 | 63 | `"Total      : "` |
| `msg_avg` | `db` | 13 | 63 | 76 | `"Average    : "` |
| `msg_high` | `db` | 13 | 76 | 89 | `"Highest    : "` |
| `msg_low` | `db` | 13 | 89 | 102 | `"Lowest     : "` |
| `msg_grade` | `db` | 21 | 102 | 123 | `"\n--- Grade Bands ---\n"` |
| `msg_dist` | `db` | 23 | 123 | 146 | `"Distinction (70-100) : "` |
| `msg_cred` | `db` | 23 | 146 | 169 | `"Credit      (60-69)  : "` |
| `msg_pass` | `db` | 23 | 169 | 192 | `"Pass        (40-59)  : "` |
| `msg_fail` | `db` | 23 | 192 | 215 | `"Fail        ( 0-39)  : "` |
| `comma_sp` | `db` | 2 | 215 | 217 | `", "` |
| `newline` | `db` | 1 | 217 | 218 | `"\n"` |

Each `*_l` symbol (`msg_hdr_l`, `msg_marks_l`, …) is an `equ $ - label`
constant, so its value equals the "Size" column above — the assembler
computes it, it is not stored in memory.

`MCOUNT`, `DIST_MIN`, `CRED_MIN`, `PASS_MIN` are also `equ` constants
(`12`, `70`, `60`, `40`). They occupy **no memory** — every reference to
them is replaced with an immediate value at assembly time ([MODE-1]).

### `marks` array detail (offsets 0–11)

| Offset | Address | Value | Hex | Grade | Notes |
|-------:|---------|------:|-----|-------|-------|
| `marks+0`  | `marks` | 45  | `0x2D` | Pass | |
| `marks+1`  | `marks+1` | 72  | `0x48` | Distinction | |
| `marks+2`  | `marks+2` | 38  | `0x26` | Fail | |
| `marks+3`  | `marks+3` | 91  | `0x5B` | Distinction | |
| `marks+4`  | `marks+4` | 100 | `0x64` | Distinction | boundary: absolute max |
| `marks+5`  | `marks+5` | 67  | `0x43` | Credit | |
| `marks+6`  | `marks+6` | 40  | `0x28` | Pass | boundary: lowest pass |
| `marks+7`  | `marks+7` | 39  | `0x27` | Fail | boundary: highest fail |
| `marks+8`  | `marks+8` | 0   | `0x00` | Fail | boundary: absolute min |
| `marks+9`  | `marks+9` | 55  | `0x37` | Pass | |
| `marks+10` | `marks+10` | 70  | `0x46` | Distinction | boundary: lowest distinction |
| `marks+11` | `marks+11` | 69  | `0x45` | Credit | boundary: highest credit |

## `.bss` section

| Label | Type | Size (bytes) | Offset | Purpose |
|-------|------|--------------|-------:|---------|
| `nbuf` | `resb 12` | 12 | 0 | Scratch buffer for `print_uint`'s integer→decimal conversion. 12 bytes covers a 32-bit unsigned value (max 10 digits) plus headroom — `total` (max 1200, 4 digits) is the largest value ever printed. |

## Register-resident "variables"

These values never live in memory — they are kept in callee-preserved
registers for the lifetime of `_start` (r8, r9, r10, r12-r15 all survive the
`syscall` instruction used by `PRINT`/`print_uint`):

| Register | Width used | Role |
|----------|-----------|------|
| `r8d` | dword | Running `total` (max `12 × 100 = 1200`, needs >8 bits) |
| `r9b` | byte | `highest` mark seen so far |
| `r10b` | byte | `lowest` mark seen so far |
| `r12b` | byte | `cnt_fail` |
| `r13b` | byte | `cnt_pass` |
| `r14b` / `r14d` | byte / dword | `cnt_credit` (stat loop); reused as the print-loop down-counter |
| `r15b` / `r15` | byte / qword | `cnt_distinction` (stat loop); reused as the array base pointer in the print loop |
| `rbx` | dword (`ebx`) | `average`, computed once via `div ecx` and held across the final `PRINT` block |
| `rsi` | qword | Array walk pointer ([MODE-3] register indirect) during the stat loop |

## Pointer / index relationships (addressing mode demo)

```
&marks            = marks + 0
[rsi]             = *rsi                  (MODE-3, rsi = &marks during loop)
[rsi + 4]         = *(rsi + 4) = marks[4] (MODE-4, after lea rsi, [marks])
[marks + rbx]     = marks[rbx]            (MODE-5, rbx = 4 → marks[4])
```

Both `[rsi + 4]` and `[marks + rbx]` (with `rbx = 4`) resolve to the same
effective address, `marks + 4`, which holds `100`.
