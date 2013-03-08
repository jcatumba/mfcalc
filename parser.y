%{
    #include "parser.h"
    #include <math.h>
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <ctype.h>
    #define YYDEBUG 1
    #define YYPRINT(file, type, value) yyprint(file, type, value)
    int yylex(void);
    void yyerror(char const*s);
    void yyprint();
    void put_output (datatype);
    datatype num_to_datatype (double);
    datatype str_to_datatype (char[50]);
    datatype do_arith (datatype, datatype, int);
%}

%union {
    datatype val;
    char sym;
    symrec *tptr;
}

%token <val> NUM STR /* Simple double precision number */
%token <sym> LP RP LS RS LB RB COMMA COLON PLUS MINUS TIMES OVER EQ TO STOP
%token <tptr> VAR FNCT FNCP /* Variable and functions */
%type <val> basic hashable

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
            | basic STOP { put_output ($1); clear_stack(); }
            | error STOP { yyerrok; }
            ;

hashable    : NUM           { double num = $1.data.num; $$ = num_to_datatype (num); }
            | STR           { char *str = $1.data.str; $$ = str_to_datatype (str); }
            ;

basic       : hashable
            | VAR                { $$ = $1->value.var; }
            | VAR EQ basic       { $$ = $3; $1->value.var = $3; }
            | FNCT LP basic RP   { $$.data.num = (*($1->value.fnctptr))($3.data.num); $$.type = NUM; }
            | FNCP LP csv RP     { $$.data.num = (*($1->value.fncpptr))(s); $$.type = NUM; }
            | basic PLUS basic   { $$ = do_arith ($1, $3, PLUS); }
            | basic MINUS basic  { $$ = do_arith ($1, $3, MINUS); }
            | basic TIMES basic  { $$ = do_arith ($1, $3, TIMES); }
            | basic OVER basic   { $$ = do_arith ($1, $3, OVER); }
            | basic TO basic     { $$ = do_arith ($1, $3, TO); }
            | LP basic RP        { $$.data.num = $2.data.num; $$.type = NUM; }
            ;

csv         : basic           { push ($1); }
            | csv COMMA basic { push ($3); }
            ;

/* End of grammar */
%%

/* Called by yyparse on error. */
void yyerror( char const *s ) {
    fprintf( stderr, "mfcalc: %s\n", s );
}

void yyprint(FILE *file, int type, YYSTYPE value) {
    if (type == VAR)
        fprintf(file, " %s", value.tptr->name);
    else if (type == NUM)
        fprintf(file, " %g", value.val);
}

void put_output (datatype val) {
    int type = val.type;
    switch (type) {
        case NUM:
            printf (">>> %.10g\n", val.data.num);
            break;
        case STR:
            printf (">>> %s\n", val.data.str);
        default:
            break;
    }
    clear_stack ();
}

datatype do_arith (datatype one, datatype two, int operator) {
    datatype result;
    if (one.type == NUM && two.type == NUM ) {
        switch (operator) {
            case PLUS:
                result.data.num = one.data.num + two.data.num;
                break;
            case MINUS:
                result.data.num = one.data.num - two.data.num;
                break;
            case TIMES:
                result.data.num = one.data.num * two.data.num;
                break;
            case OVER:
                result.data.num = one.data.num / two.data.num;
                break;
            case TO:
                result.data.num = pow (one.data.num, two.data.num);
        }
        result.type = NUM;
    } else if (one.type == STR && two.type == STR) {
        switch (operator) {
            case PLUS:
                strcpy (result.data.str, one.data.str);
                strcat (result.data.str, two.data.str);
                break;
            default:
                strcpy(result.data.str, "Incorrect types on operands.");
                break;
        }
        result.type = STR;
    }
    return result;
}

datatype num_to_datatype (double num) {
    datatype ptr;
    ptr.type = NUM;
    ptr.data.num = num;
    return ptr;
}

datatype str_to_datatype (char str[50]) {
    datatype ptr;
    ptr.type = STR;
    strcpy(ptr.data.str, str);
    return ptr;
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
    ptr->value.var.data.num = 0; /* Set value to 0 even if fctn */
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

/*Function to add an element to the stack*/
void push (datatype val) {
    if (s->top == (MAXSIZE - 1)) {
        return; /* stack is full */
    } else {
        switch (val.type) {
            case STR:
                s = putitem (s->top+1, STR);
                strcpy(s->value.string, val.data.str);
                break;
            case NUM:
                s = putitem (s->top+1, NUM);
                s->value.number = val.data.num;
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
        return (s->top); /* stack is empty */
    } else {
        type = s->type;
        s = s->next;
    }
    return s->top;
}

/*Function to display the status of the stack*/
void display () {
    int i, type;
    if (s->top == -1) {
        return; /* stack is empty */
    } else {
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

/* Function to clear the stack */
void clear_stack () {
    int i, j;
    for (i = s->top; i>=0; i--)
        pop ();
    return;
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

double max (stack *p) {
    int i;
    double max;
    max = s->value.number;
    for (i=s->top; i>=1; i--) {
        if (max < s->next->value.number )
            max = s->next->value.number;
        pop ();
    }
    return max;
}

double min (stack *p) {
    int i;
    double min;
    min = s->value.number;
    for (i=s->top; i>=1; i--) {
        if (min > s->next->value.number )
            min = s->next->value.number;
        pop ();
    }
    return min;
}
