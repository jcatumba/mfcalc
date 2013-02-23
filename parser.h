#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAXSIZE 10 /* change to use dynamic size */

/* Params type */
typedef  struct {
    double first;
    double second;
} params;

/* Stacks */

/* Union definition for data */
typedef union {
    double number;
    char string[16];
} data;

 /* Structure definition for stack */
struct stack {
    int top;
    int type; /* type of element on stack VAR, STR */
    data value;
    struct stack *next;
};

typedef struct stack stack;
stack *s;

/* Function type.  */
typedef double (*func_t) (double);
typedef double (*func_p) (stack *);
     
/* Data type for links in the chain of symbols.  */
struct symrec
{
    char *name;  /* name of symbol */
    int type;    /* type of symbol: either VAR or FNCT */
    union
    {
      double var;      /* value of a VAR */
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
void push (int, double);
int pop (void);
void display (void);

/* Functions to handle stack structs */
stack * putitem (int, int);
stack * getitem (int);
void clear_stack (void);

/* The functions with two parameters */
double max (stack *);
double min (stack *);
