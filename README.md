# (De)Codificador Base64

Um codificador e decodificador para Base64 implementado em Assembly x64 (NASM). \
O programa converte 3 bytes para 4 bytes correspondentes ao conjunto de caracteres do Base64.

## Como Usar: 
```
# Compilar
make

# Testar
make test

# Codificar
./b64 -e arquivo.bin

# Decodificar
./b64 -d arquivo_enc.txt

```
