%option outfile="scanner.c"
%option yylineno
%option noyywrap

%{
#include <string.h>
#include "parser.h"

int n_equals = 0;
char strbuf[8192] = {0};
char inline_string_delimiter;

int strnequals() {
    int n = 0;
    char *ptr = yytext;
    while(*ptr) {
        n += *ptr == '=';
        ptr++;
    }
    return n;
}

 /*
void process_token(const char* tok) {
    printf("%d: %s -> %s\n", yylineno, yytext, yytok);
}
 */

    /* manifest constants */
%}

    /* From Lua 5.3 manual:
    A numeric constant (or numeral) can be written with an optional fractional
    part and an optional decimal exponent, marked by a letter 'e' or 'E'. Lua also
    accepts hexadecimal constants, which start with 0x or 0X. Hexadecimal constants
    also accept an optional fractional part plus an optional binary exponent, marked
    by a letter 'p' or 'P'. A numeric constant with a radix point or an exponent
    denotes a float; otherwise, if its value fits in an integer, it denotes an
    integer. */

hexint       0(x|X)[[:xdigit:]]+
decint       [[:digit:]]+
int          {decint}|{hexint}

floatd_1     {decint}\.
floatd_2     \.{decint}
floatd_3     {decint}\.{decint}
floatd_4     {decint}([eE](-|\+)?{decint})
floatd       ({floatd_1}|{floatd_2}|{floatd_3})([eE][-+]?{decint})?|{floatd_4}

floatx_1     {hexint}\.
floatx_2     0(x|X)\.[[:xdigit:]]+
floatx_3     0(x|X)[[:xdigit:]]+\.[[:xdigit:]]+
floatx_4     {hexint}([pP](-|\+)?{decint})
floatx       ({floatx_1}|{floatx_2}|{floatx_3})([pP][-+]?{decint})?|{floatx_4}

float        {floatd}|{floatx}

id           [[:alpha:]_][[:alnum:]_]*
goto_label   ::{id}::
string       \"[^\"\n]*\"|'[^'\n]*'

ignore       [[:space:]]+

%x COMMENT
%x LB_COMMENT
%x INLINE_COMMENT
%x LB_STRING

%%

{ignore}  {}
"--"      {strcpy(strbuf, yytext); BEGIN(COMMENT);}

<COMMENT>{
\[=*\[     {n_equals=strnequals(); BEGIN(LB_COMMENT);}
  /* Line comment */
[^\[]      {BEGIN(INLINE_COMMENT);}
\[/[^=\[]  {BEGIN(INLINE_COMMENT);}
\[=*/[^\[] {BEGIN(INLINE_COMMENT);}
}

<INLINE_COMMENT>.*\n  {
    //strcat(strbuf, yytext);
    //printf("Comment: %s\n", strbuf);
    BEGIN(INITIAL);
}

<LB_COMMENT>{
\]=*\]  {
        //strcat(strbuf, yytext);
        if (strnequals() == n_equals) {
            //printf("Comment: %s\n", strbuf);
            BEGIN(INITIAL);
        }
    }
[^\]\n]*  {}
"]"       {}
\n        {}
} 

and      return AND;
break    return BREAK;
do       return DO;
else     return ELSE;
elseif   return ELSEIF;
end      return END;
false    return FALSE;
for      return FOR;
function return FUNCTION;
goto     return GOTO;
if       return IF;
in       return IN;
local    return LOCAL;
nil      return NIL;
not      return NOT;
or       return OR;
repeat   return REPEAT;
return   return RETURN;
then     return THEN;
true     return TRUE;
until    return UNTIL;
while    return WHILE;

"+"   return PLUS;
"-"   return MINUS;
"*"   return TIMES;
"/"   return OVER;
"%"   return MOD;
"^"   return POW;
"#"   return LEN;
"&"   return BAND;
"~"   return BNOT;
"|"   return BOR;
"<<"  return SHL;
">>"  return SHR;
"//"  return IOVER;
"=="  return EQ;
"~="  return NEQ;
"<="  return LE;
">="  return GE;
"<"   return LT;
">"   return GT;
"="   return ASSIGN;
"("   return LPAR;
")"   return RPAR;
"{"   return LCUR;
"}"   return RCUR;
"["   return LBCK;
"]"   return RBCK;
"::"  return DCOL;
";"   return SCOL;
":"   return COL;
","   return COM;
"."   return DOT;
".."  return CAT;
"..." return VARG;

{float}  return FLOATCONST; //printf("float: %s\n", yytext);
{int}    return INTCONST;   //printf("int: %s\n", yytext);

  /* Inline strings */
{string}  return STRINGCONST; //printf("string: %s\n", yytext); 

\[=*\[ {
    n_equals=strnequals();
    strcpy(strbuf, yytext);
    BEGIN(LB_STRING);
}
<LB_STRING>{
\]=*\]    {
        strcat(strbuf, yytext);
        if (strnequals() == n_equals) {
            BEGIN(INITIAL);
            return STRINGCONST; //printf("string: %s\n", strbuf);
        }
    }
[^\]\n]*  {strcat(strbuf, yytext);}
"]"       {strcat(strbuf, yytext);}
\n        {strcat(strbuf, yytext);}
} 

{id}  return IDENTIFIER; //printf("id: %s\n", yytext);

.   {
    printf("LEXICAL ERROR (%d): Unknown symbol %s\n", yylineno, yytext);
    exit(EXIT_FAILURE);
}
