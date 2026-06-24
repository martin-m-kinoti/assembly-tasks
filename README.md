# assembly-tasks

x86-64 NASM assembly programs written for a computer organisation/architecture unit. All programs target Linux x86-64 (or WSL) and are built with NASM + GNU `ld`.

## Tasks

### [Task 1: Hello World & Data Representation](task1/)

Two introductory programs:
- `hello.asm` — prints a greeting using a raw Linux `write` syscall.
- `data_rep.asm` — demonstrates how ASCII characters, signed/unsigned integers, and other data types are stored and displayed in assembly.

### [Task 2: Arithmetic & Logic Calculator](task2/)

Menu-driven calculator that reads two single digits from the keyboard and supports `ADD`, `SUB`, `INC`, `DEC`, `MUL`, `IMUL`, `DIV`, `IDIV`, `AND`, `OR`, `XOR`, `NOT`, and `TEST`. After each operation the program prints the result along with the CPU flags (CF, ZF, SF, OF) captured via `pushfq`. Includes input validation and division-by-zero handling. A companion GDB debug build and [flagAnalysis.md](task2/flagAnalysis.md) walk through flag behaviour for every operation.

### [Task 3: Mark Statistics](task3/)

Processes a twelve-element byte array of student marks and prints total, average, highest, lowest, and grade-band counts (Distinction / Credit / Pass / Fail). Demonstrates five addressing modes (immediate, direct, register-indirect, base+displacement, base+index), explicit operand-size annotations with `movzx`, and loop-based array traversal. Supplementary files cover the [memory map](task3/memory_map.md) and [boundary test cases](task3/test_case.md).
