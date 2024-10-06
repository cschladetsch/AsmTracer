; Debug version: Ray-tracer in x64 Assembly (NASM) for Linux
; Outputs a BMP image with two spheres to stdout

section .data
    ; BMP Header (unchanged)
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

    width dq 800.0
    height dq 600.0

    sphere1_center dq -1.0, 0.0, -3.0
    sphere1_radius dq 0.5
    sphere1_color db 0, 0, 255  ; Blue (BGR in BMP)

    sphere2_center dq 1.0, 0.0, -3.0
    sphere2_radius dq 0.5
    sphere2_color db 255, 0, 0  ; Red (BGR in BMP)

    background_color db 100, 100, 100  ; Light gray

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
    ; Calculate ray direction
    cvtsi2sd xmm0, r13
    cvtsi2sd xmm1, r12
    divsd xmm0, qword [width]
    divsd xmm1, qword [height]
    subsd xmm0, qword [half]
    subsd xmm1, qword [half]
    mulsd xmm0, qword [aspect_ratio]
    movsd xmm2, qword [neg_one]

    ; Normalize ray direction
    call normalize_vector

    ; Debug: Color based on ray direction
    cvtsd2si eax, xmm0
    add eax, 128
    mov byte [pixel], al   ; B
    cvtsd2si eax, xmm1
    add eax, 128
    mov byte [pixel+1], al ; G
    cvtsd2si eax, xmm2
    add eax, 128
    mov byte [pixel+2], al ; R

    ; Uncomment the following lines to enable sphere intersection
    ; Check intersection with sphere 1
    ; mov rsi, sphere1_center
    ; movsd xmm3, [sphere1_radius]
    ; call intersect_sphere
    
    ; If hit, color pixel and continue to next
    ; jnc .check_sphere2
    ; mov rsi, sphere1_color
    ; jmp .color_pixel

; .check_sphere2:
    ; Check intersection with sphere 2
    ; mov rsi, sphere2_center
    ; movsd xmm3, [sphere2_radius]
    ; call intersect_sphere
    
    ; If hit, color pixel, otherwise keep debug color
    ; jnc .write_pixel
    ; mov rsi, sphere2_color

; .color_pixel:
    ; mov al, [rsi]
    ; mov [pixel], al
    ; mov al, [rsi+1]
    ; mov [pixel+1], al
    ; mov al, [rsi+2]
    ; mov [pixel+2], al

.write_pixel:
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

; Helper functions (unchanged)
normalize_vector:
    ; Input: xmm0, xmm1, xmm2 (vector components)
    ; Output: normalized vector in xmm0, xmm1, xmm2
    movsd xmm3, xmm0
    mulsd xmm3, xmm3
    movsd xmm4, xmm1
    mulsd xmm4, xmm4
    addsd xmm3, xmm4
    movsd xmm4, xmm2
    mulsd xmm4, xmm4
    addsd xmm3, xmm4
    sqrtsd xmm3, xmm3
    divsd xmm0, xmm3
    divsd xmm1, xmm3
    divsd xmm2, xmm3
    ret

intersect_sphere:
    ; Input: xmm0, xmm1, xmm2 (ray direction), rsi (sphere center), xmm3 (sphere radius)
    ; Output: CF set if intersection, clear if no intersection
    sub rsp, 24
    movsd [rsp], xmm0
    movsd [rsp+8], xmm1
    movsd [rsp+16], xmm2

    ; Calculate oc (origin - center)
    movsd xmm4, [rsi]
    subsd xmm4, [rsp]
    movsd xmm5, [rsi+8]
    subsd xmm5, [rsp+8]
    movsd xmm6, [rsi+16]
    subsd xmm6, [rsp+16]

    ; Calculate b = 2 * dot(oc, ray_direction)
    mulsd xmm4, xmm0
    mulsd xmm5, xmm1
    mulsd xmm6, xmm2
    addsd xmm4, xmm5
    addsd xmm4, xmm6
    addsd xmm4, xmm4    ; b = 2 * dot product

    ; Calculate c = dot(oc, oc) - radius^2
    movsd xmm5, [rsi]
    subsd xmm5, [rsp]
    mulsd xmm5, xmm5
    movsd xmm6, [rsi+8]
    subsd xmm6, [rsp+8]
    mulsd xmm6, xmm6
    addsd xmm5, xmm6
    movsd xmm6, [rsi+16]
    subsd xmm6, [rsp+16]
    mulsd xmm6, xmm6
    addsd xmm5, xmm6
    movsd xmm6, xmm3
    mulsd xmm6, xmm6
    subsd xmm5, xmm6    ; c = dot(oc, oc) - radius^2

    ; Calculate discriminant = b^2 - 4c
    movsd xmm6, xmm4
    mulsd xmm6, xmm6
    movsd xmm7, xmm5
    addsd xmm7, xmm7
    addsd xmm7, xmm7
    subsd xmm6, xmm7

    ; Check if discriminant is positive
    xorpd xmm7, xmm7
    comisd xmm6, xmm7
    jb .no_intersection

    ; We have an intersection
    add rsp, 24
    stc
    ret

.no_intersection:
    add rsp, 24
    clc
    ret

section .rodata
    align 8
    half dq 0.5
    neg_one dq -1.0
    aspect_ratio dq 1.3333333333333333  ; 800 / 600
