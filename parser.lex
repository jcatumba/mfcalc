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
all     [[:alnum:][:blank:]]
ls      `\x5b'
rs      `\x5d'
%%

{long}         { yylval.val.value.num = atof (yytext); return NUM; }
"+"            { yylval.sym = yytext[0]; return PLUS; }
"-"            { yylval.sym = yytext[0]; return MINUS; }
"*"            { yylval.sym = yytext[0]; return TIMES; }
"/"            { yylval.sym = yytext[0]; return OVER; }
"^"            { yylval.sym = yytext[0]; return TO; }
"="            { yylval.sym = yytext[0]; return EQ; }
'{all}*'       { strcpy(yylval.val.value.str, yytext); return STR; }
\"{all}*\"     { strcpy(yylval.val.value.str, yytext); return STR; }
{char}+        { symrec *sym = getsym (yytext); if (sym==0) sym = putsym(yytext, VAR) ; yylval.tptr = sym; return sym->type; }
{ls}           { return LS; }
{rs}           { return RS; }
"("            { return LP; }
")"            { return RP; }
"{"            { return LB; }
"}"            { return RB; }
","            { return COMMA; }
":"            { return COLON; }
[ \t]+         { }
"\n"           { return STOP; }

%%
