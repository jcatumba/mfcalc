/* mfcalc */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern FILE *yyin;
extern FILE *yyout;
extern int yyparse(void);

int main (int argc, char const *argv[]){
    char command[256];
    init_table();

    while (1) {
        printf ("[mfcalc]: ");
        memset (command, 0x00, sizeof(command));
        fgets (command, 100, stdin);
        yyin = fopen ("command", "w+");
        fprintf (yyin, "%s", command);
        fseek (yyin, 0, SEEK_SET); /* Put pointer at beginig of the file */
        yyparse ();
        remove ("command");
        //fclose (fp);
    }

}
