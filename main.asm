; main.asm - Ray-tracer Main Logic

%include "constants.inc"

extern normalize_vector
extern dot_product
extern reflect_vector
extern add_vector
extern subtract_vector
extern multiply_vector
extern intersect_sphere
extern shade_sphere
extern trace_ray
extern write_bmp_header
extern write_pixel

section .rodata
neg_mask: dq 0x8000000000000000

section .data
; MAX_DEPTH: dq 5

; Sphere data
sphere1 istruc sphere
    at sphere.center, dq -2.0, 0.0, -5.0
    at sphere.radius, dq 1.0
    at sphere.color,  dq 1.0, 0.0, 0.0
iend

sphere2 istruc sphere
    at sphere.center, dq 0.0, 1.0, -7.0
    at sphere.radius, dq 1.5
    at sphere.color,  dq 0.0, 1.0, 0.0
iend

sphere3 istruc sphere
    at sphere.center, dq 2.0, -1.0, -5.0
    at sphere.radius, dq 0.75
    at sphere.color,  dq 0.0, 0.0, 1.0
iend

section .text
global _start

_start:
    call write_bmp_header

    ; Initialize loop counters
    mov r12, HEIGHT - 1  ; Start from bottom row (BMP is bottom-up)

.row_loop:
    xor r13, r13         ; Column counter

.col_loop:
    ; Calculate ray direction
    call calculate_ray_direction

    ; Set ray origin
    xorpd xmm3, xmm3
    xorpd xmm4, xmm4
    xorpd xmm5, xmm5

    ; Trace ray
    xor rdi, rdi         ; depth = 0
    call trace_ray

    ; Write pixel
    call write_pixel

    ; Loop control
    inc r13
    cmp r13, WIDTH
    jl .col_loop

    dec r12
    cmp r12, -1
    jne .row_loop

    ; Exit
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall

calculate_ray_direction:
    ; Input: r13 (x), r12 (y)
    ; Output: xmm0-xmm2 (direction vector)
    cvtsi2sd xmm0, r13
    cvtsi2sd xmm1, r12
    divsd xmm0, [width]
    divsd xmm1, [height]
    subsd xmm0, [half]
    subsd xmm1, [half]
    movq xmm2, [neg_mask]
    xorpd xmm1, xmm2       ; Negate the y-axis
    mulsd xmm0, [aspect_ratio]
    movsd xmm2, [neg_one]
    call normalize_vector
    ret

trace_ray:
    ; Input: xmm0-xmm2 (ray direction), xmm3-xmm5 (ray origin), rdi (depth)
    ; Output: xmm0-xmm2 (color)
    push rdi
    
    ; Check depth
    cmp rdi, MAX_DEPTH    ; Compare depth to MAX_DEPTH
    jge .max_depth_reached

    ; Save ray direction and origin
    sub rsp, 48
    movsd [rsp], xmm0
    movsd [rsp+8], xmm1
    movsd [rsp+16], xmm2
    movsd [rsp+24], xmm3
    movsd [rsp+32], xmm4
    movsd [rsp+40], xmm5

    ; Check sphere intersections
    mov rsi, sphere1
    call intersect_sphere
    jc .hit_sphere1
    mov rsi, sphere2
    call intersect_sphere
    jc .hit_sphere2
    mov rsi, sphere3
    call intersect_sphere
    jc .hit_sphere3

    ; Check ground intersection
    call intersect_ground
    jc .hit_ground

    ; No hit, return sky color
    call calculate_sky_color
    add rsp, 48
    jmp .return

.hit_sphere1:
    mov rsi, sphere1
    jmp .shade_sphere

.hit_sphere2:
    mov rsi, sphere2
    jmp .shade_sphere

.hit_sphere3:
    mov rsi, sphere3

.shade_sphere:
    call shade_sphere
    add rsp, 48
    jmp .return

.hit_ground:
    call shade_ground
    add rsp, 48
    jmp .return

.max_depth_reached:
    movsd xmm0, [black]
    movsd xmm1, [black+8]
    movsd xmm2, [black+16]

.return:
    pop rdi
    ret

intersect_ground:
    ; Input: xmm0-xmm2 (ray direction), xmm3-xmm5 (ray origin)
    ; Output: CF set if intersection, xmm6 (t), xmm7-xmm9 (intersection point)
    movsd xmm10, [epsilon]
    comisd xmm1, xmm10
    jbe .no_intersection

    movsd xmm6, xmm4
    movq xmm7, [neg_mask]    ; Load the negation mask into xmm7
    xorpd xmm6, xmm7         ; Flip the sign bit of xmm6
    divsd xmm6, xmm1         ; Divide xmm6 by the y-component of the ray direction

    movsd xmm7, xmm0         ; Calculate intersection point (x component)
    mulsd xmm7, xmm6
    addsd xmm7, xmm3

    movsd xmm8, xmm1         ; Calculate intersection point (y component)
    mulsd xmm8, xmm6
    addsd xmm8, xmm4

    movsd xmm9, xmm2         ; Calculate intersection point (z component)
    mulsd xmm9, xmm6
    addsd xmm9, xmm5

    stc                      ; Set carry flag to indicate intersection
    ret

.no_intersection:
    clc                      ; Clear carry flag to indicate no intersection
    ret

shade_ground:
    ; Your shading logic here
    movsd xmm0, [black]
    movsd xmm1, [black+8]
    movsd xmm2, [black+16]
    ret

calculate_sky_color:
    ; Sky color calculation
    movsd xmm3, xmm1
    addsd xmm3, [one]
    mulsd xmm3, [half]
    movsd xmm4, [one]
    subsd xmm4, xmm3
    
    movsd xmm0, [sky_color1]
    movsd xmm1, [sky_color1+8]
    movsd xmm2, [sky_color1+16]
    mulsd xmm0, xmm4
    mulsd xmm1, xmm4
    mulsd xmm2, xmm4
    
    movsd xmm5, [sky_color2]
    movsd xmm6, [sky_color2+8]
    movsd xmm7, [sky_color2+16]
    mulsd xmm5, xmm3
    mulsd xmm6, xmm3
    mulsd xmm7, xmm3
    
    addsd xmm0, xmm5
    addsd xmm1, xmm6
    addsd xmm2, xmm7
    ret

