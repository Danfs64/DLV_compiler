// LALR(1) grammar for Lua.
// Adapted from http://lua-users.org/wiki/LuaFourOneGrammar, which is version
// 4.1 of the language. Additional constructs were added to make the grammar
// 5.3 compliant.

%output "parser.c"
%defines "parser.h"
%define parse.error verbose
%define parse.lac full

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

%precedence ";"

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

// From: http://lua-users.org/wiki/LuaFourOneGrammar
// Note that left parenthesis, left brace, and literals are preferentially treated
// as arguments rather than as starting a new expession. This rule comes into
// effect when interpreting a call as a statement, or a primary, variable, or call
// as an expession. Without this rule, the grammar is ambiguous.

%precedence "(" "{" STRINGCONST

%start chunk

%%

// --- Helpers rules

numeral:
    INTCONST
|   FLOATCONST
;

// --- Opt

opt_retstat:
    %empty
|   retstat
;

opt_semi:
    %empty
|   ";"
;

opt_else:
    %empty
|   "else" block
;

opt_comma_exp:
    %empty
|   "," exp
;

opt_parlist:
    %empty
|   parlist
;

opt_eq_explist:
    %empty
|   "=" explist
;

opt_explist:
    %empty
|   explist
;

opt_col_name:
    %empty
|   ":" IDENTIFIER
;

opt_comma_elip:
    %empty
|   "," "..."
;

opt_fieldlist:
    %empty
|   fieldlist
;

opt_fieldsep:
    %empty
|   fieldsep
;

// --- Loop

loop_stat:
    %empty
|   loop_stat stat
;

loop_elseif:
    %empty
|   loop_elseif "elseif" exp "then" block
;

loop_dot_name:
    %empty
|   loop_dot_name "." IDENTIFIER
;

loop_fields:
    %empty
|   loop_fields fieldsep field
;

// --- Rules

chunk:
    block
;

block:
    loop_stat opt_retstat
;

stat:
    ";"
|   varlist "=" explist
|   call                            %prec ";"
|   label
|   "break"
|   "goto" IDENTIFIER
|   "do" block "end"
|   "while" exp "do" block "end"
|   "repeat" block "until" exp
|   "if" exp "then" block loop_elseif opt_else "end"
|   "for" IDENTIFIER "=" exp "," exp opt_comma_exp "do" block "end"
|   "for" namelist "in" explist "do" block "end"
|   "function" funcname funcbody
|   "local" "function" IDENTIFIER funcbody
|   "local" namelist opt_eq_explist
;

retstat:
    "return" opt_explist opt_semi

label:
    "::" IDENTIFIER "::"
;

funcname:
    IDENTIFIER loop_dot_name opt_col_name
;

varlist:
    var
|   varlist "," var

var:
    IDENTIFIER
|   primary index
|   var index
|   call index
;

index:
    "[" exp "]"
|   "." IDENTIFIER
;

namelist:
    IDENTIFIER
|   namelist "," IDENTIFIER
;

explist:
    exp
|   explist "," exp
;

exp:
    primary     %prec ";"
|   var         %prec ";"
|   call        %prec ";"
|   binop
|   unop
;

primary:
    "nil"
|   "false"
|   "true"
|   numeral
|   STRINGCONST
|   "..."
|   functiondef
|   tableconstructor
|   "(" exp ")"
;

call:
    primary args
|   primary ":" IDENTIFIER args
|   var args
|   var ":" IDENTIFIER args
|   call args
|   call ":" IDENTIFIER args
;

args:
    "(" opt_explist ")"
|   tableconstructor
|   STRINGCONST
;

functiondef:
    "function" funcbody
;

funcbody:
    "(" opt_parlist ")" block "end"
;

parlist:
   namelist opt_comma_elip
|  "..."
;

tableconstructor:
    "{" opt_fieldlist "}"
;

fieldlist:
    field loop_fields opt_fieldsep
;

field:
    "[" exp "]" "=" exp
|   IDENTIFIER "=" exp
|   exp
;

fieldsep:
    ","
|   ";"
;

binop:
    exp "+" exp
|   exp "-" exp
|   exp "*" exp
|   exp "/" exp
|   exp "//" exp
|   exp "^" exp
|   exp "%" exp
|   exp "&" exp
|   exp "~" exp
|   exp "|" exp
|   exp ">>" exp
|   exp "<<" exp
|   exp ".." exp
|   exp "<" exp
|   exp "<=" exp
|   exp ">" exp
|   exp ">=" exp
|   exp "==" exp
|   exp "~=" exp
|   exp "and" exp
|   exp "or" exp
;

unop:
    "-" exp     %prec "not"
|   "not" exp
|   "#" exp
|   "~" exp     %prec "not"
;

%%

void yyerror (char const *s) {
    printf("SYNTAX ERROR (%d): %s\n", yylineno, s);
    exit(1);
}

int main(void) {
    if (yyparse() == 0) {
        puts("PARSE SUCCESSFUL");
    } else {
        puts("PARSE FAILED");
        return 1;
    }
    return 0;
}
