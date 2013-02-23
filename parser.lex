%{
    #include "parser.h"
    #include "parser.tab.h"
    #include <stdio.h>
%}

%option noyywrap

digit   [0-9]
posint  {digit}+
int     "-"?{posint}
long    {int}(""|("."{posint}))

char    [a-zA-z]
%%

{long}         { yylval.val = atof(yytext); return NUM; }
"+"            { yylval.sym = yytext[0]; return PLUS; }
"-"            { yylval.sym = yytext[0]; return MINUS; }
"*"            { yylval.sym = yytext[0]; return TIMES; }
"/"            { yylval.sym = yytext[0]; return OVER; }
"^"            { yylval.sym = yytext[0]; return TO; }
"="            { yylval.sym = yytext[0]; return EQ; }
{char}+        { symrec *sym = getsym(yytext); if (sym==0) sym = putsym(yytext, VAR) ; yylval.tptr = sym; return sym->type; }
"("            { return LP; }
")"            { return RP; }
","            { return COMMA; }
[ \t]+         { }
"\n"           { return STOP; }

%%
