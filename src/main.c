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

// Protótipos das funções Assembly
extern void _3bto4a(unsigned char *input, unsigned char *output, size_t lin);
extern size_t _4ato3b(unsigned char *input, unsigned char *output);

/**
 * Codifica arquivo binário para Base64
 * 
 * @param in: Ponteiro para arquivo de entrada aberto em modo binário
 * @return: String alocada dinamicamente com conteúdo Base64 ou NULL em erro
 */
char *btoa(FILE *in)
{
    // Calcula a quantidade de bytes no arquivo de entrada
    fseek(in, 0L, SEEK_END);
    size_t lin = ftell(in);
    fseek(in, 0L, SEEK_SET);

    if (lin == 0) return NULL;

    size_t pads = (3 - (lin % 3)) % 3;                // Quantidade de caracteres "="
    size_t nchars = ceil(lin / 3.) * 4;               // Quantidade de caracteres Base64
    size_t lines = (nchars > 0) ? (nchars - 1) / 76 : 0;  // Quantidade de quebras de linha
    size_t lout = nchars + (lines * 2) + 1;           // Tamanho total (com \r\n e terminador)

    char *output = (char *)calloc(lout, sizeof(char));
    if (!output) return NULL;

    size_t i, j, count, r;
    int char_count = 0;  // Contador para inserção de \r\n

    for (i = 0, j = 0; i < lin; i += 3)
    {
        unsigned char bytes[3] = {0};

        // A cada 76 caracteres, insere "\r\n"
        if (char_count > 0 && char_count % 76 == 0)
        {
            output[j++] = '\r';
            output[j++] = '\n';
        }

        // Determina quantos bytes ler (1, 2 ou 3)
        count = (r = lin - ftell(in)) > 3 ? 3 : r;
        fread(bytes, sizeof(char), count, in);
        
        // Chama função Assembly para converter 3 bytes em 4 caracteres Base64
        _3bto4a(bytes, (unsigned char *)&output[j], count);
        
        j += 4;
        char_count += 4;
    }

    output[lout - 1] = '\0';
    return output;
}

/**
 * Decodifica arquivo Base64 para binário
 * 
 * @param in: Ponteiro para arquivo de entrada Base64
 * @param out_size: Ponteiro para armazenar tamanho do buffer de saída
 * @return: Buffer alocado dinamicamente com dados binários ou NULL em erro
 */
unsigned char *atob(FILE *in, size_t *out_size)
{
    // Calcula tamanho do arquivo
    fseek(in, 0L, SEEK_END);
    size_t lin = ftell(in);
    fseek(in, 0L, SEEK_SET);

    if (lin == 0)
    {
        *out_size = 0;
        return NULL;
    }

    // Aloca buffer para saída (tamanho máximo estimado)
    size_t max_out = (lin / 4) * 3 + 3;
    unsigned char *output = (unsigned char *)calloc(max_out, sizeof(unsigned char));
    if (!output)
    {
        *out_size = 0;
        return NULL;
    }

    unsigned char block[4];
    size_t block_pos = 0;
    size_t out_pos = 0;
    int c;

    // Lê arquivo caractere por caractere
    while ((c = fgetc(in)) != EOF)
    {
        // Ignora caracteres de quebra de linha e espaços
        if (c == '\r' || c == '\n' || c == ' ' || c == '\t')
            continue;

        // Valida caractere Base64
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
              (c >= '0' && c <= '9') || c == '+' || c == '/' || c == '='))
        {
            fprintf(stderr, "Caractere inválido encontrado: '%c' (0x%02X)\n", c, c);
            free(output);
            *out_size = 0;
            return NULL;
        }

        block[block_pos++] = (unsigned char)c;

        // Quando completar um bloco de 4 caracteres, decodifica
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

            // Copia bytes decodificados para saída
            memcpy(&output[out_pos], decoded, bytes_written);
            out_pos += bytes_written;
            block_pos = 0;
        }
    }

    // Verifica se sobrou algum bloco incompleto (erro de formato)
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

int main(const int argc, char *argv[])
{
    if (argc < 3)
    {
        printf("CODIFICADOR/DECODIFICADOR BASE64\n\n");
        printf("USO:\n");
        printf("  Codificar: %s [-e | --encode] arquivo_entrada\n", argv[0]);
        printf("  Decodificar: %s [-d | --decode] arquivo_entrada\n\n", argv[0]);
        printf("EXEMPLOS:\n");
        printf("  %s -e imagem.png     # Gera imagem_enc.txt\n", argv[0]);
        printf("  %s -d imagem_enc.txt # Gera imagem_enc_dec.bin\n", argv[0]);
        exit(1);
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
        exit(1);
    }

    FILE *fptr = fopen(argv[2], "rb");
    if (!fptr)
    {
        printf("ERRO: Não foi possível abrir o arquivo '%s'\n", argv[2]);
        exit(1);
    }

    if (encode)
    {
        printf("Codificando arquivo '%s' para Base64...\n", argv[2]);
        
        const char *output = btoa(fptr);
        fclose(fptr);

        if (!output)
        {
            printf("ERRO: Falha ao codificar arquivo\n");
            exit(1);
        }

        // Cria nome do arquivo de saída
        size_t l = strlen(argv[2]) + 8 + 1;
        char output_file[l];
        char *fname_copy = strdup(argv[2]);
        char *fname = strtok(fname_copy, ".");

        strcpy(output_file, fname);
        strcat(output_file, "_enc.txt");
        output_file[l - 1] = '\0';

        // Grava arquivo codificado
        fptr = fopen(output_file, "wb");
        if (!fptr)
        {
            printf("ERRO: Não foi possível criar arquivo '%s'\n", output_file);
            free((void *)output);
            free(fname_copy);
            exit(1);
        }

        size_t encoded_size = strlen(output);
        fwrite(output, sizeof(char), encoded_size, fptr);
        fclose(fptr);

        // Reabre arquivo original para mostrar tamanho
        FILE *fptr_orig = fopen(argv[2], "rb");
        fseek(fptr_orig, 0L, SEEK_END);
        size_t orig_size = ftell(fptr_orig);
        fclose(fptr_orig);

        printf("✓ Arquivo codificado salvo em: %s\n", output_file);
        printf("  Tamanho original: %ld bytes\n", orig_size);
        printf("  Tamanho codificado: %ld caracteres\n", encoded_size);

        free((void *)output);
        free(fname_copy);
    }
    else
    {
        printf("Decodificando arquivo Base64 '%s'...\n", argv[2]);
        
        size_t output_size;
        unsigned char *output = atob(fptr, &output_size);
        fclose(fptr);

        if (!output)
        {
            printf("ERRO: Falha ao decodificar arquivo\n");
            exit(1);
        }

        // Cria nome do arquivo de saída
        size_t l = strlen(argv[2]) + 9 + 1;
        char output_file[l];
        char *fname_copy = strdup(argv[2]);
        char *fname = strtok(fname_copy, ".");

        strcpy(output_file, fname);
        strcat(output_file, "_dec.bin");
        output_file[l - 1] = '\0';

        // Grava arquivo decodificado
        fptr = fopen(output_file, "wb");
        if (!fptr)
        {
            printf("ERRO: Não foi possível criar arquivo '%s'\n", output_file);
            free(output);
            free(fname_copy);
            exit(1);
        }

        fwrite(output, sizeof(unsigned char), output_size, fptr);
        fclose(fptr);

        printf("✓ Arquivo decodificado salvo em: %s\n", output_file);
        printf("  Tamanho decodificado: %ld bytes\n", output_size);

        free(output);
        free(fname_copy);
    }

    return 0;
}