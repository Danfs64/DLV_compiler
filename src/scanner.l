%option outfile="scanner.cc"
%option yylineno
%option noyywrap

%{
#include <string_view>
#include "parser.hpp"
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

string_dq    \"(\\.|[^\\"\n]|\\\n|\\z[ \n]*)*\"
   /* '[^'\n]*' */
string_sq    '(\\.|[^\\'\n]|\\\n|\\z[ \n]*)*'   
string       {string_dq}|{string_sq}

ignore       [[:space:]]+

%x COMMENT
%x LB_COMMENT
%x INLINE_COMMENT
%x LB_STRING
%x SHEBANG

%%

<SHEBANG>{
#.*\n   {BEGIN(INITIAL);}
.       {char c = *yytext; unput(c); BEGIN(INITIAL);}
}

{ignore}  {}
--      {BEGIN(COMMENT);}
--\n    {}

<COMMENT>{
\[=*\[       {yymore(); BEGIN(LB_COMMENT);}
    /* Line comment */
\n           {BEGIN(INLINE_COMMENT);}
.            {yymore(); BEGIN(INLINE_COMMENT);}
}

<INLINE_COMMENT>{
.*\n    {BEGIN(INITIAL);}
}

<LB_COMMENT>{
\]=*\]  {
        const std::string_view str {yytext};
        int sz1 = 0, sz2 = 0;
        for (int i = 1; str[i] != '['; ++i) {
            ++sz1;
        }
        for (int i = str.size() - 2; str[i] != ']'; --i) {
            ++sz2;
        }
        if (sz1 == sz2) {
            BEGIN(INITIAL);
        } else {
            unput(']');
            yymore();
        }
    }
        /* [^\]\n]*  {yymore();} */
        /* "]"       {yymore();} */
        /* \n        {yymore();} */
.|\n    {yymore();}
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
    yymore();
    BEGIN(LB_STRING);
}
<LB_STRING>{
\]=*\]    {
        const std::string_view str {yytext};
        int sz1 = 0, sz2 = 0;
        for (int i = 1; str[i] != '['; ++i) {
            ++sz1;
        }
        for (int i = str.size() - 2; str[i] != ']'; --i) {
            ++sz2;
        }
        if (sz1 == sz2) {
            BEGIN(INITIAL);
            return STRINGCONST; //printf("string: %s\n", strbuf);
        } else {
            unput(']');
            yymore();
        }
    }
.|\n      {yymore();}
} 

{id}  return IDENTIFIER; //printf("id: %s\n", yytext);

.   {
    printf("LEXICAL ERROR (%d): Unknown symbol %s\n", yylineno, yytext);
    exit(EXIT_FAILURE);
}


%%

void init_shebang() {
    BEGIN(SHEBANG);
}
