/* mfcalc */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern FILE *yyin;
extern FILE *yyout;
extern int yyparse(void);

int main (int argc, char const *argv[]){
    char command[256];
    char output[256];
    FILE *fp;
    init_table();

    while (1) {
        printf ("[mfcalc]: ");
        memset (command, 0x00, sizeof(command));
        fgets (command, 100, stdin);
        fp = fopen("command.txt", "w+");
        fprintf(fp, "%s", command);
        yyin=fp;
        yyparse();
        fscanf(yyout, "%s", output);
        printf("%s\n", output);
        fclose(fp);
    }

}

/*int main(int argc, char const *argv[]){
    init_table ();
    return yyparse ();
}*/
