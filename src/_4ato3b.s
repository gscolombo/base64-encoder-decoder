BITS 64

section .data
    ; Tabela de decodificação Base64 (256 bytes)
    ; Mapeia caractere ASCII -> valor 0-63
    ; Valores inválidos são marcados com 0xFF
    decode_table:
        times 43 db 0xFF        ; 0-42: caracteres inválidos
        db 62                    ; 43 '+' = 62
        db 0xFF                  ; 44 ','
        db 0xFF                  ; 45 '-'
        db 0xFF                  ; 46 '.'
        db 63                    ; 47 '/' = 63
        db 52, 53, 54, 55, 56, 57, 58, 59, 60, 61  ; 48-57: '0'-'9' = 52-61
        times 7 db 0xFF         ; 58-64: ':' a '@'
        db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9          ; 65-74: 'A'-'J' = 0-9
        db 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 ; 75-84: 'K'-'T' = 10-19
        db 20, 21, 22, 23, 24, 25                ; 85-90: 'U'-'Z' = 20-25
        times 6 db 0xFF         ; 91-96: '[' a '`'
        db 26, 27, 28, 29, 30, 31, 32, 33, 34, 35 ; 97-106: 'a'-'j' = 26-35
        db 36, 37, 38, 39, 40, 41, 42, 43, 44, 45 ; 107-116: 'k'-'t' = 36-45
        db 46, 47, 48, 49, 50, 51                ; 117-122: 'u'-'z' = 46-51
        times 133 db 0xFF       ; 123-255: caracteres inválidos

section .text
global _4ato3b

; =============================================================================
; Decodifica 4 caracteres Base64 para 3 bytes
;
; Entrada "QUJD" (16 20 9 3):
;   Q=16=010000  U=20=010100  J=9=001001  D=3=000011
;   
; Reorganiza em 3 bytes:
;   010000|01 0100|0010 01|000011
;   01000001 01000010 01000011
;      65       66       67
;      'A'      'B'      'C'
; =============================================================================

_4ato3b:
    push rbx
    lea rbx, [rel decode_table]
    
    ; === Decodifica C0 ===
    movzx eax, byte [rdi]
    cmp al, '='
    je .invalid
    movzx eax, al
    movzx r8d, byte [rbx + rax]
    cmp r8b, 0xFF
    je .invalid
    ; R8 = valor de C0 (6 bits)
    
    ; === Decodifica C1 ===
    movzx eax, byte [rdi + 1]
    cmp al, '='
    je .invalid
    movzx eax, al
    movzx r9d, byte [rbx + rax]
    cmp r9b, 0xFF
    je .invalid
    ; R9 = valor de C1 (6 bits)
    
    ; === Byte 0 = C0 (6 bits) + 2 bits superiores de C1 ===
    mov eax, r8d
    shl eax, 2                  ; C0 << 2
    mov edx, r9d
    shr edx, 4                  ; C1 >> 4 (pega 2 bits superiores)
    or eax, edx
    mov [rsi], al               ; Grava byte 0
    
    ; === Decodifica C2 ===
    movzx eax, byte [rdi + 2]
    cmp al, '='
    je .one_byte                ; Apenas 1 byte de saída
    
    movzx eax, al
    movzx r10d, byte [rbx + rax]
    cmp r10b, 0xFF
    je .invalid
    ; R10 = valor de C2 (6 bits)
    
    ; === Byte 1 = 4 bits inferiores de C1 + 4 bits superiores de C2 ===
    mov eax, r9d
    and eax, 0x0F               ; Pega 4 bits inferiores de C1
    shl eax, 4
    mov edx, r10d
    shr edx, 2                  ; Pega 4 bits superiores de C2
    or eax, edx
    mov [rsi + 1], al           ; Grava byte 1
    
    ; === Decodifica C3 ===
    movzx eax, byte [rdi + 3]
    cmp al, '='
    je .two_bytes               ; Apenas 2 bytes de saída
    
    movzx eax, al
    movzx r11d, byte [rbx + rax]
    cmp r11b, 0xFF
    je .invalid
    ; R11 = valor de C3 (6 bits)
    
    ; === Byte 2 = 2 bits inferiores de C2 + C3 (6 bits) ===
    mov eax, r10d
    and eax, 0x03               ; Pega 2 bits inferiores de C2
    shl eax, 6
    or eax, r11d                ; Adiciona C3 completo
    mov [rsi + 2], al           ; Grava byte 2
    
    mov rax, 3                  ; Retorna 3 bytes
    jmp .end

.one_byte:
    mov rax, 1
    jmp .end

.two_bytes:
    mov rax, 2
    jmp .end

.invalid:
    xor eax, eax

.end:
    pop rbx
    ret