
; sphere.asm - Sphere Intersection and Shading

%include "constants.inc"

extern dot_product, reflect_vector, normalize_vector, trace_ray  ; Ensure trace_ray is properly declared
extern add_vector, subtract_vector, multiply_vector

section .text
    global intersect_sphere, shade_sphere

; Definitions of intersect_sphere and shade_sphere go here...

intersect_sphere:
    ; Input: xmm0-xmm2 (ray direction), xmm3-xmm5 (ray origin), rsi (sphere data)
    ; Output: CF set if intersection, xmm6 (t), xmm7-xmm9 (intersection point)
    push rax
    sub rsp, 48
    movsd [rsp], xmm0
    movsd [rsp+8], xmm1
    movsd [rsp+16], xmm2
    movsd [rsp+24], xmm3
    movsd [rsp+32], xmm4
    movsd [rsp+40], xmm5
    
    ; Calculate oc (origin - center)
    movsd xmm0, xmm3
    movsd xmm1, xmm4
    movsd xmm2, xmm5
    movsd xmm3, [rsi + sphere.center]
    movsd xmm4, [rsi + sphere.center + 8]
    movsd xmm5, [rsi + sphere.center + 16]
    call subtract_vector
    
    ; Calculate b = dot(oc, ray_direction)
    movsd xmm3, [rsp]
    movsd xmm4, [rsp+8]
    movsd xmm5, [rsp+16]
    call dot_product
    movsd xmm6, xmm0  ; b
    
    ; Calculate c = dot(oc, oc) - radius^2
    movsd xmm3, xmm0
    movsd xmm4, xmm1
    movsd xmm5, xmm2
    call dot_product
    movsd xmm10, [rsi + sphere.radius]
    mulsd xmm10, xmm10
    subsd xmm0, xmm10  ; c
    
    ; Calculate discriminant = b^2 - c
    movsd xmm10, xmm6
    mulsd xmm10, xmm10
    subsd xmm10, xmm0  ; discriminant
    
    ; Check if discriminant is positive
    xorpd xmm11, xmm11
    comisd xmm10, xmm11
    jb .no_intersection
    
    ; Calculate t = -b - sqrt(discriminant)
    sqrtsd xmm11, xmm10
    movsd xmm6, xmm11
    addsd xmm6, [rsp+48]  ; -b (note: b was negated earlier)
    
    ; Check if t > epsilon
    movsd xmm11, [epsilon]
    comisd xmm6, xmm11
    jbe .no_intersection
    
    ; Calculate intersection point
    movsd xmm0, [rsp]
    movsd xmm1, [rsp+8]
    movsd xmm2, [rsp+16]
    movsd xmm3, xmm6
    call multiply_vector
    movsd xmm3, [rsp+24]
    movsd xmm4, [rsp+32]
    movsd xmm5, [rsp+40]
    call add_vector
    movsd xmm7, xmm0
    movsd xmm8, xmm1
    movsd xmm9, xmm2
    
    add rsp, 48
    pop rax
    stc
    ret

.no_intersection:
    add rsp, 48
    pop rax
    clc
    ret

shade_sphere:
    ; Input: xmm6 (t), xmm7-xmm9 (intersection point), rsi (sphere data)
    ; Output: xmm0-xmm2 (color)
    push rax
    push rdi
    sub rsp, 80
    movsd [rsp], xmm6
    movsd [rsp+8], xmm7
    movsd [rsp+16], xmm8
    movsd [rsp+24], xmm9
    
    ; Calculate normal
    movsd xmm0, xmm7
    movsd xmm1, xmm8
    movsd xmm2, xmm9
    movsd xmm3, [rsi + sphere.center]
    movsd xmm4, [rsi + sphere.center + 8]
    movsd xmm5, [rsi + sphere.center + 16]
    call subtract_vector
    call normalize_vector
    movsd [rsp+32], xmm0
    movsd [rsp+40], xmm1
    movsd [rsp+48], xmm2
    
    ; Calculate lighting (Lambertian reflection)
    movsd xmm3, [light_dir]
    movsd xmm4, [light_dir+8]
    movsd xmm5, [light_dir+16]
    call dot_product
    xorpd xmm1, xmm1
    maxsd xmm0, xmm1
    movsd [rsp+56], xmm0  ; diffuse
    
    ; Base color
    movsd xmm0, [rsi + sphere.color]
    movsd xmm1, [rsi + sphere.color + 8]
    movsd xmm2, [rsi + sphere.color + 16]
    
    ; Apply diffuse lighting
    movsd xmm3, [rsp+56]
    call multiply_vector
    movsd [rsp+64], xmm0
    movsd [rsp+72], xmm1
    movsd [rsp+80], xmm2
    
    ; Calculate reflection
    movsd xmm0, [rsp+32]
    movsd xmm1, [rsp+40]
    movsd xmm2, [rsp+48]
    movsd xmm3, [light_dir]
    movsd xmm4, [light_dir+8]
    movsd xmm5, [light_dir+16]
    call reflect_vector
    
    ; Recursive ray trace for reflection
    movsd xmm3, [rsp+8]
    movsd xmm4, [rsp+16]
    movsd xmm5, [rsp+24]
    mov rdi, [rsp+88]  ; Retrieve current depth
    inc rdi
    call trace_ray
    
    ; Blend reflection (50% reflection for simplicity)
    movsd xmm3, [half]
    call multiply_vector
    movsd xmm3, [rsp+64]
    movsd xmm4, [rsp+72]
    movsd xmm5, [rsp+80]
    call add_vector
    
    add rsp, 80
    pop rdi
    pop rax
    ret
