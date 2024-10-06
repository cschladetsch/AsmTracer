#!/bin/bash

# Script name: r
# Purpose: Build the ray-tracer project and run it, saving output to the current directory

# Ensure the script exits if any command fails
set -e

echo "Building the ray-tracer..."
nasm.exe -f elf64 main.asm
ld main.o -o raytracer

echo "Running the ray-tracer..."
./raytracer > output.bmp

echo "Done! Output saved as output.bmp in the current directory."
