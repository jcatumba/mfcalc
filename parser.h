#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAXSIZE 10 /* change to use more or less size */

typedef struct tuple tuple;

//
// Stacks
//

typedef union {
    double num;
    char str[50];
    tuple *tup;
} data;

typedef struct {
    int type;
    data value;
} typed;

/* Structure definition for stack */
struct stack {
    int top;
    typed value;
    struct stack *next;
};

typedef struct stack stack;
stack *s;

//
// Tuples
//

struct tuple {
    int pos;
    typed value;
    tuple *next;
    tuple *prev;
};

/* Function type.  */
typedef double (*func_t) (double);
typedef double (*func_p) (typed);

//
// Symrec (chain of symbols)
//

/* Data type for links in the chain of symbols. (Holds functions and variables) */
struct symrec {
    char *name;  /* name of symbol */
    int type;    /* type of symbol: either VAR or FNCT or FNCP */
    union {
      typed var;  /* value of a VAR */
      func_t fnctptr;  /* value of a FNCT */
      func_p fncpptr;  /* value of a FNCP */
    } value;
    struct symrec *next;  /* link field */
};
     
typedef struct symrec symrec;
     
/* The symbol table: a chain of `struct symrec'.  */
extern symrec *sym_table;
     
symrec *putsym (char const *, int);
symrec *getsym (char const *);

/* Functions for add to stack */
void push (typed, stack*);
int pop (stack *);
void display (stack*);
void clear_stack (stack*);

/* Functions to handle stack structs */
stack * putitem (int, int, stack*);
stack * getitem (int, stack*);

/* Functions to handle tuples */
tuple * put_tuple_item (int, typed, tuple*);
tuple * get_tuple_item (int, tuple*);
tuple * csv_to_tuple (stack *);

/* The functions with two parameters */
double max (typed);
double min (typed);
