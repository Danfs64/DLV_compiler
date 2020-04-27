%output "parser.c"
%defines "parser.h"
%define parse.error verbose
%define parse.lac full
%debug

%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
void yyerror();

extern int yylineno;
extern int yy_flex_debug;
%}

%token	IDENTIFIER STRINGCONST INTCONST FLOATCONST
%token	AND "and" BREAK "break" DO "do" ELSE "else" ELSEIF "elseif" END "end"
%token	FALSE "false" FOR "for" FUNCTION "function" GOTO "goto" IF "if" IN "in"
%token	LOCAL "local" NIL "nil" NOT "not" OR "or" REPEAT "repeat"
%token  RETURN "return" THEN "then" TRUE "true" UNTIL "until" WHILE "while"
%token	PLUS "+" MINUS "-" TIMES "*" OVER "/" MOD "%" POW "^" LEN "#" BAND "&"
%token	BNOT "~" BOR "|" SHL "<<" SHR ">>" IOVER "//" EQ "==" NEQ "~=" LE "<="
%token	GE ">=" LT "<" GT ">" ASSIGN "=" LPAR "(" RPAR ")" LCUR "{" RCUR "}"
%token	LBCK "[" RBCK "]" DCOL "::" SCOL ";" COL ":" COM "," DOT "." CAT ".."
%token	VARG "..."


%left   "or"
%left   "and"
%left   "<" ">" "<=" ">=" "~=" "=="
%left   "|"
%left   "~"
%left   "&"
%left   "<<" ">>"
%right  ".."
%left   "+" "-"
%left   "*" "/" "//" "%"
%left   "not" "#" 
%right  "^"

%nonassoc "("

%%

chunk:            block
;

block:            stat block
|                 retstat
|                 %empty
;

stat:             ";"
|                 varlist "=" explist
|                 functioncall
|                 label
|                 "break"
|                 "goto" IDENTIFIER
|                 "do" block "end"
|                 "while" exp "do" block "end"
|                 "repeat" block "until" exp
|                 if_stmt
|                 for_stmt
|                 "function" funcname funcbody
|                 "local" "function" IDENTIFIER funcbody
|                 "local" namelist
|                 "local" namelist "=" explist
;

if_stmt:          "if" exp "then" block "end"
|                 "if" exp "then" block "else" block "end"
|                 "if" exp "then" block elseif_stmt "end"
|                 "if" exp "then" block elseif_stmt "else" block "end"
;

elseif_stmt:      elseif_stmt "elseif" exp "then" block
|                 "elseif" exp "then" block
;

for_stmt:         "for" IDENTIFIER "=" exp "," exp "do" block "end"
|                 "for" IDENTIFIER "=" exp "," exp "," exp "do" block "end"
|                 "for" namelist "in" explist "do" block "end"
;

retstat:          "return"
|                 "return" ";"
|                 "return" explist
|                 "return" explist ";"
;

label:            "::" IDENTIFIER "::"
;

funcname:         IDENTIFIER
|                 IDENTIFIER ":" IDENTIFIER
|                 IDENTIFIER dotseq
|                 IDENTIFIER dotseq ":" IDENTIFIER
;

dotseq:           "." IDENTIFIER dotseq
|                 "." IDENTIFIER
;

varlist:          varlist "," var
|                 var
;

var:              IDENTIFIER
|                 prefixexp "[" exp "]"
|                 prefixexp "." IDENTIFIER
;

namelist:         IDENTIFIER 
|                 namelist "," IDENTIFIER
;

explist:          exp
|                 explist "," exp
;

exp:              "nil"
|                 "false"
|                 "true"
|                 numeral
|                 STRINGCONST
|                 "..."
|                 functiondef
|                 prefixexp
|                 tableconstructor
|                 exp binop exp
|                 unop exp
;

numeral:          INTCONST
|                 FLOATCONST
;

prefixexp:        var
|                 functioncall
|                 "(" exp ")"
;

functioncall:     prefixexp args
|                 prefixexp ":" IDENTIFIER args
;

args:             "(" ")"
|                 "(" explist ")"
|                 tableconstructor
|                 STRINGCONST
;


functiondef:      "function" funcbody
;

funcbody:         "(" ")" block "end"
|                 "(" parlist ")" block "end"
;

parlist:          namelist "," "..."  
|                 namelist
|                 "..."
;

tableconstructor: "{" fieldlist "}"
|                 "{" "}"
;

fieldlist:        field
|                 field fieldsep
|                 fieldlist1 field
|                 fieldlist1 field fieldsep
;

fieldlist1:       fieldlist1 field fieldsep
|                 field fieldsep
;

field:            "[" exp "]" "=" exp
|                 IDENTIFIER "=" exp
|                 exp
;

fieldsep:         ","
|                 ";"
;

binop:            "+"
|                 "-"
|                 "*"
|                 "/"
|                 "//"
|                 "^"
|                 "%"
|                 "&"
|                 "~"
|                 "|"
|                 ">>"
|                 "<<"
|                 ".."
|                 "<"
|                 "<="
|                 ">"
|                 ">="
|                 "=="
|                 "~="
|                 "and"
|                 "or"
;

unop:             "-"   %prec "not"
|                 "not"
|                 "#"
|                 "~"   %prec "not"
;

%%

void yyerror (char const *s) {
    printf("SYNTAX ERROR (%d): %s\n", yylineno, s);
    exit(1);
}

int main(void) {
    #ifdef YYDEBUG
      yydebug = 1;
      yy_flex_debug = 1;
    #endif
    if (yyparse() == 0) {
        puts("PARSE SUCCESSFUL");
    } else {
        puts("PARSE FAILED");
        return 1;
    }
    return 0;
}
