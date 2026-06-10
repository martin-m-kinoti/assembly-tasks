# Task 3 — Mark Statistics

x86-64 NASM program that processes a twelve-element byte array of marks and prints total, average, highest, lowest, and grade-band counts. Demonstrates five addressing modes, explicit byte/word/dword size annotations, and loop-based array traversal.

## Objectives

1. Use `MOV` and other data-movement instructions correctly.
2. Apply five addressing modes to access scalar variables and arrays.
3. Manipulate bytes, words, and doublewords while avoiding size-mismatch errors.
4. Relate assembly memory access to high-level array indexing.

## Files

| File | Description |
|------|-------------|
| `marks.asm` | Main program — statistics computation and display |
| `build.sh` | Plain and GDB-debug builds |

## Setup

```bash
chmod +x build.sh
```

## Commands

### Build

```bash
./build.sh
```

Or manually:

```bash
nasm -f elf64 marks.asm -o marks.o && ld marks.o -o marks
```

### Run

```bash
./marks
```

Expected output:

```
=== Mark Statistics ===
Marks      : 45, 72, 38, 91, 100, 67, 40, 39, 0, 55, 70, 69
Total      : 686
Average    : 57
Highest    : 100
Lowest     : 0

--- Grade Bands ---
Distinction (70-100) : 4
Credit      (60-69)  : 2
Pass        (40-59)  : 3
Fail        ( 0-39)  : 3
```

---

## Addressing Modes

Five addressing modes are used and annotated with `[MODE-n]` in `marks.asm`.

| Mode | Syntax | Example in code | C equivalent |
|------|--------|-----------------|--------------|
| **1. Immediate** | `mov reg, const` | `mov ecx, MCOUNT` | `int n = 12;` |
| **2. Direct (label)** | `[symbol]` | `movzx r9d, byte [marks]` | `v = marks[0];` |
| **3. Register indirect** | `[reg]` | `movzx eax, byte [rsi]` | `v = *ptr;` |
| **4. Base+displacement** | `[reg + n]` | `movzx eax, byte [rsi + 4]` | `v = ptr[4];` |
| **5. Base+index** | `[label + reg]` | `movzx eax, byte [marks + rbx]` | `v = marks[idx];` |

### Where each mode appears

- **MODE-1**: `mov ecx, MCOUNT` loads the compile-time constant 12 into a register. Also used for threshold comparisons (`cmp al, DIST_MIN`).
- **MODE-2**: `byte [marks]` seeds the initial highest/lowest with `marks[0]` using the symbol's absolute address — no register needed.
- **MODE-3**: `byte [rsi]` inside both loops. `rsi` is advanced with `inc rsi` each iteration, mirroring `ptr++` in C.
- **MODE-4**: `byte [rsi + 4]` accesses an element at a fixed offset from the current pointer — shown in the demonstration section after the stat loop.
- **MODE-5**: `byte [marks + rbx]` uses the label as the array base and `rbx` as a variable index — the closest analogue to C's `marks[i]`.

---

## Data Sizes and Avoiding Mismatch Errors

| Data | Type | Register | Reason |
|------|------|----------|--------|
| Individual mark | `db` (byte) | `al` / `r9b` | Values 0–100 fit in 8 bits |
| Array load | `movzx eax, byte [rsi]` | `eax` (dword) | Zero-extend to avoid garbage in upper bits |
| Running total | `r8d` (dword) | 32-bit | Max total = 12 × 100 = 1200; overflows a byte |
| Average | `eax` after `div ecx` | 32-bit | Result of dword division |
| Grade counts | `r12b`–`r15b` (byte) | 8-bit | Max count = 12, fits in a byte |

Key rule demonstrated: always match the register size to the data size. Loading a `byte` variable with `mov eax, [rsi]` (no size specifier) would assemble as a dword load and read 3 extra bytes of garbage. `movzx eax, byte [rsi]` is explicit and safe.

---

## Memory Map

Full breakdown of `.data`/`.bss` offsets, the `marks` array, and the
register-resident "variables" is in [memory_map.md](memory_map.md).

---

## Test Cases — Boundary Marks

All six boundary values (`0`, `39`, `40`, `69`, `70`, `100`) are included in
the array so each classification edge is exercised in a single run. See
[test_case.md](test_case.md) for the full boundary matrix, expected output,
and GDB verification steps.

### Verifying boundary behaviour with GDB

```bash
gdb ./marks_dbg
```

```gdb
break .classify          # stop before each classification branch
run

# after the breakpoint fires, check which branch is taken:
info registers al        # current mark
stepi                    # step through the cmp / jge chain
info registers eflags    # ZF=1 means equal; CF=0 means ≥ (unsigned)
```

To inspect the array directly:

```gdb
# print all 12 marks as decimal bytes
x/12db &marks

# print marks[4] (should be 100)
x/db marks+4

# confirm r9b = highest, r10b = lowest after the loop
break .stat_loop+last_instruction
continue
info registers r9 r10
```

---

## Screenshots

### marks

![marks output](screenshots/Screenshot%202026-06-10%20124751.png)
