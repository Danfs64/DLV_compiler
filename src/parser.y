// LALR(1) grammar for Lua.
// Adapted from http://lua-users.org/wiki/LuaFourOneGrammar, which is version
// 4.1 of the language. Additional constructs were added to make the grammar
// 5.3 compliant.

%output "parser.cc"
%defines "parser.hpp"
%define parse.error verbose
%define parse.lac full
%define parse.trace

%code top {
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include "lua_things.hpp"
#include "data_structures.hpp"
#include "error_messages.hpp"

#define YYSTYPE lua_things::Type

int yylex();
void yyerror(const char*);
void init_shebang();

extern int yylineno;
extern int yy_flex_debug;
}

%code {
    /* Utility macros and functions */
    #define TRY_OP(bop, vf, v1, v2, func)  try { vf = func(v1, v2);} catch (std::exception& e) { error_binop( bop , v1, v2); }

    #define TRY_ARITHM(bop, vf, v1, v2)  TRY_OP(bop, vf, v1, v2, lua_things::check_arithm)
    #define TRY_EQ(bop, vf, v1, v2)      TRY_OP(bop, vf, v1, v2, lua_things::check_eq)
    #define TRY_NEQ(bop, vf, v1, v2)     TRY_OP(bop, vf, v1, v2, lua_things::check_neq)
    #define TRY_ORDER(bop, vf, v1, v2)   TRY_OP(bop, vf, v1, v2, lua_things::check_order)
    #define TRY_CAT(bop, vf, v1, v2)     TRY_OP(bop, vf, v1, v2, lua_things::check_cat)
    #define TRY_LOGICAL(bop, vf, v1, v2) TRY_OP(bop, vf, v1, v2, lua_things::check_logical)
    #define TRY_BITWISE(bop, vf, v1, v2) TRY_OP(bop, vf, v1, v2, lua_things::check_bitwise)

    #define TRY_UOP(uop, vf, v, func) try { vf = func(v);} catch (std::exception& e) { error_unop( uop , v); }

    #define TRY_UARITHM(uop, vf, v) TRY_UOP(uop, vf, v, lua_things::check_arithm)
    #define TRY_UBITWISE(uop, vf, v) TRY_UOP(uop, vf, v, lua_things::check_bitwise)
    #define TRY_NOT(uop, vf, v) TRY_UOP(uop, vf, v, lua_things::check_not)
    #define TRY_LEN(uop, vf, v) TRY_UOP(uop, vf, v, lua_things::check_len)
}

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
    "nil"            { $$ = lua_things::Type::NIL; }
|   "false"          { $$ = lua_things::Type::BOOL; }
|   "true"           { $$ = lua_things::Type::BOOL; }
|   numeral          { $$ = lua_things::Type::NUM; }
|   STRINGCONST      { $$ = lua_things::Type::STR; }
|   "..."            { $$ = lua_things::Type::TABLE; }
|   functiondef      { $$ = lua_things::Type::FUNCTION; }
|   tableconstructor { $$ = lua_things::Type::TABLE; }
|   "(" exp ")"      { $$ = $2; }
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
    exp "+" exp   { TRY_ARITHM("+", $$, $1, $3);   }
|   exp "-" exp   { TRY_ARITHM("-", $$, $1, $3);   }
|   exp "*" exp   { TRY_ARITHM("*", $$, $1, $3);   }
|   exp "/" exp   { TRY_ARITHM("/", $$, $1, $3);   }
|   exp "//" exp  { TRY_ARITHM("/", $$, $1, $3);   }
|   exp "^" exp   { TRY_ARITHM("^", $$, $1, $3);   }
|   exp "%" exp   { TRY_ARITHM("%", $$, $1, $3);   }
|   exp "&" exp   { TRY_BITWISE("&", $$, $1, $3);  }
|   exp "~" exp   { TRY_BITWISE("~", $$, $1, $3);  }
|   exp "|" exp   { TRY_BITWISE("|", $$, $1, $3);  }
|   exp ">>" exp  { TRY_BITWISE(">>", $$, $1, $3); }
|   exp "<<" exp  { TRY_BITWISE("<<", $$, $1, $3); }
|   exp ".." exp  { TRY_CAT("..", $$, $1, $3);     }
|   exp "<" exp   { TRY_ORDER("<", $$, $1, $3);    }
|   exp "<=" exp  { TRY_ORDER("<=", $$, $1, $3);   }
|   exp ">" exp   { TRY_ORDER(">", $$, $1, $3);    }
|   exp ">=" exp  { TRY_ORDER(">=", $$, $1, $3);   }
|   exp "==" exp  { TRY_EQ("==", $$, $1, $3);      }
|   exp "~=" exp  { TRY_NEQ("~=", $$, $1, $3);     }
|   exp "and" exp { TRY_LOGICAL("and", $$, $1, $3);}
|   exp "or" exp  { TRY_LOGICAL("or", $$, $1, $3); }
;

unop:
    "-"   exp     %prec "not" { TRY_UARITHM("-", $$, $1);  }
|   "not" exp                 { TRY_NOT("not", $$, $1);    }
|   "#"   exp                 { TRY_LEN("#", $$, $1);      }
|   "~"   exp     %prec "not" { TRY_UBITWISE("~", $$, $1); }
;

%%

void yyerror (char const *s) {
    printf("SYNTAX ERROR (%d): %s\n", yylineno, s);
    exit(1);
}

int main(void) {
    init_shebang();
    #ifdef YYDEBUG
      yydebug = 0;
    #endif
    if (yyparse() == 0) {
        puts("PARSE SUCCESSFUL");
    } else {
        puts("PARSE FAILED");
        return 1;
    }
    return 0;
}
