#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAXSIZE 10 /* change to use dynamic size */

/* Stacks */

/* Union definition for data */
typedef union {
    double number;
    char string[50];
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

typedef union {
    double num;
    char str[50];
} varval;

typedef struct {
    int type; /* Type of data: NUM or STR */
    varval data;
} datatype;

/* Data type for links in the chain of symbols.  */
struct symrec {
    char *name;  /* name of symbol */
    int type;    /* type of symbol: either VAR or FNCT */
    union {
      datatype var;      /* value of a VAR */
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
void push (datatype);
int pop (void);
void display (void);
void clear_stack (void);

/* Functions to handle stack structs */
stack * putitem (int, int);
stack * getitem (int);

/* The functions with two parameters */
double max (stack *);
double min (stack *);
