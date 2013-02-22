/* Params type */
typedef  struct {
    double first;
    double second;
} params;

/* Function type.  */
typedef double (*func_t) (double);
typedef double (*func_p) (params);
     
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

/* The functions with two parameters */
double max (params);
double min (params);
