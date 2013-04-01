%{
    #include "parser.h"
    #include <math.h>
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <ctype.h>
    #define YYDEBUG 1
    #define YYPRINT(file, type, value) yyprint(file, type, value)
    int yylex (void);
    void yyerror (char const*s);
    void yyprint ();
    void put_output (typed);
    void print_tuple (tuple *);
    typed num_to_typed (double);
    typed str_to_typed (char[50]);
    typed do_arith (typed, typed, int);
%}

%union {
    typed val;
    char sym;
    stack *stk;
    symrec *tptr;
}

%token <val> NUM STR TPL /* Simple double precision number */
%token <sym> LP RP LS RS LB RB COMMA COLON PLUS MINUS TIMES OVER EQ TO STOP
%token <tptr> VAR FNCT FNCP /* Variable and functions */
%type <val> basic hashable tuple
%type <stk> csv

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
            | basic STOP { printf (">>> "); put_output ($1); printf ("\n"); clear_stack (); }
            | error STOP { yyerrok; clear_stack(); }
            ;

hashable    : NUM           { double num = $1.value.num; $$ = num_to_typed (num); }
            | STR           { char *str = $1.value.str; $$ = str_to_typed (str); }
            | tuple
            ;

basic       : hashable
            | VAR                { $$ = $1->value.var; }
            | VAR EQ basic       { $$ = $3; $1->value.var = $3; }
            | FNCT tuple         {
                                     if ($2.value.tup->pos == 0 && $2.value.tup->value.type == NUM) {
                                        $$.value.num = (*($1->value.fnctptr))($2.value.tup->value.value.num);
                                        $$.type = NUM;
                                     } else {
                                        strcpy ($$.value.str, "Something went wrong (not a number).");
                                        $$.type = STR;
                                     }
                                 }
            | FNCP tuple         { $$.value.num = (*($1->value.fncpptr))($2); $$.type = NUM; }
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

tuple       : LP RP         { tuple *t = (tuple *) 0; $$.value.tup = t; $$.type = TPL; }
            | LP csv RP     { tuple *t = csv_to_tuple (s); $$.value.tup = t; $$.type = TPL; }
            ;
/* End of grammar */
%%

/* Called by yyparse on error. */
void yyerror ( char const *s ) {
    fprintf ( stderr, "mfcalc: %s\n", s );
}

void yyprint(FILE *file, int type, YYSTYPE value) {
    if (type == VAR)
        fprintf (file, " %s", value.tptr->name);
    else if (type == NUM)
        fprintf (file, " %g", value.val);
}

//
// Parser functions
//

void put_output (typed val) {
    switch (val.type) {
        case NUM:
            printf ("%.10g", val.value.num);
            break;
        case STR:
            printf ("%s", val.value.str);
            break;
        case TPL:
            print_tuple (val.value.tup);
            break;
        default:
            break;
    }
}

void print_tuple (tuple *the_tuple) {
    tuple *ptr;
    printf ("(");
    for (ptr = the_tuple; ptr != (tuple *) 0; ptr = (tuple *) ptr->next) {
        put_output (ptr->value);
        if (ptr->next != (tuple *) 0)
            printf (",");
    }
    printf (")");
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
        double (*fnc2) (typed);
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

//
// Functions for symbols on chain
//

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

//
// Functions to handle stacks
//

void push (typed val) {
    if (s->top == (MAXSIZE - 1)) {
        return; /* stack is full */
    } else {
        s = putitem (s->top+1, val.type);
        s->value = val;
        /*switch (val.type) {
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
        }*/
    }
    return;
}

int pop () {
    if (s->top == -1) {
        return (s->top); /* stack is empty */
    } else {
        s = s->next;
    }
    return s->top;
}

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
            else if (type == TPL) {
                print_tuple (ptr->value.value.tup);
                printf("\n");
            }
        }
    }
    printf ("\n");
}

void clear_stack () {
    int i;
    for (i = s->top; i>=0; i--)
        pop ();
    return;
}

/* Function to put a stack item */
stack * putitem (int top, int type) {
    stack *ptr = getitem (top);
    if (ptr == (stack *) 0)
        ptr = (stack*) malloc (sizeof (stack));
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
        if (ptr->top == top)
            return ptr;
    }
    return (stack *) 0;
}

//
// Functions to manipulate tuples
//

tuple * put_tuple_item (int pos, typed data, tuple *the_tuple) {
    tuple *ptr = get_tuple_item (pos, the_tuple);
    if (ptr == (tuple *) 0)
        ptr = (tuple*) malloc (sizeof (tuple));
    ptr->pos = pos;
    ptr->value = data;
    ptr->next = the_tuple;
    the_tuple = ptr;
    return ptr;
}

tuple * get_tuple_item (int pos, tuple *the_tuple) {
    tuple *ptr;
    for (ptr = the_tuple; ptr != (tuple *) 0; ptr = (tuple *) ptr->next) {
        if (ptr->pos == pos)
            return ptr;
    }
    return (tuple *) 0;
}

tuple * csv_to_tuple (stack *the_stack) {
    tuple *t = (tuple*) 0;
    if (the_stack->top == -1)
        return NULL; /* the_stack is empty */
    else {
        stack *stk;
        for (stk = the_stack; stk != (stack *) 0; stk = (stack *) stk->next) {
            t = put_tuple_item (stk->top, stk->value, t);
            if (t->next != (tuple *) 0)
                t->next->prev = t;
            if (t->pos == 0)
                t->prev = (tuple *) 0;
        }
    }
    return t->next;
}

//
// Other functions
//

double max (typed p) {
    tuple *tp;
    double max = p.value.tup->value.value.num;
    for (tp = p.value.tup; tp != (tuple *) 0; tp = (tuple *) tp->next) {
        if ( tp->next != (tuple *) 0 ) {
            if (max < tp->next->value.value.num )
                max = tp->next->value.value.num;
        }
    }
    return max;
}

double min (typed p) {
    tuple *tp;
    double min = p.value.tup->value.value.num;
    for (tp = p.value.tup; tp != (tuple *) 0; tp = (tuple *) tp->next) {
        if ( tp->next != (tuple *) 0 ) {
            if (min > tp->next->value.value.num )
                min = tp->next->value.value.num;
        }
    }
    return min;
}
