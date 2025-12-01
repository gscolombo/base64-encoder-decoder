#!/usr/bin/env bash
set -euo pipefail

echo "=== Testes automáticos do codificador/decodificador Base64 ==="

# Pasta onde ficarão os arquivos de teste AUTOMÁTICOS (separada)
BASE_DIR="test_outputs"
OUTPUT_DIR="$BASE_DIR/auto"

echo "[INFO] Criando pasta de saída: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
# Limpa apenas a subpasta 'auto', sem mexer nos arquivos dos testes básicos
rm -f "$OUTPUT_DIR"/* 2>/dev/null || true

# -----------------------------------------------------------------------------
# Função: checar se todas as linhas têm <= 76 caracteres (ignorando '\r')
# -----------------------------------------------------------------------------
check_line_length() {
  local file="$1"

  # Se o arquivo estiver vazio, ok
  if [ ! -s "$file" ]; then
    echo "  [OK] Arquivo '$file' vazio (nenhuma linha para checar)."
    return 0
  fi

  # Remove o '\r' antes de medir o comprimento das linhas
  if tr -d '\r' < "$file" | awk 'length($0) > 76 { exit 1 }'; then
    echo "  [OK] Todas as linhas de '$file' têm <= 76 caracteres (desconsiderando o \\r do \\r\\n)"
  else
    echo "  [FAIL] Linha com mais de 76 caracteres em '$file' (mesmo ignorando \\r)"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Função: codificar, checar linhas e decodificar comparando com o original
# -----------------------------------------------------------------------------
test_roundtrip() {
  local file="$1"   # caminho completo (dentro de $OUTPUT_DIR)
  local name="$2"   # nome "bonito" pra mostrar no log

  echo
  echo "=== Testando arquivo: $name ==="

  echo "  [INFO] Codificando..."
  ./b64 -e "$file" > /dev/null

  local base="${file%.*}"         # ex: test_outputs/auto/test_1byte
  local enc="${base}_enc.txt"     # ex: test_outputs/auto/test_1byte_enc.txt

  check_line_length "$enc"

  echo "  [INFO] Decodificando..."
  ./b64 -d "$enc" > /dev/null

  local dec="${base}_enc_dec.bin" # ex: test_outputs/auto/test_1byte_enc_dec.bin

  if cmp -s "$file" "$dec"; then
    echo "  [OK] Arquivo decodificado é idêntico ao original"
  else
    echo "  [FAIL] Arquivo decodificado difere do original"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# 1) Criar arquivos de teste dentro de test_outputs/auto/
# -----------------------------------------------------------------------------
echo "[INFO] Criando arquivos de teste automáticos..."

dd if=/dev/zero bs=1 count=1 of="$OUTPUT_DIR/test_1byte.bin"   status=none
dd if=/dev/zero bs=1 count=2 of="$OUTPUT_DIR/test_2bytes.bin"  status=none
dd if=/dev/zero bs=1 count=3 of="$OUTPUT_DIR/test_3bytes.bin"  status=none
dd if=/dev/zero bs=1 count=4 of="$OUTPUT_DIR/test_4bytes.bin"  status=none

head -c 4096 /dev/urandom > "$OUTPUT_DIR/test_random.bin"

# -----------------------------------------------------------------------------
# 2) Rodar os testes em cada arquivo
# -----------------------------------------------------------------------------
test_roundtrip "$OUTPUT_DIR/test_1byte.bin"   "test_1byte.bin"
test_roundtrip "$OUTPUT_DIR/test_2bytes.bin"  "test_2bytes.bin"
test_roundtrip "$OUTPUT_DIR/test_3bytes.bin"  "test_3bytes.bin"
test_roundtrip "$OUTPUT_DIR/test_4bytes.bin"  "test_4bytes.bin"
test_roundtrip "$OUTPUT_DIR/test_random.bin"  "test_random.bin"

echo
echo "=== TODOS OS TESTES PASSARAM ==="
echo "Arquivos de teste e resultados estão em: $BASE_DIR/ (básicos) e $OUTPUT_DIR/ (automáticos)"
