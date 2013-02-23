/* mfcalc */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.h"

extern FILE *yyin;
extern int yyparse(void);

int main (int argc, char const *argv[]){
    char command[256];
    init_table();
    s = (stack*) malloc (sizeof (stack));
    s->top = -1;

    while (1) {
        printf ("[mfcalc]: ");
        memset (command, 0x00, sizeof(command));
        fgets (command, 100, stdin);
        yyin = fopen ("command", "w+");
        fprintf (yyin, "%s", command);
        fseek (yyin, 0, SEEK_SET); /* Put pointer at beginig of the file */
        yyparse ();
        remove ("command");
    }

}
