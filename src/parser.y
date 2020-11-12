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
#include <iostream>
#include <exception>
#include <stdexcept>
#include "lua_things.hpp"
#include "data_structures.hpp"
#include "error_messages.hpp"
#include "common_utils.hpp"
#include "parser_utils.hpp"

#define YYSTYPE lua_things::Type

int yylex();
void yyerror(const char*);
void init_shebang();

extern char* yytext;
extern int yylineno;
extern int yy_flex_debug;

data_structures::context ctx;

}

%code {
    /* Utility macros and functions */
    #define TRY_OP(bop, vf, v1, v2, func)  { try { vf = func(v1, v2); } catch (std::exception& e) { std::cout << e.what();  error_binop( bop , v1, v2); } }

    #define TRY_ARITHM(bop, vf, v1, v2)  TRY_OP(bop, vf, v1, v2, lua_things::check_arithm)
    #define TRY_EQ(bop, vf, v1, v2)      TRY_OP(bop, vf, v1, v2, lua_things::check_eq)
    #define TRY_NEQ(bop, vf, v1, v2)     TRY_OP(bop, vf, v1, v2, lua_things::check_neq)
    #define TRY_ORDER(bop, vf, v1, v2)   TRY_OP(bop, vf, v1, v2, lua_things::check_order)
    #define TRY_CAT(bop, vf, v1, v2)     TRY_OP(bop, vf, v1, v2, lua_things::check_cat)
    #define TRY_LOGICAL(bop, vf, v1, v2) TRY_OP(bop, vf, v1, v2, lua_things::check_logical)
    #define TRY_BITWISE(bop, vf, v1, v2) TRY_OP(bop, vf, v1, v2, lua_things::check_bitwise)

    #define TRY_UOP(uop, vf, v, func) { try { vf = func(v); } catch (std::exception& e) { error_unop( uop , v); } }

    #define TRY_UARITHM(uop, vf, v)   TRY_UOP(uop, vf, v, lua_things::check_arithm)
    #define TRY_UBITWISE(uop, vf, v)  TRY_UOP(uop, vf, v, lua_things::check_bitwise)
    #define TRY_NOT(uop, vf, v)       TRY_UOP(uop, vf, v, lua_things::check_not)
    #define TRY_LEN(uop, vf, v)       TRY_UOP(uop, vf, v, lua_things::check_len)

    #define TRY_CALL(vf, v)  { try { vf = lua_things::check_call(v); } catch (std::exception& e) { error_call(v); } }

    #define TRY_INDEX(vf, v1, v2)  { try { vf = lua_things::check_index(v1, v2); } catch (std::exception& e) { error_index(v1, v2); } }

    #define ASSIGN_LOCAL()       { global::assign_type = data_structures::assign_type::LOCAL;            }
    #define ASSIGN_GLOBAL()      { global::assign_type = data_structures::assign_type::GLOBAL;           }
    #define CLEAR_NAME_EXP()     { global::namelist.clear(); global::explist.clear(); }
    #define ASSIGN_AND_CLEAR()   { add_assign_list(); CLEAR_NAME_EXP(); }

    #define NEW_SCOPE(TYPE)    { ctx.new_scope(data_structures::scope_type::TYPE); }
    #define REMOVE_SCOPE()     { ctx.remove_scope(); }

    #define STORE_LIST_TYPE()    { global::prev_assign_list_type = global::assign_list_type; }
    #define TO_EXPLIST()         { global::assign_list_type = list_type::EXPLIST; }
    #define RESTORE_LIST_TYPE()  { global::assign_list_type = global::prev_assign_list_type; }
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
|   "else" { NEW_SCOPE(NON_LOOP); } block { REMOVE_SCOPE(); }
;

opt_comma_exp:
    %empty
|   "," exp
;

opt_parlist:
    %empty
|   parlist  {
        for (const auto& name : global::namelist) {
            add_symbol_last_scope(name, yylineno, lua_things::Type::TABLE);
        }
        global::namelist.clear();
    }
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
|   ":" IDENTIFIER  { global::full_funcname.emplace_back(global::last_identifier); }
;

opt_comma_elip:
    %empty
|   "," "..."       { add_namelist("..."); }
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
|   loop_elseif "elseif" exp "then" { NEW_SCOPE(NON_LOOP); } block { REMOVE_SCOPE(); }
;

loop_dot_name:
    %empty
|   loop_dot_name "." IDENTIFIER { global::full_funcname.emplace_back(global::last_identifier); }
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
|   varlist "=" {
        #ifdef DLVCDEBUG
        std::cerr << "after varlist" << std::endl;
        #endif
        global::assign_list_type = list_type::EXPLIST;
    } explist {
        ASSIGN_AND_CLEAR();
        global::assign_list_type = list_type::VARLIST;
    }
|   call                            %prec ";"                    { CLEAR_NAME_EXP(); } 
|   label
|   "break" { if(!ctx.verify_break()) { error_break(); } }
|   "goto" IDENTIFIER
|   "do" { NEW_SCOPE(NON_LOOP); } block "end" { REMOVE_SCOPE(); }
|   "while" exp "do" { NEW_SCOPE(LOOP); } block "end" { REMOVE_SCOPE(); }
|   "repeat" { NEW_SCOPE(LOOP); } block "until" exp { REMOVE_SCOPE(); }
|   "if" exp { CLEAR_NAME_EXP(); } "then" { NEW_SCOPE(NON_LOOP); } block { REMOVE_SCOPE(); } loop_elseif opt_else "end" { CLEAR_NAME_EXP(); }
|   "for" IDENTIFIER { global::for_init_id = global::last_identifier; } "=" exp "," exp opt_comma_exp "do" {
        NEW_SCOPE(LOOP);
        #ifdef DLVCDEBUG
        std::cerr << "for_init_id: " << global::for_init_id << std::endl;
        #endif
        add_symbol_last_scope(global::for_init_id, yylineno, $5);
    } block "end" { REMOVE_SCOPE(); }
|   "for" namelist "in" explist "do" { NEW_SCOPE(LOOP); } block "end" { REMOVE_SCOPE(); }
|   "function" funcname {
        add_symbol_global_scope(global::full_funcname.at(0), yylineno, $2);
        global::full_funcname.clear();
        ctx.new_scope(data_structures::scope_type::FUNCTION);
    } funcbody {
        ctx.remove_scope();
    }
|   "local" "function" IDENTIFIER {
        add_symbol_last_scope(global::last_identifier, yylineno, lua_things::Type::FUNCTION);
        ctx.new_scope(data_structures::scope_type::FUNCTION);
    } funcbody {
        ctx.remove_scope();
    }
|   "local" {
        ASSIGN_LOCAL();
    }  namelist {
        global::assign_list_type = list_type::EXPLIST;
    } opt_eq_explist {
        ASSIGN_AND_CLEAR();
        #ifdef DLVCDEBUG
        std::cerr << "ASSIGN_AND_CLEAR | namelist size: " << global::namelist.size() << std::endl;
        #endif
        ASSIGN_GLOBAL();
        global::assign_list_type = list_type::VARLIST;
    }
;

retstat:
    "return" opt_explist opt_semi

label:
    "::" IDENTIFIER { add_label(yytext); } "::"
;

funcname:
    IDENTIFIER { global::full_funcname.emplace_back(global::last_identifier); } loop_dot_name opt_col_name  { $$ = add_func(); }
;

varlist:
    var
|   varlist "," var

var:
    IDENTIFIER {
        #ifdef DLVCDEBUG
        std::cerr << "-------- Acessing identifier --------" << std::endl;
        std::cerr << "ID: " << global::last_identifier << std::endl;
        switch (global::assign_list_type) {
            case list_type::VARLIST:
                std::cerr << "LIST_TYPE: VARLIST" << std::endl;
                break;
            case list_type::EXPLIST:
                std::cerr << "LIST_TYPE: EXPLIST" << std::endl;
                break;
            default:
                std::cerr << "LIST_TYPE: NO_TYPE" << std::endl;
                break;
        }
        #endif
        if (global::assign_list_type == list_type::EXPLIST) {
            try {
                $$ = identifier_check(global::last_identifier);
                if (global::assign_type != data_structures::assign_type::LOCAL)
                    add_namelist(global::last_identifier);
            } catch (std::exception& e) {
                error_identifier_dont_exist(global::last_identifier);
                // add_namelist(global::null_identifier);
            }
        } else {
            try {
                $$ = identifier_check(global::last_identifier);
            } catch (std::exception& e) {
                $$ = lua_things::Type::NIL;
            }
            add_namelist(global::last_identifier);
        }
    }
|   primary index  { TRY_INDEX($$, $1, $2);                       pop_namelist(); add_namelist(global::null_identifier); }
|   var index      { TRY_INDEX($$, $1, $2);                       pop_namelist(); add_namelist(global::null_identifier); }
|   call index     { TRY_INDEX($$, lua_things::Type::TABLE, $2);  pop_namelist(); add_namelist(global::null_identifier); }
;

index:
    "[" exp "]"       { $$ = $2; }
|   "." IDENTIFIER    { $$ = $2; }
;

namelist:
    IDENTIFIER                 { add_namelist(global::last_identifier); }
|   namelist "," IDENTIFIER    { add_namelist(global::last_identifier); }
;

explist:
    exp                   { add_explist($1); }
|   explist "," exp       { add_explist($3); }
;

exp:
    primary     %prec ";"  { $$ = $1; }
|   var         %prec ";"  { $$ = $1; }
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
    primary args                   { TRY_CALL($$, $1); }
|   primary ":" IDENTIFIER args    { TRY_CALL($$, $1); }
|   var args                       { TRY_CALL($$, $1); }
|   var ":" IDENTIFIER args        { TRY_CALL($$, $1); }
|   call args                      { TRY_CALL($$, $1); RESTORE_LIST_TYPE(); }
|   call ":" IDENTIFIER args       { TRY_CALL($$, $1); }
;

args:
    "(" { STORE_LIST_TYPE(); TO_EXPLIST(); global::is_args = true; } opt_explist ")" { RESTORE_LIST_TYPE(); global::is_args = false; }
|   tableconstructor
|   STRINGCONST
;

functiondef:
    "function" { ctx.new_scope(data_structures::scope_type::FUNCTION); } funcbody { ctx.remove_scope(); }
;

funcbody:
    "(" opt_parlist ")" block "end"
;

parlist:
   namelist opt_comma_elip   
|  "..."                     { add_namelist("..."); }
;

tableconstructor:
    "{" opt_fieldlist "}"
;

fieldlist:
    field loop_fields opt_fieldsep
;

field:
    "[" exp "]" "=" exp            /* VERIFICAR se exp do índice é nil */
|   IDENTIFIER "=" exp
|   exp
;

fieldsep:
    ","
|   ";"
;

binop:
    exp "+"   exp { TRY_ARITHM("+", $$, $1, $3);    }
|   exp "-"   exp { TRY_ARITHM("-", $$, $1, $3);    }
|   exp "*"   exp { TRY_ARITHM("*", $$, $1, $3);    }
|   exp "/"   exp { TRY_ARITHM("/", $$, $1, $3);    }
|   exp "//"  exp { TRY_ARITHM("/", $$, $1, $3);    }
|   exp "^"   exp { TRY_ARITHM("^", $$, $1, $3);    }
|   exp "%"   exp { TRY_ARITHM("%", $$, $1, $3);    }
|   exp "&"   exp { TRY_BITWISE("&", $$, $1, $3);   }
|   exp "~"   exp { TRY_BITWISE("~", $$, $1, $3);   }
|   exp "|"   exp { TRY_BITWISE("|", $$, $1, $3);   }
|   exp ">>"  exp { TRY_BITWISE(">>", $$, $1, $3);  }
|   exp "<<"  exp { TRY_BITWISE("<<", $$, $1, $3);  }
|   exp ".."  exp { TRY_CAT("..", $$, $1, $3);      }
|   exp "<"   exp { TRY_ORDER("<", $$, $1, $3);     }
|   exp "<="  exp { TRY_ORDER("<=", $$, $1, $3);    }
|   exp ">"   exp { TRY_ORDER(">", $$, $1, $3);     }
|   exp ">="  exp { TRY_ORDER(">=", $$, $1, $3);    }
|   exp "=="  exp { TRY_EQ("==", $$, $1, $3);       }
|   exp "~="  exp { TRY_NEQ("~=", $$, $1, $3);      }
|   exp "and" exp { TRY_LOGICAL("and", $$, $1, $3); }
|   exp "or"  exp { TRY_LOGICAL("or", $$, $1, $3);  }
;

unop:
    "-"   exp     %prec "not" { TRY_UARITHM("-", $$, $2);  }
|   "not" exp                 { TRY_NOT("not", $$, $2);    }
|   "#"   exp                 { TRY_LEN("#", $$, $2);      }
|   "~"   exp     %prec "not" { TRY_UBITWISE("~", $$, $2); }
;

%%

void yyerror (char const *s) {
    printf("SYNTAX ERROR (%d): %s\n", yylineno, s);
    exit(50);
}

int main(void) {
    global::assign_list_type = list_type::VARLIST;
    global::prev_assign_list_type = list_type::VARLIST;
    
    ctx.new_scope(data_structures::scope_type::NON_LOOP);
    add_builtin();
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
