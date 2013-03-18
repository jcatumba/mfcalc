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
    void put_output (typed);
    typed num_to_typed (double);
    typed str_to_typed (char[50]);
    typed do_arith (typed, typed, int);
%}

%union {
    typed val;
    char sym;
    symrec *tptr;
}

%token <val> NUM STR /* Simple double precision number */
%token <sym> LP RP LS RS LB RB COMMA COLON PLUS MINUS TIMES OVER EQ TO STOP
%token <tptr> VAR FNCT FNCP /* Variable and functions */
%type <val> basic hashable tuple

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

hashable    : NUM           { double num = $1.value.num; $$ = num_to_typed (num); }
            | STR           { char *str = $1.value.str; $$ = str_to_typed (str); }
            | tuple
            ;

basic       : hashable
            | VAR                { $$ = $1->value.var; }
            | VAR EQ basic       { $$ = $3; $1->value.var = $3; }
            | FNCT tuple         { $$.value.num = (*($1->value.fnctptr))($2.value.num); $$.type = NUM; }
            | FNCP tuple         { $$.value.num = (*($1->value.fncpptr))(s); $$.type = NUM; }
            | basic PLUS basic   { $$ = do_arith ($1, $3, PLUS); }
            | basic MINUS basic  { $$ = do_arith ($1, $3, MINUS); }
            | basic TIMES basic  { $$ = do_arith ($1, $3, TIMES); }
            | basic OVER basic   { $$ = do_arith ($1, $3, OVER); }
            | basic TO basic     { $$ = do_arith ($1, $3, TO); }
            | LP basic RP        { $$.value.num = $2.value.num; $$.type = NUM; }
            ;

csv         : basic           { push ($1); }
            | csv COMMA basic { push ($3); }
            ;

tuple       : LP RP         { $$.value.num = 0; }
            | LP csv RP     { $$.value.num = 0; }
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

void put_output (typed val) {
    int type = val.type;
    switch (type) {
        case NUM:
            printf (">>> %.10g\n", val.value.num);
            break;
        case STR:
            printf (">>> %s\n", val.value.str);
        default:
            break;
    }
    clear_stack ();
}

typed do_arith (typed one, typed two, int operator) {
    typed result;
    if (one.type == NUM && two.type == NUM ) {
        switch (operator) {
            case PLUS:
                result.value.num = one.value.num + two.value.num;
                break;
            case MINUS:
                result.value.num = one.value.num - two.value.num;
                break;
            case TIMES:
                result.value.num = one.value.num * two.value.num;
                break;
            case OVER:
                result.value.num = one.value.num / two.value.num;
                break;
            case TO:
                result.value.num = pow (one.value.num, two.value.num);
                break;
        }
        result.type = NUM;
    } else if (one.type == STR && two.type == STR) {
        switch (operator) {
            case PLUS:
                strcpy (result.value.str, one.value.str);
                strcat (result.value.str, two.value.str);
                break;
            default:
                strcpy(result.value.str, "Incorrect types on operands.");
                break;
        }
        result.type = STR;
    }
    return result;
}

typed num_to_typed (double num) {
    typed ptr;
    ptr.type = NUM;
    ptr.value.num = num;
    return ptr;
}

typed str_to_typed (char str[50]) {
    typed ptr;
    ptr.type = STR;
    strcpy(ptr.value.str, str);
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
    ptr->value.var.value.num = 0; /* Set value to 0 even if fctn */
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

/* Function to add an element to the stack */
void push (typed val) {
    if (s->top == (MAXSIZE - 1)) {
        return; /* stack is full */
    } else {
        switch (val.type) {
            case STR:
                s = putitem (s->top+1, STR);
                strcpy(s->value.value.str, val.value.str);
                break;
            case NUM:
                s = putitem (s->top+1, NUM);
                s->value.value.num = val.value.num;
                break;
            default:
                break;
        }
    }
    return;
}

/* Function to delete an element from the stack */
int pop () {
    //int type;
    if (s->top == -1) {
        return (s->top); /* stack is empty */
    } else {
        //type = s->type;
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
            type = ptr->value.type;
            if (type == STR)
                printf ("%s\n", ptr->value.value.str);
            else if (type == NUM)
                printf ("%.10g\n", ptr->value.value.num);
        }
    }
    printf ("\n");
}

/* Function to clear the stack */
void clear_stack () {
    int i;
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
    ptr->value.type = type;
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
    //double max;
    double max = p->value.value.num;
    for (i=p->top; i>=1; i--) {
        if (max < p->next->value.value.num )
            max = p->next->value.value.num;
        pop ();
    }
    return max;
}

double min (stack *p) {
    int i;
    double min;
    min = p->value.value.num;
    for (i=p->top; i>=1; i--) {
        if (min > p->next->value.value.num )
            min = p->next->value.value.num;
        pop ();
    }
    return min;
}
