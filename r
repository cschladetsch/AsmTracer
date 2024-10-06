#!/bin/bash

# build.sh - Ray-tracer Build Script

# Ensure the script exits if any command fails
set -e

# Print commands before executing them
set -x

# Assemble all .asm files
nasm.exe -f elf64 main.asm
nasm.exe -f elf64 vector.asm
nasm.exe -f elf64 sphere.asm
nasm.exe -f elf64 output.asm

# Link the object files
ld -o raytracer main.o vector.o sphere.o output.o

# Clean up object files
rm *.o

# Make the raytracer executable
chmod +x raytracer

echo "Build complete. Run ./raytracer > output.bmp to generate the image."
