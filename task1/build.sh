#!/bin/sh
# build.sh - Assembles and links both programs
# Run: chmod +x build.sh && ./build.sh

set -e  # stop on any error

echo ">>> Building hello.asm ..."
nasm -f elf64 hello.asm -o hello.o
ld hello.o -o hello
echo "    Done. Run with: ./hello"

echo ""
echo ">>> Building calc.asm ..."
nasm -f elf64 calc.asm -o calc.o
ld calc.o -o calc
echo "    Done. Run with: ./calc"

echo ""
echo ">>> Running hello:"
./hello

echo ""
echo ">>> Running calc:"
./calc