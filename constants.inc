
%define WIDTH 800
%define HEIGHT 600
%define MAX_DEPTH 10

section .data
    width dq WIDTH
    height dq HEIGHT
    aspect_ratio dq WIDTH / HEIGHT

    epsilon dq 0.0001
    checker_size dq 1.0

    ; Colors
    white dq 1.0, 1.0, 1.0
    black dq 0.0, 0.0, 0.0
    sky_color1 dq 1.0, 1.0, 1.0  ; White
    sky_color2 dq 0.5, 0.7, 1.0  ; Light blue

    ; Light direction (normalized)
    light_dir dq 0.5773502691896258, 0.5773502691896258, -0.5773502691896258

section .rodata
    align 8
    half dq 0.5
    one dq 1.0
    neg_one dq -1.0
    two dq 2.0

struc sphere
    .center: resq 3
    .radius: resq 1
    .color:  resq 3
endstruc

