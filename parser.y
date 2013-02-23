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
    stack stk;
}

%token <val> NUM STR /* Simple double precision number */
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
            | genericexp STOP { printf ( "[%d] >>> %.10g\n", s->top, $1 ); clear_stack(); }
            | error STOP { yyerrok; }
;

genericexp  : basicexp
            | FNCT LP basicexp RP  { $$ = (*($1->value.fnctptr))($3); }
            | FNCP LP csv RP       { $$ = (*($1->value.fncpptr))(s); }
;

basicexp    : NUM                      { $$ = $1; }
            | VAR                      { $$ = $1->value.var; }
            | VAR EQ basicexp          { $$ = $3; $1->value.var = $3; }
            | basicexp PLUS basicexp   { $$ = $1 + $3; }
            | basicexp MINUS basicexp  { $$ = $1 - $3; }
            | basicexp TIMES basicexp  { $$ = $1 * $3; }
            | basicexp OVER basicexp   { $$ = $1 / $3; }
            | basicexp TO basicexp     { $$ = pow ($1, $3); }
            | LP basicexp RP           { $$ = $2; }
;

csv         : basicexp           { push(NUM, $1); }
            | csv COMMA basicexp { push(NUM, $3); }
;

/* End of grammar */
%%

/* Called by yyparse on error. */
void yyerror( char const *s ) {
    fprintf( stderr, "mfcalc: %s\n", s );
}

struct init {
    char const *fname;
    union {
        double (*fnc1) (double);
        double (*fnc2) (stack *);
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
        if (i <= 5) {
            symrec *ptr = putsym (arith_fncts[i].fname, FNCT);
            ptr->value.fnctptr = arith_fncts[i].fnct.fnc1;
        } else {
            symrec *ptr = putsym (arith_fncts[i].fname, FNCP);
            ptr->value.fncpptr = arith_fncts[i].fnct.fnc2;
        }
    }
}

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

/*Function to add an element to the stack*/
void push (int type, double val) {
    if (s->top == (MAXSIZE - 1)) {
        return;
    } else {
        switch (type) {
            //case STR:
            //    s = putitem (s->top+1, STR);
            //    strcpy(s->value.string, val.string);
            //    break;
            case NUM:
                s = putitem (s->top+1, NUM);
                s->value.number = val;
                break;
            default:
                break;
        }
    }
    return;
}

/*Function to delete an element from the stack*/
int pop () {
    int type;
    if (s->top == -1) {
        return (s->top);
    } else {
        type = s->type;
        //if (type == STR)
            //printf ("poped element is = %s\n", s->value.string);
        //else if (type == NUM)
            //printf ("poped element is = %.10g\n", s->value.number);
        s = s->next;
    }
    return s->top;
}

/*Function to display the status of the stack*/
void display () {
    int i, type;
    if (s->top == -1) {
        //printf ("Stack is empty\n");
        return;
    } else {
        //printf ("\nThe status of the stack is\n");
        for (i = s->top; i >= 0; i--) {
            stack *ptr = getitem (i);
            type = ptr->type;
            if (type == STR)
                printf ("%s\n", ptr->value.string);
            else if (type == NUM)
                printf ("%.10g\n", ptr->value.number);
        }
    }
    printf ("\n");
}

/* Function to put a stack item */
stack * putitem (int top, int type) {
    stack *ptr = getitem (top);
    if (ptr == 0) {
        ptr = (stack*) malloc (sizeof (stack));
    }
    ptr->top = top;
    ptr->type = type;
    ptr->next = s;
    s = ptr;
    return ptr;
}

/* Function to get a stack item */
stack * getitem (int top) {
    stack *ptr;
    for (ptr = s; ptr != (stack *) 0; ptr = (stack *) ptr->next) {
        if (ptr->top == top) {
            return ptr;
        }
    }
    return 0;
}

/* Function to clear the stack */
void clear_stack () {
    int i, j;
    for (i = s->top; i>=0; i--) {
        pop ();
    }
    return;
}

double max (stack *p) {
    int i, max;
    max = s->value.number;
    for (i=s->top; i>=1; i--) {
        if (max < s->next->value.number )
            max = s->next->value.number;
        pop ();
    }
    return max;
}

double min (stack *p) {
    int i, min;
    min = s->value.number;
    for (i=s->top; i>=1; i--) {
        if (min > s->next->value.number )
            min = s->next->value.number;
        pop ();
    }
    return min;
}
