; Ray-tracer in x64 Assembly (NASM) for Linux
; Filename: main.asm
; Outputs a BMP image to stdout

section .data
    ; BMP Header
    bmp_header:
        db 0x42, 0x4D           ; BM
        dd 54 + 800*600*3       ; File size
        dd 0                    ; Reserved
        dd 54                   ; Offset to pixel data
        dd 40                   ; DIB header size
        dd 800                  ; Width
        dd 600                  ; Height
        dw 1                    ; Planes
        dw 24                   ; Bits per pixel
        dd 0                    ; Compression
        dd 800*600*3            ; Image size
        dd 2835                 ; X pixels per meter
        dd 2835                 ; Y pixels per meter
        dd 0                    ; Colors in color table
        dd 0                    ; Important color count
    bmp_header_len equ $ - bmp_header

    width dq 800
    height dq 600

section .bss
    pixel resb 3

section .text
    global _start

_start:
    ; Write BMP header
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, bmp_header
    mov rdx, bmp_header_len
    syscall

    ; Initialize loop counters
    mov r12, 599        ; Start from bottom row (BMP is bottom-up)

.row_loop:
    mov r13, 0          ; Column counter

.col_loop:
    ; Simple color based on position
    mov byte [pixel], r13b      ; B increases from left to right
    mov byte [pixel+1], r12b    ; G increases from bottom to top
    mov byte [pixel+2], 128     ; R is constant

    ; Write pixel to stdout
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, pixel
    mov rdx, 3
    syscall

    ; Loop control
    inc r13
    cmp r13, 800
    jl .col_loop

    dec r12
    cmp r12, -1
    jne .row_loop

    ; Exit
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall
