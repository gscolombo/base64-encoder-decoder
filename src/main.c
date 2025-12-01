/*
 * ============================================================================
 * CODIFICADOR E DECODIFICADOR BASE64
 * ============================================================================
 * 
 * DESCRIÇÃO:
 *   Programa que converte arquivos binários para representação Base64 e
 *   vice-versa, utilizando rotinas em Assembly NASM para a conversão.
 * 
 * USO:
 *   ./b64 -e arquivo.bin    # Codifica arquivo binário para Base64
 *   ./b64 -d arquivo.txt    # Decodifica arquivo Base64 para binário
 * 
 * ALGORITMO DE CODIFICAÇÃO:
 *   - Lê 3 bytes do arquivo de entrada
 *   - Converte para 4 caracteres Base64 usando a tabela padrão
 *   - Adiciona padding '=' se necessário (menos de 3 bytes)
 *   - Insere '\r\n' a cada 76 caracteres
 * 
 * ALGORITMO DE DECODIFICAÇÃO:
 *   - Lê 4 caracteres Base64 (ignorando '\r' e '\n')
 *   - Converte para 3 bytes originais
 *   - Trata padding '=' adequadamente
 * 
 * ARQUIVOS GERADOS:
 *   - Codificação: [nome_original]_enc.txt
 *   - Decodificação: [nome_original]_dec.bin
 * 
 * ============================================================================
 */

#include <inttypes.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>

/* Protótipos das funções Assembly */
extern void   _3bto4a(unsigned char *input, unsigned char *output, size_t lin);
extern size_t _4ato3b(unsigned char *input, unsigned char *output);

/* ============================================================================
 * Função auxiliar: obtém tamanho do arquivo
 * ========================================================================== */
static size_t get_file_size(FILE *f) {
    if (!f) return 0;

    long current = ftell(f);
    if (current == -1L) return 0;

    if (fseek(f, 0L, SEEK_END) != 0) return 0;
    long size = ftell(f);
    if (size == -1L) return 0;

    if (fseek(f, current, SEEK_SET) != 0) return 0;

    return (size_t)size;
}

/* ============================================================================
 * Função auxiliar: gera nome de saída a partir de um input + sufixo
 * Ex.: "img.png" + "_enc.txt"  -> "img_enc.txt"
 *      "dir/test.bin" + "_dec.bin" -> "dir/test_dec.bin"
 * Retorna string alocada com malloc (quem chama deve dar free).
 * ========================================================================== */
static char *make_output_name(const char *input, const char *suffix) {
    if (!input || !suffix) return NULL;

    char *copy = strdup(input);
    if (!copy) return NULL;

    /* Remove apenas a última extensão (depois do último '.') */
    char *dot = strrchr(copy, '.');
    if (dot) {
        *dot = '\0';
    }

    size_t base_len   = strlen(copy);
    size_t suffix_len = strlen(suffix);
    size_t total_len  = base_len + suffix_len + 1; /* +1 para '\0' */

    char *result = (char *)malloc(total_len);
    if (!result) {
        free(copy);
        return NULL;
    }

    snprintf(result, total_len, "%s%s", copy, suffix);
    free(copy);

    return result;
}

/* ============================================================================
 * Codifica arquivo binário para Base64
 * 
 * @param in: Ponteiro para arquivo de entrada aberto em modo binário
 * @return: String alocada dinamicamente com conteúdo Base64 ou NULL em erro
 * ========================================================================== */
char *btoa(FILE *in)
{
    size_t lin = get_file_size(in);
    if (lin == 0) return NULL;

    /* Número de blocos de 3 bytes (arredondando pra cima) */
    size_t chunks = (lin + 2) / 3;
    size_t nchars = chunks * 4;                        /* 4 chars Base64 por bloco */
    size_t lines  = (nchars > 0) ? (nchars - 1) / 76 : 0;  /* número de quebras de linha */
    size_t lout   = nchars + (lines * 2) + 1;         /* +2 por "\r\n", +1 por '\0' */

    char *output = (char *)calloc(lout, sizeof(char));
    if (!output) return NULL;

    size_t i, j;
    int char_count = 0;  /* conta quantos caracteres já foram gerados */

    /* Volta pro início do arquivo para leitura */
    fseek(in, 0L, SEEK_SET);

    for (i = 0, j = 0; i < lin; i += 3)
    {
        unsigned char bytes[3] = {0};

        /* A cada 76 caracteres Base64, insere "\r\n" */
        if (char_count > 0 && char_count % 76 == 0)
        {
            output[j++] = '\r';
            output[j++] = '\n';
        }

        /* Quantos bytes ainda faltam? (1, 2 ou 3) */
        size_t remaining = lin - i;
        size_t count = (remaining >= 3) ? 3 : remaining;

        size_t read = fread(bytes, 1, count, in);
        if (read != count) {
            /* Erro de leitura ou EOF inesperado */
            free(output);
            return NULL;
        }

        /* Converte com rotina Assembly */
        _3bto4a(bytes, (unsigned char *)&output[j], count);

        j          += 4;
        char_count += 4;
    }

    output[j] = '\0';
    return output;
}

/* ============================================================================
 * Decodifica arquivo Base64 para binário
 * 
 * @param in: Ponteiro para arquivo de entrada Base64
 * @param out_size: Ponteiro para armazenar tamanho do buffer de saída
 * @return: Buffer alocado dinamicamente com dados binários ou NULL em erro
 * ========================================================================== */
unsigned char *atob(FILE *in, size_t *out_size)
{
    if (!in || !out_size) return NULL;

    size_t lin = get_file_size(in);
    if (lin == 0)
    {
        *out_size = 0;
        return NULL;
    }

    /* Tamanho máximo estimado de saída */
    size_t max_out = (lin / 4) * 3 + 3;
    unsigned char *output = (unsigned char *)calloc(max_out, sizeof(unsigned char));
    if (!output)
    {
        *out_size = 0;
        return NULL;
    }

    unsigned char block[4];
    size_t block_pos = 0;
    size_t out_pos   = 0;
    int c;

    fseek(in, 0L, SEEK_SET);

    /* Lê arquivo caractere por caractere */
    while ((c = fgetc(in)) != EOF)
    {
        /* Ignora quebras de linha e espaços em branco simples */
        if (c == '\r' || c == '\n' || c == ' ' || c == '\t')
            continue;

        /* Valida caractere Base64 */
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
              (c >= '0' && c <= '9') || c == '+' || c == '/' || c == '='))
        {
            fprintf(stderr, "Caractere inválido encontrado: '%c' (0x%02X)\n", c, (unsigned)c);
            free(output);
            *out_size = 0;
            return NULL;
        }

        block[block_pos++] = (unsigned char)c;

        /* Quando completar um bloco de 4 caracteres, decodifica */
        if (block_pos == 4)
        {
            unsigned char decoded[3];
            size_t bytes_written = _4ato3b(block, decoded);
            
            if (bytes_written == 0)
            {
                fprintf(stderr, "Erro ao decodificar bloco Base64\n");
                free(output);
                *out_size = 0;
                return NULL;
            }

            memcpy(&output[out_pos], decoded, bytes_written);
            out_pos   += bytes_written;
            block_pos  = 0;
        }
    }

    /* Se sobrou bloco incompleto, formato inválido */
    if (block_pos != 0)
    {
        fprintf(stderr, "Arquivo Base64 incompleto (bloco parcial no final)\n");
        free(output);
        *out_size = 0;
        return NULL;
    }

    *out_size = out_pos;
    return output;
}

/* ============================================================================
 * main
 * ========================================================================== */
int main(const int argc, char *argv[])
{
    if (argc < 3)
    {
        printf("CODIFICADOR/DECODIFICADOR BASE64\n\n");
        printf("USO:\n");
        printf("  Codificar:   %s [-e | --encode] arquivo_entrada\n", argv[0]);
        printf("  Decodificar: %s [-d | --decode] arquivo_entrada\n\n", argv[0]);
        printf("EXEMPLOS:\n");
        printf("  %s -e imagem.png     # Gera imagem_enc.txt\n", argv[0]);
        printf("  %s -d imagem_enc.txt # Gera imagem_enc_dec.bin\n", argv[0]);
        return 1;
    }

    int encode;
    if (!strcmp(argv[1], "-e") || !strcmp(argv[1], "--encode"))
        encode = 1;
    else if (!strcmp(argv[1], "-d") || !strcmp(argv[1], "--decode"))
        encode = 0;
    else
    {
        printf("ERRO: Opção inválida '%s'\n\n", argv[1]);
        printf("USO: %s [-e | --encode | -d | --decode] arquivo\n", argv[0]);
        return 1;
    }

    FILE *fptr = fopen(argv[2], "rb");
    if (!fptr)
    {
        printf("ERRO: Não foi possível abrir o arquivo '%s'\n", argv[2]);
        return 1;
    }

    if (encode)
    {
        printf("Codificando arquivo '%s' para Base64...\n", argv[2]);
        
        char *encoded = btoa(fptr);
        fclose(fptr);

        if (!encoded)
        {
            printf("ERRO: Falha ao codificar arquivo\n");
            return 1;
        }

        /* Gera nome do arquivo de saída: *_enc.txt */
        char *output_file = make_output_name(argv[2], "_enc.txt");
        if (!output_file)
        {
            printf("ERRO: Falha ao gerar nome do arquivo de saída\n");
            free(encoded);
            return 1;
        }

        fptr = fopen(output_file, "wb");
        if (!fptr)
        {
            printf("ERRO: Não foi possível criar arquivo '%s'\n", output_file);
            free(encoded);
            free(output_file);
            return 1;
        }

        size_t encoded_size = strlen(encoded);
        fwrite(encoded, sizeof(char), encoded_size, fptr);
        fclose(fptr);

        /* Reabre arquivo original para mostrar tamanho */
        fptr = fopen(argv[2], "rb");
        size_t orig_size = get_file_size(fptr);
        if (fptr) fclose(fptr);

        printf("✓ Arquivo codificado salvo em: %s\n", output_file);
        printf("  Tamanho original:   %zu bytes\n", orig_size);
        printf("  Tamanho codificado: %zu caracteres\n", encoded_size);

        free(encoded);
        free(output_file);
    }
    else
    {
        printf("Decodificando arquivo Base64 '%s'...\n", argv[2]);
        
        size_t output_size;
        unsigned char *decoded = atob(fptr, &output_size);
        fclose(fptr);

        if (!decoded)
        {
            printf("ERRO: Falha ao decodificar arquivo\n");
            return 1;
        }

        /* Gera nome do arquivo de saída: *_dec.bin */
        char *output_file = make_output_name(argv[2], "_dec.bin");
        if (!output_file)
        {
            printf("ERRO: Falha ao gerar nome do arquivo de saída\n");
            free(decoded);
            return 1;
        }

        fptr = fopen(output_file, "wb");
        if (!fptr)
        {
            printf("ERRO: Não foi possível criar arquivo '%s'\n", output_file);
            free(decoded);
            free(output_file);
            return 1;
        }

        fwrite(decoded, sizeof(unsigned char), output_size, fptr);
        fclose(fptr);

        printf("✓ Arquivo decodificado salvo em: %s\n", output_file);
        printf("  Tamanho decodificado: %zu bytes\n", output_size);

        free(decoded);
        free(output_file);
    }

    return 0;
}
