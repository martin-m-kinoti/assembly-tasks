# Task 2: Arithmetic & Logic Calculator

Interactive IA-32 (i386) NASM program. Reads two digits from the keyboard, then lets the user run arithmetic and logical operations from a menu while displaying the CPU flags (CF, ZF, SF, OF) after each instruction.

## Objectives

1. Use `ADD`, `SUB`, `INC`, `DEC`, `MUL`, `IMUL`, `DIV`, `IDIV` instructions.
2. Apply `AND`, `OR`, `XOR`, `NOT`, `TEST` for bit manipulation.
3. Inspect and explain carry, zero, sign, and overflow flags.
4. Convert ASCII input digits into numeric values and display results.

## Files

| File | Description |
|------|-------------|
| `calc.asm` | Calculator with menu-driven operations and flag display |
| `build.sh` | Assembles both a plain and a GDB-debug build |

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
# plain build
nasm -f elf32 calc.asm -o calc.o
ld -m elf_i386 calc.o -o calc

# debug build (includes DWARF symbols for GDB)
nasm -f elf32 -g -F dwarf calc.asm -o calc_dbg.o
ld -m elf_i386 calc_dbg.o -o calc_dbg
```

### Run

```bash
./calc
```

Example session:

```
=== Arithmetic & Logic Calculator ===
Enter first number  (0-9): 7
Enter second number (0-9): 3

  1. ADD    2. SUB    3. INC(a)  4. DEC(a)
  5. MUL    6. IMUL   7. DIV     8. IDIV
  9. AND    a. OR     b. XOR     c. NOT(a)
  d. TEST   q. Quit
Choice: 1

Op     : ADD
Result : 10
Flags  : CF=0 ZF=0 SF=0 OF=0
```

### Validation

- Non-digit input at the number prompts → `[!] Enter a single digit 0-9.`
- Invalid menu character → `[!] Invalid choice.`
- Division by zero (choices `7` or `8` with second number = 0) → `[!] Division by zero.`

## How flags are captured

Immediately after each operation the program executes `pushfd` / `pop esi` to snapshot EFLAGS before any other instruction can change them. `show_flags` then reads individual bits with the `bt` instruction:

| Flag | EFLAGS bit | Set when… |
|------|-----------|-----------|
| CF | 0 | Unsigned carry/borrow out of the MSB; or MUL/IMUL result does not fit in the lower half |
| ZF | 6 | Result is exactly zero |
| SF | 7 | Result MSB is 1 (negative in two's complement) |
| OF | 11 | Signed overflow — result exceeds the signed range of the destination |

**Notes:**
- `INC` / `DEC` deliberately do **not** modify CF (use `ADD 1` / `SUB 1` if you need CF updated).
- `NOT` does **not** modify any flags.
- `TEST` performs `a AND b` internally to set ZF/SF/PF and clears CF/OF, but discards the result — only the flags matter.

## GDB flag inspection

```bash
gdb ./calc_dbg
```

### Useful GDB commands

```gdb
# break at the ADD handler, then run
break do_add
run

# step one machine instruction at a time
stepi

# view all registers including EFLAGS
info registers

# read individual flags from EFLAGS
print $eflags & 1          # CF
print ($eflags >> 6) & 1   # ZF
print ($eflags >> 7) & 1   # SF
print ($eflags >> 11) & 1  # OF

# display EFLAGS automatically after every step
display $eflags

# inspect operand values
print /d $eax
print /d $ebx
print /x $eax              # hex view
```

### Example GDB walkthrough

```
(gdb) break do_add
Breakpoint 1 at 0x401...
(gdb) run
Enter first number  (0-9): 9
Enter second number (0-9): 9
Choice: 1
Breakpoint 1, do_add ()
(gdb) stepi 4              # step past PRINT calls to the add al,bl
(gdb) info registers eflags
eflags  0x202  [ IF ]      # CF=0 ZF=0 SF=0 OF=0  (9+9=18, fits in a byte)
(gdb) stepi                # execute  add al, bl
(gdb) info registers eflags eax
eax     0x12               # 18
eflags  0x202  [ IF ]      # flags unchanged — no overflow, no carry
```

To see CF set, try `SUB` with a larger second number (e.g., 2 − 9):

```
(gdb) break do_sub
(gdb) continue
Choice: 2          # SUB, num1=2, num2=9
(gdb) stepi ...
(gdb) info registers eflags
eflags  0x293  [ CF AF SF IF ]   # CF=1 SF=1 (borrow occurred, result negative)
```

## Flag analysis

See [flagAnalysis.md](flagAnalysis.md) for a worked-example breakdown of CF, ZF, SF, and OF across every operation.

## Screenshots

### calc

![calc output](screenshots/Screenshot%202026-06-10%20121344.png)
