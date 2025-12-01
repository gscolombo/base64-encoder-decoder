BITS 64

section .data

alphabet: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


section .text
global _3bto4a

_3bto4a:
    ; rdi := 3 Bytes de entrada
    ; rsi := 4 bytes de saída
    ; rdx := Quantidade de bytes que resta converter (1, 2 ou 3)

    ; Salva o conteúdo do registrador RBX e armazena o endereço da tabela de conversão
    push rbx
    lea rbx, [rel alphabet] ; Carrega endereço relativo da tabela de caracteres do Base64

    ; Armazena o conteúdo de RDX em R8
    mov r8, rdx

    ; Inicializa ECX com zero
    xor ecx, ecx

    ; Carrega o primeiro byte (sempre presente)
    movzx eax, byte [rdi]       ; eax := 0x000000[byte0]
    shl eax, 16                 ; eax := 0x00[byte0]0000
    or ecx, eax                 ; ecx := 0x00[byte0]0000

    ; Verifica se há segundo byte
    cmp r8, 1
    jle .process                ; Se só tem 1 byte, processa

    ; Carrega o segundo byte
    movzx eax, byte [rdi + 1]   ; eax := 0x000000[byte1]
    shl eax, 8                  ; eax := 0x0000[byte1]00
    or ecx, eax                 ; ecx := 0x00[byte0][byte1]00

    ; Verifica se há terceiro byte
    cmp r8, 2
    jle .process                ; Se só tem 2 bytes, processa

    ; Carrega o terceiro byte
    movzx eax, byte [rdi + 2]   ; eax := 0x000000[byte2]
    or ecx, eax                 ; ecx := 0x00[byte0][byte1][byte2]

.process:
    ; ecx agora contém os bytes alinhados corretamente

    ; Primeiro caractere (sempre presente)
    mov eax, ecx
    shr eax, 18                 ; Extrai os 6 bits mais significativos
    and eax, 0x3F               ; Máscara de segurança
    movzx eax, byte [rbx + rax] ; Traduz usando tabela
    mov [rsi], al

    ; Segundo caractere (sempre presente)
    mov eax, ecx
    shr eax, 12                 ; Extrai os próximos 6 bits
    and eax, 0x3F               ; Máscara para filtrar os 6 bits
    movzx eax, byte [rbx + rax]
    mov [rsi + 1], al

    ; Verifica se falta somente um byte para conversão
    cmp r8, 1          
    je .pad2

    ; Terceiro caractere
    mov eax, ecx
    shr eax, 6
    and eax, 0x3F               ; Máscara para filtrar os 6 bits
    movzx eax, byte [rbx + rax]
    mov [rsi + 2], al

    ; Verifica se faltam somente dois bytes para conversão
    cmp r8, 2          
    je .pad1

    ; Quarto caractere (3 bytes completos)
    mov eax, ecx
    and eax, 0x3F               ; Máscara para filtrar os 6 bits
    movzx eax, byte [rbx + rax]
    mov [rsi + 3], al
    jmp .end

.pad2:
    ; Apenas 1 byte de entrada: C0 C1 = =
    mov byte [rsi + 2], '='
.pad1:
    ; Apenas 2 bytes de entrada: C0 C1 C2 =
    mov byte [rsi + 3], '='

.end:
    pop rbx
    ret