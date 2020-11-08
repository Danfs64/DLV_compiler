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

#define YYSTYPE lua_things::Type

int yylex();
void yyerror(const char*);
void init_shebang();

extern char* yytext;
extern int yylineno;
extern int yy_flex_debug;

extern std::string scanner_id;

data_structures::context ctx;

enum class var_type : int {
    NAME,
    INDEX,
};

enum class list_type : int {
    VARLIST,
    EXPLIST,
    NO_TYPE,
};

namespace tmp {
    std::vector<std::string> namelist;
    std::vector<lua_things::Type> explist;
    data_structures::assign_type assign_type;
    std::vector<std::tuple<std::string, var_type>> varlist;
    std::string last_identifier;
    std::vector<std::string> full_funcname;
    list_type assign_list_type = list_type::VARLIST;
    list_type prev_assign_list_type = list_type::VARLIST;
    std::string for_init_id;
}

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

    #define ASSIGN_LOCAL() tmp::assign_type = data_structures::assign_type::LOCAL
    #define ASSIGN_GLOBAL() tmp::assign_type = data_structures::assign_type::GLOBAL
    #define ASSIGN_AND_CLEAR() { add_assign_list(); tmp::namelist.clear(); tmp::explist.clear(); }

    #define UPDATE_IDENTIFIER() { tmp::last_identifier = yytext; }

    #define NEW_SCOPE(TYPE)    { ctx.new_scope(data_structures::scope_type::TYPE); }
    #define REMOVE_SCOPE()     { ctx.remove_scope(); }

    #define STORE_LIST_TYPE()    { tmp::prev_assign_list_type = tmp::assign_list_type; }
    #define TO_EXPLIST()         { tmp::assign_list_type = list_type::EXPLIST; }
    #define RESTORE_LIST_TYPE()  { tmp::assign_list_type = tmp::prev_assign_list_type; }

    #include "parser_utils.cpp"
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
|   ":" IDENTIFIER  { UPDATE_IDENTIFIER(); tmp::full_funcname.emplace_back(tmp::last_identifier); }
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
|   loop_elseif "elseif" exp "then" { NEW_SCOPE(NON_LOOP); } block { REMOVE_SCOPE(); }
;

loop_dot_name:
    %empty
|   loop_dot_name "." IDENTIFIER { UPDATE_IDENTIFIER(); tmp::full_funcname.emplace_back(tmp::last_identifier); }
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
        tmp::assign_list_type = list_type::EXPLIST;
    } explist {
        ASSIGN_AND_CLEAR();
        tmp::assign_list_type = list_type::VARLIST;
    }
|   call                            %prec ";"
|   label
|   "break" { if(!ctx.verify_break()) { error_break(); } }
|   "goto" IDENTIFIER
|   "do" { NEW_SCOPE(NON_LOOP); } block "end" { REMOVE_SCOPE(); }
|   "while" exp "do" { NEW_SCOPE(LOOP); } block "end" { REMOVE_SCOPE(); }
|   "repeat" { NEW_SCOPE(LOOP); } block "until" exp { REMOVE_SCOPE(); }
|   "if" exp "then" { NEW_SCOPE(NON_LOOP); } block { REMOVE_SCOPE(); } loop_elseif opt_else "end"
|   "for" IDENTIFIER { tmp::for_init_id = scanner_id; } "=" exp "," exp opt_comma_exp "do" {
        NEW_SCOPE(LOOP);
        #ifdef DLVCDEBUG
        std::cerr << "for_init_id: " << tmp::for_init_id << std::endl;
        #endif
        add_symbol_last_scope(tmp::for_init_id, yylineno, $5);
    } block "end" { REMOVE_SCOPE(); }
|   "for" namelist "in" explist "do" { NEW_SCOPE(LOOP); } block "end" { REMOVE_SCOPE(); }
|   "function" funcname {
        UPDATE_IDENTIFIER();
        add_symbol_global_scope(tmp::full_funcname.at(0), yylineno, $2);
        tmp::full_funcname.clear();
        ctx.new_scope(data_structures::scope_type::FUNCTION);
    } funcbody {
        ctx.remove_scope();
    }
|   "local" "function" IDENTIFIER {
        UPDATE_IDENTIFIER();
        add_symbol_last_scope(tmp::last_identifier, yylineno, lua_things::Type::FUNCTION);
        ctx.new_scope(data_structures::scope_type::FUNCTION);
    } funcbody {
        ctx.remove_scope();
    }
|   "local" {
        ASSIGN_LOCAL();
    }  namelist {
        tmp::assign_list_type = list_type::EXPLIST;
    } opt_eq_explist {
        ASSIGN_AND_CLEAR();
        ASSIGN_GLOBAL();
        tmp::assign_list_type = list_type::VARLIST;
    }
;

retstat:
    "return" opt_explist opt_semi

label:
    "::" IDENTIFIER { add_label(yytext); } "::"
;

funcname:
    IDENTIFIER { UPDATE_IDENTIFIER(); tmp::full_funcname.emplace_back(tmp::last_identifier); } loop_dot_name opt_col_name  { $$ = add_func(); }
;

varlist:
    var
|   varlist "," var

var:
    IDENTIFIER {
        UPDATE_IDENTIFIER();
        #ifdef DLVCDEBUG
        std::cerr << "-------- Acessing identifier --------" << std::endl;
        switch (tmp::assign_list_type) {
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
        if (tmp::assign_list_type == list_type::EXPLIST) {
            try {
                $$ = identifier_check(tmp::last_identifier);
            } catch (std::exception& e) {
                error_identifier_dont_exist();
            }
            tmp::varlist.emplace_back(yytext, var_type::NAME);
        } else {
            try {
                $$ = identifier_check(tmp::last_identifier);
            } catch (std::exception& e) {
                $$ = lua_things::Type::NIL;
                // Nothing
            }
            tmp::namelist.emplace_back(tmp::last_identifier);
        }
    }
|   primary index  { TRY_INDEX($$, $1, $2); }
|   var index      { TRY_INDEX($$, $1, $2); }
|   call index     { TRY_INDEX($$, lua_things::Type::TABLE, $2); }
;

index:
    "[" exp "]"       { $$ = $2; }
|   "." IDENTIFIER    { $$ = $2; }
;

namelist:
    IDENTIFIER                 { tmp::namelist.emplace_back(yytext); }
|   namelist "," IDENTIFIER    { tmp::namelist.emplace_back(yytext); }
;

explist:
    exp                   { tmp::explist.emplace_back($1); }
|   explist "," exp       { tmp::explist.emplace_back($3); }
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
    "(" { STORE_LIST_TYPE(); TO_EXPLIST(); } opt_explist ")"
|   tableconstructor
|   STRINGCONST
;

functiondef:
    "function"  funcbody
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
    "-"   exp     %prec "not" { TRY_UARITHM("-", $$, $1);  }
|   "not" exp                 { TRY_NOT("not", $$, $1);    }
|   "#"   exp                 { TRY_LEN("#", $$, $1);      }
|   "~"   exp     %prec "not" { TRY_UBITWISE("~", $$, $1); }
;

%%

void yyerror (char const *s) {
    printf("SYNTAX ERROR (%d): %s\n", yylineno, s);
    exit(50);
}

int main(void) {
    ctx.new_scope(data_structures::scope_type::NON_LOOP);
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
