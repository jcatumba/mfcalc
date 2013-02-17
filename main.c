/* mfcalc */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern FILE *yyin;
extern int yyparse();

int main (int argc, char *argv[]){
    char command[256];
    FILE *fp;
    init_table();


    while(1){
        printf ("[mfcalc]: ");
        memset (command, 0x00, sizeof(command));
        fgets (command, 100, stdin);
        fp = fopen("command.txt", "w+");
        fprintf(fp, "%s", command);
        yyin=fp;
        yyparse();
        fclose(fp);
    }

}
