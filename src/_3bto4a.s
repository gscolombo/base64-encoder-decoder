BITS 64

section .data

alphabet: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

section .text
global _3bto4a

_3bto4a:
    ; rdi := 3 Bytes de entrada
    ; rsi := 4 bytes de saída
    ; rdx := Quantidade de bytes que resta converter

    ; Salva o conteúdo do registrador RBX e armazena o endereço da tabela de conversão
    push rbx
    mov bx, alphabet

    mov bx, db

    ; Armazena o conteúdo de RDX em R8
    mov r8, rdx

    movzx ecx, byte [rdi]       ; ecx := 0x000000[byte0]
    shl ecx, 16                 ; ecx := 0x00[byte0]0000
    movzx edx, byte [rdi + 1]   ; edx := 0x000000[byte1]
    shl edx, 8                  ; edx := 0x0000[byte1]00
    or ecx, edx                 ; ecx := 0x00[byte0][byte1]00
    movzx edx, byte [rdi + 2]     ; edx := 0x000000[byte2]
    or  ecx, edx                ; ecx := 0x00[byte0][byte1][byte2]

    ; ecx := 0x[byte0][byte1][byte2]00

    ; Primeiro caractere
    mov eax, ecx
    shr eax, 18         ; 16 bits dos bytes 1 e 2 mais 2 bits (LSB) do byte 0
    xlatb           
    mov [rsi], al

    ; Segundo caractere
    mov eax, ecx
    shr eax, 12         ; 8 bits do bytes 2 mais 4 bits (LSB) do byte 1
    and eax, 0x3F       ; Máscara de bits para filtrar os 6 primeiros bits
    xlatb
    mov [rsi + 1], al

    ; Verifica se falta somente um byte para conversão
    cmp r8, 1          
    je .pad2

    ; Terceiro caractere
    mov eax, ecx
    shr eax, 6
    and eax, 0x3F       ; Máscara de bits para filtrar os 6 primeiros bits
    xlatb
    mov [rsi + 2], al


    ; Verifica se falta somente dois bytes para conversão
    cmp r8, 2          
    je .pad1

    mov eax, ecx
    and eax, 0x3F       ; Máscara de bits para filtrar os 6 primeiros bits
    xlatb
    mov [rsi + 3], al
    jmp .end

    .pad2:
        mov byte [rsi + 2], '='
    .pad1:
        mov byte [rsi + 3], '='

    .end:
        pop rbx
        ret
    



    

