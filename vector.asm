; vector.asm - Vector Operations

%include "constants.inc"

section .text
    global normalize_vector, dot_product, reflect_vector, add_vector, subtract_vector, multiply_vector

normalize_vector:
    ; Input/Output: xmm0-xmm2 (vector)
    movsd xmm3, xmm0
    mulsd xmm3, xmm3
    movsd xmm4, xmm1
    mulsd xmm4, xmm4
    addsd xmm3, xmm4
    movsd xmm4, xmm2
    mulsd xmm4, xmm4
    addsd xmm3, xmm4
    sqrtsd xmm3, xmm3
    
    ; Check if vector is not zero-length
    xorpd xmm4, xmm4
    ucomisd xmm3, xmm4
    je .return  ; If length is zero, return original vector
    
    divsd xmm0, xmm3
    divsd xmm1, xmm3
    divsd xmm2, xmm3
.return:
    ret

dot_product:
    ; Input: xmm0-xmm2 (vector1), xmm3-xmm5 (vector2)
    ; Output: xmm0 (dot product)
    mulsd xmm0, xmm3
    mulsd xmm1, xmm4
    mulsd xmm2, xmm5
    addsd xmm0, xmm1
    addsd xmm0, xmm2
    ret

reflect_vector:
    ; Input: xmm0-xmm2 (incident vector), xmm3-xmm5 (normal vector)
    ; Output: xmm0-xmm2 (reflected vector)
    push rax
    sub rsp, 48
    movsd [rsp], xmm0
    movsd [rsp+8], xmm1
    movsd [rsp+16], xmm2
    movsd [rsp+24], xmm3
    movsd [rsp+32], xmm4
    movsd [rsp+40], xmm5
    
    call dot_product
    addsd xmm0, xmm0  ; 2 * dot product
    
    movsd xmm3, [rsp+24]
    movsd xmm4, [rsp+32]
    movsd xmm5, [rsp+40]
    call multiply_vector
    
    movsd xmm3, xmm0
    movsd xmm4, xmm1
    movsd xmm5, xmm2
    movsd xmm0, [rsp]
    movsd xmm1, [rsp+8]
    movsd xmm2, [rsp+16]
    call subtract_vector
    
    add rsp, 48
    pop rax
    ret

add_vector:
    ; Input: xmm0-xmm2 (vector1), xmm3-xmm5 (vector2)
    ; Output: xmm0-xmm2 (result)
    addsd xmm0, xmm3
    addsd xmm1, xmm4
    addsd xmm2, xmm5
    ret

subtract_vector:
    ; Input: xmm0-xmm2 (vector1), xmm3-xmm5 (vector2)
    ; Output: xmm0-xmm2 (result)
    subsd xmm0, xmm3
    subsd xmm1, xmm4
    subsd xmm2, xmm5
    ret

multiply_vector:
    ; Input: xmm0-xmm2 (vector), xmm3 (scalar)
    ; Output: xmm0-xmm2 (result)
    mulsd xmm0, xmm3
    mulsd xmm1, xmm3
    mulsd xmm2, xmm3
    ret
