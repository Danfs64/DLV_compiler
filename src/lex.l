%option yylineno

%{
    /* manifest constants */
AND, BREAK, DO, ELSE, ELSEIF, END, FALSE, FOR, FUNCTION, GOTO, IF, IN, LOCAL,
NIL, NOT, OR, REPEAT, RETURN, THEN, TRUE, UNTIL, WHILE,

PLUS, MINUS, TIMES, OVER, MOD, POW, LEN, BAND, BNOT, BAND, SHL, SHR, IOVER, EQ,
NEQ, LE, GE, LT, GT, ASSIGN, LPAR, RPAR, LCUR, RCUR, LBCK, RBCK, DCOL, SCOL,
COL, COM, DOT, CAT, VARG, UNDS
%}

    /* From Lua 5.3 manual:
    A numeric constant (or numeral) can be written with an optional fractional
    part and an optional decimal exponent, marked by a letter 'e' or 'E'. Lua also
    accepts hexadecimal constants, which start with 0x or 0X. Hexadecimal constants
    also accept an optional fractional part plus an optional binary exponent, marked
    by a letter 'p' or 'P'. A numeric constant with a radix point or an exponent
    denotes a float; otherwise, if its value fits in an integer, it denotes an
    integer. */

int          [[:digit:]]+
hexint       0(x|X)[[:xdigit:]]+

floatd_1     [[:digit:]]+\.
floatd_2     \.[[:digit:]]+
floatd_3     [[:digit:]]+\.[[:digit:]]+
floatd       ({floatd_1}|{floatd_2}|{floatd_3})((e|E)(-|\+)?{int})?

floatx_1     0(x|X)[[:xdigit]]+.
floatx_2     0(x|X).[[:xdigit:]]+
floatx_3     0(x|X)[[:xdigit:]]+.[[:xdigit:]]+
floatx       ({floatx_1}|{floatx_2}|{floatx_3})((p|P)(-|\+)?{int})?

float        {floatd}|{floatx}

llongbracket \[=*\[
rlongbracket \]=*\]

id           [[:alpha:]_][[:alnum:]_]*
goto_label   ::{id}::
string       \"[^\"\n]*\"|'[^'\n]+'|{llongbracket}[^\[\]]{rlongbracket}

comment      --.*|--{llongbracket}(.|\n)*{rlongbracket}
ignore       [[:space:]]+

%%

{ignore}  {}
{comment} {}

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
"|"   return BAND;
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
"_"   return UNDS;

