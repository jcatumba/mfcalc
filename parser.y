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
    params par;
}

%token <val> NUM /* Simple double precision number */
%token <sym> LP RP LA RA LB RB COMMA COLON PLUS MINUS TIMES OVER EQ TO STOP
%token <tptr> VAR FNCT FNCP /* Variable and functions */
%type <val> /*exp*/ basicexp genericexp csv

%right EQ
%left PLUS MINUS
%left TIMES OVER
%right TO
%right COMMA
/*%right COLON*/

%% /* The grammar follows */

input       : /* empty */
            | input line
;

line        : STOP      
            | genericexp STOP { printf ( ">>> %.10g\n", $1 ); }
            | error STOP { yyerrok; }
;

genericexp  : csv
/*            | FNCP LP csv RP    { $$ = (*($1->value.fncpptr))($3); }*/
;

basicexp    : NUM               { $$ = $1; }
            | VAR               { $$ = $1->value.var; }
            | VAR EQ basicexp        { $$ = $3; $1->value.var = $3; }
            | FNCT LP basicexp RP { $$ = (*($1->value.fnctptr))($3); }
            | basicexp PLUS basicexp      { $$ = $1 + $3; }
            | basicexp MINUS basicexp     { $$ = $1 - $3; }
            | basicexp TIMES basicexp     { $$ = $1 * $3; }
            | basicexp OVER basicexp      { $$ = $1 / $3; }
            | basicexp TO basicexp        { $$ = pow ($1, $3); }
            | LP basicexp RP         { $$ = $2; }
;

csv         : basicexp
            | csv COMMA basicexp{ $$ = $3; /* put something here */}
;

/* End of grammar */
%%

/* Called by yyparse on error. */
void yyerror( char const *s ) {
    fprintf( stderr, "netext: %s\n", s );
}

struct init {
    char const *fname;
    union {
        double (*fnc1) (double);
        double (*fnc2) (params);
    } fnct;
};

struct init const arith_fncts[] =
{
    {"sin", sin},
    {"cos", cos},
    {"atan", atan},
    {"ln", log},
    {"exp", exp},
    {"sqrt", sqrt},
    {"max", {.fnc2 = max}},
    {"min", {.fnc2 = min}},
    {0, 0}
};

/* The symbol table: a chain of `struct symrec' */
symrec *sym_table;

/* Put arithmetic functions in table */
void init_table (void) {
    int i;
    for (i=0; arith_fncts[i].fname != 0; i++) {
        symrec *ptr = putsym (arith_fncts[i].fname, FNCT);
        if (i <= 5) {
            ptr->value.fnctptr = arith_fncts[i].fnct.fnc1;
        } else {
            ptr->value.fncpptr = arith_fncts[i].fnct.fnc2;
        }
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

double max (params p) {
    if (p.first < p.second)
        return p.second;
    else
        return p.first;
}

double min (params p) {
    if (p.first > p.second)
        return p.second;
    else
        return p.first;
}
