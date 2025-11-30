# ============================================================================
# Makefile para Codificador/Decodificador Base64
# ============================================================================
# 
# Uso:
#   make          # Compila o projeto
#   make clean    # Remove arquivos compilados
#   make test     # Executa testes básicos
#   make help     # Mostra ajuda
#

CC = gcc
NASM = nasm
CFLAGS = -Wall -Wextra -O2 -g
NASMFLAGS = -f elf64 -g

TARGET = b64
SRC_DIR = src
OBJ_DIR = obj

# Arquivos fonte
C_SRC = $(SRC_DIR)/main.c
ASM_ENCODE = $(SRC_DIR)/_3bto4a.s
ASM_DECODE = $(SRC_DIR)/_4ato3b.s

# Arquivos objeto
C_OBJ = $(OBJ_DIR)/main.o
ASM_ENCODE_OBJ = $(OBJ_DIR)/_3bto4a.o
ASM_DECODE_OBJ = $(OBJ_DIR)/_4ato3b.o

all: $(TARGET)

# Cria diretório de objetos se não existir
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

# Compila arquivo C
$(C_OBJ): $(C_SRC) | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compila arquivo Assembly de codificação
$(ASM_ENCODE_OBJ): $(ASM_ENCODE) | $(OBJ_DIR)
	$(NASM) $(NASMFLAGS) $< -o $@

# Compila arquivo Assembly de decodificação
$(ASM_DECODE_OBJ): $(ASM_DECODE) | $(OBJ_DIR)
	$(NASM) $(NASMFLAGS) $< -o $@

# Linka todos os objetos
$(TARGET): $(C_OBJ) $(ASM_ENCODE_OBJ) $(ASM_DECODE_OBJ)
	$(CC) $(CFLAGS) $^ -o $@ -lm
	@echo ""
	@echo "✓ Compilação concluída com sucesso!"
	@echo "  Executável: ./$(TARGET)"
	@echo ""
	@echo "Uso:"
	@echo "  ./$(TARGET) -e arquivo.bin    # Codifica para Base64"
	@echo "  ./$(TARGET) -d arquivo.txt    # Decodifica de Base64"
	@echo ""

# Testes básicos
test: $(TARGET)
	@echo "=========================================="
	@echo "Executando testes básicos..."
	@echo "=========================================="
	@echo ""
	@echo "Teste 1: Codificando string 'ABCD'"
	@echo -n "ABCD" > test_input.bin
	./$(TARGET) -e test_input.bin
	@echo ""
	@echo "Teste 2: Decodificando resultado"
	./$(TARGET) -d test_input_enc.txt
	@echo ""
	@echo "Teste 3: Verificando integridade"
	@if diff test_input.bin test_input_enc_dec.bin > /dev/null 2>&1; then \
		echo "✓ Teste passou! Arquivo original e decodificado são idênticos"; \
	else \
		echo "✗ Teste falhou! Arquivos diferem"; \
	fi
	@echo ""
	@echo "Teste 4: Codificando arquivo de texto maior"
	@echo "Este é um teste com mais conteúdo para verificar a quebra de linha a cada 76 caracteres no formato Base64. Vamos adicionar mais texto para garantir que ultrapasse 76 caracteres quando codificado." > test_long.txt
	./$(TARGET) -e test_long.txt
	@echo ""
	@echo "Teste 5: Decodificando arquivo maior"
	./$(TARGET) -d test_long_enc.txt
	@if diff test_long.txt test_long_enc_dec.bin > /dev/null 2>&1; then \
		echo "✓ Teste passou! Arquivos são idênticos"; \
	else \
		echo "✗ Teste falhou! Arquivos diferem"; \
	fi
	@echo ""
	@echo "=========================================="
	@echo "Testes concluídos!"
	@echo "=========================================="

# Limpa arquivos compilados e de teste
clean:
	rm -rf $(OBJ_DIR) $(TARGET)
	rm -f test_input.bin test_input_enc.txt test_input_enc_dec.bin
	rm -f test_long.txt test_long_enc.txt test_long_enc_dec.bin
	@echo "✓ Arquivos de compilação e teste removidos"

# Ajuda
help:
	@echo "=========================================="
	@echo "Makefile - Codificador/Decodificador Base64"
	@echo "=========================================="
	@echo ""
	@echo "Comandos disponíveis:"
	@echo "  make          - Compila o projeto"
	@echo "  make clean    - Remove arquivos compilados"
	@echo "  make test     - Executa testes básicos"
	@echo "  make help     - Mostra esta ajuda"
	@echo ""
	@echo "Após compilar, use:"
	@echo "  ./$(TARGET) -e arquivo.bin    # Codifica"
	@echo "  ./$(TARGET) -d arquivo.txt    # Decodifica"
	@echo ""

.PHONY: all clean test help