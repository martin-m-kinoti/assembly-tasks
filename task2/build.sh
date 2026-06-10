#!/bin/sh
# build.sh – Assembles and links calc.asm
# Run: chmod +x build.sh && ./build.sh

set -e

echo ">>> Building calc.asm ..."
nasm -f elf64 calc.asm -o calc.o
ld calc.o -o calc
echo "    Done. Run with: ./calc"

echo ""
echo ">>> Debug build (for GDB) ..."
nasm -f elf64 -g -F dwarf calc.asm -o calc_dbg.o
ld calc_dbg.o -o calc_dbg
echo "    Done. Debug with: gdb ./calc_dbg"
