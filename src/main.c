#include <inttypes.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern void _3bto4a(unsigned char *input, unsigned char *output, size_t lin);

char *btoa(FILE *in)
{
    // Calcula a quantidade de bytes no arquivo de entrada
    fseek(in, 0L, SEEK_END);
    size_t lin = ftell(in);
    fseek(in, 0L, SEEK_SET);

    size_t pads = (3 - (lin % 3)) % 3;                // Calcula a quantidade de caracteres "="
    size_t nchars = ceil(lin / 3.) * 4;               // Calcula a quantidade de caracteres imprimíveis (exceto "=")
    double crnl = nchars / 76.;                       // Calcula a quantidade de strings "\r\n"
    size_t lout = nchars + pads + ceil(2 * crnl) + 1; // Calcula a quantidade final de caracteres (com terminador)

    char *output = (char *)calloc(lout, sizeof(char));
    if (output)
    {
        size_t i, j, k, count, r;
        

        for (i = 0, j = 0, k = 0; i < lin; i += 3, j += 4, k += 4)
        {
            unsigned char bytes[3] = {0};

            // A cada 76 caracteres, é incluído "\r\n"
            if (k > 0 && !(k % 76))
            {
                output[j++] = '\r';
                output[j++] = '\n';
            }

            count = (r = lin - ftell(in)) > 3 ? 3 : r; // Se faltar menos de 3 bytes para leitura, lê somente os bytes restantes.
            fread(bytes, sizeof(char), count, in);
            _3bto4a(bytes, &output[j], count);
        }

        output[lout - 1] = '\0';

        return output;
    }

    return NULL;
}

int main(const int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("USO: b64 [-e | --encode | -d | --decode ] caminho\n");
        exit(1);
    }

    int encode;
    if (!strcmp(argv[1], "-e") || !strcmp(argv[1], "--encode"))
        encode = 1;
    else if (!strcmp(argv[1], "-e") || !strcmp(argv[1], "-e"))
        encode = 0;
    else
    {
        printf("Argumentos inválidos.\n"
               "USO: b64 [-e | --encode | -d | --decode ] caminho\n");
        exit(1);
    }

    if (!argv[2])
    {
        printf("Passe um caminho para um arquivo.\n"
               "USO: b64 [-e | --encode | -d | --decode ] caminho\n");
        exit(1);
    }

    FILE *fptr = fopen(argv[2], "rb");
    if (!fptr)
    {
        printf("Erro ao abrir arquivo %s.\n", argv[2]);
        exit(1);
    }

    if (encode)
    {
        const char *output = btoa(fptr);

        fclose(fptr);
        if (output)
        {
            printf("Output:\n%s\n", output);

            size_t l = strlen(argv[2]) + 8 + 1;
            char output_file[l];
            char *fname = strtok(argv[2], ".");

            strcpy(output_file, fname);
            strcat(output_file, "_enc.txt");
            output_file[l - 1] = '\0';

            fptr = fopen(output_file, "wb");
            if (!fptr)
            {
                printf("Erro ao criar arquivo %s.\n", output_file);
                exit(1);
            }

            fwrite(output, sizeof(char), strlen(output), fptr);
            fclose(fptr);

            free((void *)output);
        }
    }

    return 0;
}