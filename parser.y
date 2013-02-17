%{
    #include <math.h>
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <ctype.h>
    #include "parser.h"
    #define YYDEBUG 1
    #define YYPRINT(file, type, value) yyprint(file, type, value)
    int yylex(void);
    void yyerror(char const*s);
    void yyprint();
%}

%union {
    double val;
    char sym;
    symrec *tptr;
}

%token <val> NUM /* Simple double precision number */
%token <sym> LP RP LA RA LB RB COMMA COLON PLUS MINUS TIMES OVER EQ TO STOP
%token <tptr> VAR FNCT /* Variable and function */
%type <val> exp

%right EQ
%left PLUS MINUS
%left TIMES OVER
%right TO
%right COMMA
%right COLON

%% /* The grammar follows */

input       : /* empty */
            | input line
;

line        : STOP      
            | exp STOP { printf ( ">>> %.10g\n", $1 ); }
            | error STOP { yyerrok; }
;

exp         : NUM               { $$ = $1; }
            | VAR               { $$ = $1->value.var; }
            | VAR EQ exp        { $$ = $3; $1->value.var = $3; }
            | FNCT LP exp RP    { $$ = (*($1->value.fnctptr))($3); }
            | exp PLUS exp      { $$ = $1 + $3; }
            | exp MINUS exp     { $$ = $1 - $3; }
            | exp TIMES exp     { $$ = $1 * $3; }
            | exp OVER exp      { $$ = $1 / $3; }
            | exp TO exp        { $$ = pow ($1, $3); }
            | LP exp RP         { $$ = $2; }
;

/* End of grammar */
%%

/* Called by yyparse on error. */
void yyerror( char const *s ) {
    fprintf( stderr, "netext: %s\n", s );
}

struct init {
    char const *fname;
    double (*fnct) (double);
};

struct init const arith_fncts[] =
{
    {"sin", sin},
    {"cos", cos},
    {"atan", atan},
    {"ln", log},
    {"exp", exp},
    {"sqrt", sqrt},
    {0, 0}
};

/* The symbol table: a chain of `struct symrec' */
symrec *sym_table;

/* Put arithmetic functions in table */
void init_table (void) {
    int i;
    for (i=0; arith_fncts[i].fname != 0; i++) {
        symrec *ptr = putsym (arith_fncts[i].fname, FNCT);
        ptr->value.fnctptr = arith_fncts[i].fnct;
    }
}

/*int main(int argc, char const* argv[]) {
    int i;
    for (i=1; i < argc; ++i)
        if(!strcmp(argv[i], "-p"))
            yydebug = 1;
    init_table ();
    //printf("%i\n", yyparse());
    return yyparse ();
}*/

symrec * putsym (char const *sym_name, int sym_type) {
    symrec *ptr = (symrec*) malloc (sizeof (symrec));
    ptr->name = (char*) malloc (strlen (sym_name) + 1);
    strcpy (ptr->name, sym_name);
    ptr->type = sym_type;
    ptr->value.var = 0; /* Set value to 0 even if fctn */
    ptr->next = (struct symrec *)sym_table;
    sym_table = ptr;
    return ptr;
}

symrec * getsym (char const *sym_name) {
    symrec *ptr;
    for (ptr = sym_table; ptr != (symrec *) 0; ptr = (symrec *)ptr->next) {
        if (strcmp (ptr->name, sym_name) == 0) {
            return ptr;
        }
    }
    return 0;
}

void yyprint(FILE *file, int type, YYSTYPE value) {
    if (type == VAR)
        fprintf(file, " %s", value.tptr->name);
    else if (type == NUM)
        fprintf(file, " %g", value.val);
}