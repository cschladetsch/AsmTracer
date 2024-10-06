#!/bin/sh

nasm -f elf64 -g -F dwarf -o main.o main.asm
nasm -f elf64 -g -F dwarf -o vector.o vector.asm
nasm -f elf64 -g -F dwarf -o sphere.o sphere.asm
nasm -f elf64 -g -F dwarf -o output.o output.asm
ld -o raytracer main.o vector.o sphere.o output.o


