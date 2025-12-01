# ============================================================================
# Makefile para Codificador/Decodificador Base64
# ============================================================================
# 
# Uso:
#   make          # Compila o projeto
#   make clean    # Remove arquivos compilados
#   make test     # Executa testes (básicos + automáticos)
#   make help     # Mostra ajuda
#

CC = gcc
NASM = nasm
CFLAGS = -Wall -Wextra -O2 -g
NASMFLAGS = -f elf64 -g

TARGET = b64
SRC_DIR = src
OBJ_DIR = obj
TEST_DIR = test_outputs

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

# Testes (básicos + automáticos), tudo dentro de $(TEST_DIR)
# Testes (básicos + automáticos), tudo organizado usando $(TEST_DIR)
test: $(TARGET)
	@echo "=========================================="
	@echo "Executando testes básicos..."
	@echo "=========================================="
	@echo ""
	@echo "[INFO] Preparando pasta de testes: $(TEST_DIR)"
	@mkdir -p $(TEST_DIR)
	@rm -f $(TEST_DIR)/* 2>/dev/null || true

	@echo "Teste 1: Codificando string 'ABCD'"
	@echo -n "ABCD" > $(TEST_DIR)/test_input.bin
	./$(TARGET) -e $(TEST_DIR)/test_input.bin
	# O programa provavelmente gerou test_input_enc.txt na raiz do projeto.
	@mv -f test_input_enc.txt $(TEST_DIR)/ 2>/dev/null || true
	@echo ""
	@echo "Teste 2: Decodificando resultado"
	./$(TARGET) -d $(TEST_DIR)/test_input_enc.txt
	# O programa provavelmente gerou test_input_enc_dec.bin na raiz do projeto.
	@mv -f test_input_enc_dec.bin $(TEST_DIR)/ 2>/dev/null || true
	@echo ""
	@echo "Teste 3: Verificando integridade"
	@if diff $(TEST_DIR)/test_input.bin $(TEST_DIR)/test_input_enc_dec.bin > /dev/null 2>&1; then \
		echo "✓ Teste passou! Arquivo original e decodificado são idênticos"; \
	else \
		echo "✗ Teste falhou! Arquivos diferem"; \
	fi
	@echo ""
	@echo "Teste 4: Codificando arquivo de texto maior"
	@echo "Este é um teste com mais conteúdo para verificar a quebra de linha a cada 76 caracteres no formato Base64. Vamos adicionar mais texto para garantir que ultrapasse 76 caracteres quando codificado." > $(TEST_DIR)/test_long.txt
	./$(TARGET) -e $(TEST_DIR)/test_long.txt
	@mv -f test_long_enc.txt $(TEST_DIR)/ 2>/dev/null || true
	@echo ""
	@echo "Teste 5: Decodificando arquivo maior"
	./$(TARGET) -d $(TEST_DIR)/test_long_enc.txt
	@mv -f test_long_enc_dec.bin $(TEST_DIR)/ 2>/dev/null || true
	@if diff $(TEST_DIR)/test_long.txt $(TEST_DIR)/test_long_enc_dec.bin > /dev/null 2>&1; then \
		echo "✓ Teste passou! Arquivos são idênticos"; \
	else \
		echo "✗ Teste falhou! Arquivos diferem"; \
	fi
	@echo ""
	@echo "=========================================="
	@echo "Testes básicos concluídos!"
	@echo "=========================================="
	@echo ""
	@echo "Agora rodando testes automáticos adicionais (script test_b64.sh)..."
	@echo ""

	@if [ -x ./test_b64.sh ]; then \
		./test_b64.sh; \
	else \
		echo "⚠ Aviso: script ./test_b64.sh não encontrado ou sem permissão de execução."; \
		echo "  Crie o script de testes automáticos ou rode: chmod +x test_b64.sh"; \
	fi

# Limpa arquivos compilados e de teste
clean:
	rm -rf $(OBJ_DIR) $(TARGET) $(TEST_DIR)
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
	@echo "  make test     - Executa testes (básicos + automáticos)"
	@echo "  make help     - Mostra esta ajuda"
	@echo ""
	@echo "Após compilar, use:"
	@echo "  ./$(TARGET) -e arquivo.bin    # Codifica"
	@echo "  ./$(TARGET) -d arquivo.txt    # Decodifica"
	@echo ""

.PHONY: all clean test help
