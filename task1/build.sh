#!/bin/sh
# build.sh - Assembles and links both programs
# Run: chmod +x build.sh && ./build.sh

set -e  # stop on any error

echo ">>> Building hello.asm ..."
nasm -f elf64 hello.asm -o hello.o
ld hello.o -o hello
echo "    Done. Run with: ./hello"

echo ""
echo ">>> Building datatypes.asm ..."
nasm -f elf64 datatypes.asm -o datatypes.o
ld data_rep.o -o data_rep
echo "    Done. Run with: ./datatypes"

echo ""
echo ">>> Running hello:"
./hello

echo ""
echo ">>> Running datatypes:"
./datatypes