#!/bin/sh
# build.sh – Assembles and links marks.asm
# Run: chmod +x build.sh && ./build.sh

set -e

echo ">>> Building marks.asm ..."
nasm -f elf64 marks.asm -o marks.o
ld marks.o -o marks
echo "    Done. Run with: ./marks"

echo ""
echo ">>> Debug build (DWARF symbols for GDB) ..."
nasm -f elf64 -g -F dwarf marks.asm -o marks_dbg.o
ld marks_dbg.o -o marks_dbg
echo "    Done. Debug with: gdb ./marks_dbg"
