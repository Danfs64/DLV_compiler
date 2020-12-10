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
#include "ast.hpp"
#include "code.hpp"

#define YYSTYPE node

using luat = lua_things::Type;
using luae = lua_things::expression;

int yylex();
void yyerror(const char*);
void init_shebang();

extern char* yytext;
extern int yylineno;
extern int yy_flex_debug;

data_structures::context ctx;
node root(NodeKind::program, luae());

}

%code {
    /* Utility macros and functions */
    #define TRY_OP(bop, vf, v1, v2, func)  { try { vf.expr = func(v1.expr, v2.expr); } catch (std::exception& e) { std::cout << e.what();  error_binop( bop , (v1).expr.type, (v2).expr.type); } }

    #define TRY_ARITHM(bop, vf, v1, v2)  TRY_OP(bop, vf, v1, v2, lua_things::check_arithm)
    #define TRY_EQ(bop, vf, v1, v2)      TRY_OP(bop, vf, v1, v2, lua_things::check_eq)
    #define TRY_NEQ(bop, vf, v1, v2)     TRY_OP(bop, vf, v1, v2, lua_things::check_neq)
    #define TRY_ORDER(bop, vf, v1, v2)   TRY_OP(bop, vf, v1, v2, lua_things::check_order)
    #define TRY_CAT(bop, vf, v1, v2)     TRY_OP(bop, vf, v1, v2, lua_things::check_cat)
    #define TRY_LOGICAL(bop, vf, v1, v2) TRY_OP(bop, vf, v1, v2, lua_things::check_logical)
    #define TRY_BITWISE(bop, vf, v1, v2) TRY_OP(bop, vf, v1, v2, lua_things::check_bitwise)

    #define TRY_UOP(uop, vf, v, func) { try { vf.expr = func(v.expr); } catch (std::exception& e) { error_unop(uop , v.expr.type); } }

    #define TRY_UARITHM(uop, vf, v)   TRY_UOP(uop, vf, v, lua_things::check_arithm)
    #define TRY_UBITWISE(uop, vf, v)  TRY_UOP(uop, vf, v, lua_things::check_bitwise)
    #define TRY_NOT(uop, vf, v)       TRY_UOP(uop, vf, v, lua_things::check_not)
    #define TRY_LEN(uop, vf, v)       TRY_UOP(uop, vf, v, lua_things::check_len)

    #define TRY_CALL(vf, v)  { try { vf.expr = lua_things::check_call(v.expr); } catch (std::exception& e) { error_call(v.expr.type); } }

    #define TRY_INDEX(vf, v1, v2)  { try { vf.expr = lua_things::check_index(v1.expr, v2.expr); } catch (std::exception& e) { error_index((v1).expr.type, (v2).expr.type); } }

    #define ASSIGN_LOCAL()       { global::assign_type = data_structures::assign_type::LOCAL;            }
    #define ASSIGN_GLOBAL()      { global::assign_type = data_structures::assign_type::GLOBAL;           }
    #define CLEAR_NAME_EXP()     { global::namelist.clear(); global::explist.clear(); }
    #define ASSIGN_AND_CLEAR()   { add_assign_list(); CLEAR_NAME_EXP(); }

    #define NEW_SCOPE(TYPE)    { ctx.new_scope(data_structures::scope_type::TYPE); }
    #define REMOVE_SCOPE()     { ctx.remove_scope(); }

    #define STORE_LIST_TYPE()    { global::prev_assign_list_type = global::assign_list_type; }
    #define TO_EXPLIST()         { global::assign_list_type = list_type::EXPLIST; }
    #define RESTORE_LIST_TYPE()  { global::assign_list_type = global::prev_assign_list_type; }

    #define CHECK_GOTO()   { if (!ctx.verify_goto_calls()) { error_goto(); } }

    void unify_binop_nodes(node& parent, node&& child1, node&& child2, const char* opstr) {
        parent.add_child(std::move(child1));
        parent.add_child(std::move(child2));
        parent.kind = str2kind(opstr);
    }

    void unify_uop_nodes(node& parent, node&& child, const char* opstr) {
        parent.add_child(std::move(child));
        parent.kind = str2kind(opstr);
    }
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
    INTCONST      { double val = std::stod(yytext); $$.kind = NodeKind::num_val; $$.d_data = val;}
|   FLOATCONST    { double val = std::stod(yytext); $$.kind = NodeKind::num_val; $$.d_data = val;}
;

// --- Opt

opt_retstat:
    %empty   { $$ = node(); }
|   retstat  { $$ = std::move($1); }
;

opt_semi:
    %empty
|   ";"
;

opt_else:
    %empty { $$ = node(); }
|   "else" { NEW_SCOPE(NON_LOOP); } block {
        REMOVE_SCOPE();

        // AST
        node new_node = node();
        new_node.kind = NodeKind::else_;
        new_node.add_child(std::move($3));
        $$ = std::move(new_node);
    }
;

opt_comma_exp:
    %empty        { $$ = node();        }
|   "," exp       { $$ = std::move($2); }
;

opt_parlist:
    %empty   { $$ = node(); }
|   parlist  {
        for (const auto& name : global::namelist) {
            add_symbol_last_scope(name, yylineno, lua_things::Type::TABLE);
        }
        global::namelist.clear();

        $$ = std::move($1);
    }
;

opt_eq_explist:
    %empty        { $$ = node();  }
|   "=" explist   { $$ = std::move($2); }
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
    %empty         { $$ = node(); $$.kind = NodeKind::BLOCK; }
|   loop_stat stat { $1.add_child(std::move($2)); $$ = std::move($1);}
;

loop_elseif:
    %empty  { $$ = node(); }
|   loop_elseif "elseif" exp "then" { CLEAR_NAME_EXP(); NEW_SCOPE(NON_LOOP);} block {
        REMOVE_SCOPE();

        // AST
        node new_node = node();
        new_node.kind = NodeKind::elif;
        new_node.add_child(std::move($3)); // exp
        new_node.add_child(std::move($6)); // block

        $1.add_child(std::move(new_node));
        $$ = std::move($1);
    }
;

loop_dot_name:
    %empty
|   loop_dot_name "." IDENTIFIER { global::full_funcname.emplace_back(global::last_identifier); }
;

loop_fields:
    %empty  { $$ = node(); }
|   loop_fields fieldsep field
;

// --- Rules

chunk:
    block  { CHECK_GOTO(); root = std::move($1); root.kind = NodeKind::program; }
;

block:
    loop_stat opt_retstat { $1.add_child(std::move($2)); $$ = std::move($1); }
;

stat:
    ";"
|   varlist "=" {
        #ifdef DLVCDEBUG
        std::cerr << "after varlist" << std::endl;
        #endif
        global::assign_list_type = list_type::EXPLIST;
    } explist {
        ASSIGN_GLOBAL();
        ASSIGN_AND_CLEAR();
        global::assign_list_type = list_type::VARLIST;

        // AST
        $$ = node();
        $$.add_child(std::move($1));
        $$.add_child(std::move($4));
        $$.kind = NodeKind::assign;
    }
|   call                            %prec ";"                    { CLEAR_NAME_EXP(); $$ = std::move($1); } 
|   label
|   "break" { if(!ctx.verify_break()) { error_break(); } }
|   "goto" IDENTIFIER { ctx.add_goto_call(global::last_identifier); }
|   "do" { NEW_SCOPE(NON_LOOP); } block "end" {
        REMOVE_SCOPE();
        // AST
        $$ = node();
        $$.kind = NodeKind::do_;
        $$.add_child(std::move($3)); // block
    }
|   "while" exp "do" { NEW_SCOPE(LOOP); CLEAR_NAME_EXP(); } block "end" {
        REMOVE_SCOPE();
        $$.kind = NodeKind::while_;
        $$.add_child(std::move($2)); // exp
        $$.add_child(std::move($5)); // block
    }
|   "repeat" { NEW_SCOPE(LOOP); } block "until" exp {
        REMOVE_SCOPE();

        $$.kind = NodeKind::repeat;
        $$.add_child(std::move($3)); // Block
        $$.add_child(std::move($5)); // Exp
    }
|   "if" exp { CLEAR_NAME_EXP(); } "then" { NEW_SCOPE(NON_LOOP); } block { REMOVE_SCOPE(); } loop_elseif opt_else "end" {
        CLEAR_NAME_EXP();

        // AST
        $$.kind = NodeKind::if_;
        $$.add_child(std::move($2));
        $$.add_child(std::move($6));
        $$.add_child(std::move($8));
        $$.add_child(std::move($9));

        for (auto& i : $8.children) { // elseif
            $$.add_child(std::move(i));
        }

        $$.add_child(std::move($9)); // else
    }
|   "for" IDENTIFIER { global::for_init_id = global::last_identifier; } "=" exp "," exp opt_comma_exp "do" {
        CLEAR_NAME_EXP();
        NEW_SCOPE(LOOP);
        #ifdef DLVCDEBUG
        std::cerr << "for_init_id: " << global::for_init_id << std::endl;
        #endif
        add_symbol_last_scope(global::for_init_id, yylineno, ($5).expr.type);
    } block "end" {
        REMOVE_SCOPE();

        // AST
        node id_node = node();
        id_node.kind = NodeKind::var_name;
        id_node.expr.name = global::for_init_id;
        id_node.expr.type = $5.expr.type;
        
        $$.kind = NodeKind::for_;
        $$.add_child(std::move(id_node)); // ID
        $$.add_child(std::move($5)); // exp1
        $$.add_child(std::move($7)); // exp2
        $$.add_child(std::move($8)); // opt_comma_exp
        $$.add_child(std::move($11)); // block
    }
|   "for" namelist "in" explist "do" {
        NEW_SCOPE(LOOP);
        ASSIGN_AND_CLEAR();
        CLEAR_NAME_EXP();
    } block "end" { REMOVE_SCOPE(); }
|   "function" funcname {
        add_symbol_global_scope(global::full_funcname.at(0), yylineno, ($2).expr.type);
        global::full_funcname.clear();
        ctx.new_scope(data_structures::scope_type::FUNCTION);
    } funcbody {
        ctx.verify_goto_calls();
        ctx.remove_scope();

        $$.kind = NodeKind::func_def;
        $$.add_child(std::move($2));
        $$.add_child(std::move($4));
    }
|   "local" "function" IDENTIFIER {
        add_symbol_last_scope(global::last_identifier, yylineno, lua_things::Type::FUNCTION);
        ctx.new_scope(data_structures::scope_type::FUNCTION);
    } funcbody {
        ctx.verify_goto_calls();
        ctx.remove_scope();
    }
|   "local" {
        ASSIGN_LOCAL();
    }  namelist {
        global::assign_list_type = list_type::EXPLIST;

        // AST
        // Fix node list
        // auto tmp = std::move($3);
        // auto tmp_list = std::move(tmp.children);
        // $3 = node();
        // $3.add_child(std::move(tmp));
        // for (auto& i : tmp_list) {
        //     $3.add_child(std::move(i));
        // }
        // $3.kind = NodeKind::var_list;
    } opt_eq_explist {
        ASSIGN_AND_CLEAR();
        #ifdef DLVCDEBUG
        std::cerr << "ASSIGN_AND_CLEAR | namelist size: " << global::namelist.size() << std::endl;
        #endif
        ASSIGN_GLOBAL();
        global::assign_list_type = list_type::VARLIST;

        // AST
        $$.kind = NodeKind::var_decl;
        $$.add_child(std::move($3));
        if ($5.kind != NodeKind::NO_KIND) {
            $$.add_child(std::move($5));
        }
    }
;

retstat:
    "return" opt_explist opt_semi

label:
    "::" IDENTIFIER { add_label(yytext); ctx.add_goto_label(global::last_identifier); } "::"
;

funcname:
    IDENTIFIER { global::full_funcname.emplace_back(global::last_identifier); } loop_dot_name opt_col_name  {
        $$.expr = add_func();
        std::string funcname = "";
        for (auto& i : global::full_funcname) {
            funcname += i;
        }
        $$.kind = NodeKind::func_name;
        $$.expr.name = std::move(funcname);
    }
;

varlist:
    var              { $$ = node();  $$.add_child(std::move($1)); $$.kind = NodeKind::var_list; }
|   varlist "," var  { $1.add_child(std::move($3)); $$ = std::move($1); }

var:
    IDENTIFIER {
        #ifdef DLVCDEBUG
        std::cerr << "-------- Acessing identifier --------" << std::endl;
        std::cerr << "ID: " << global::last_identifier << std::endl;
        std::cerr << "Is index: " << global::is_index << std::endl;
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
        if (!global::is_index) {
            if (global::assign_list_type == list_type::EXPLIST) {
                try {
                    auto expr = identifier_check(global::last_identifier);
                    $$ = node(NodeKind::var_use, expr);
                    if (global::assign_type != data_structures::assign_type::LOCAL)
                        add_namelist(global::last_identifier);
                } catch (std::exception& e) {
                    error_identifier_dont_exist(global::last_identifier);
                    // add_namelist(global::null_identifier);
                }
            } else {
                try {
                    auto expr = identifier_check(global::last_identifier);
                    $$ = node(NodeKind::var_use, expr);
                } catch (std::exception& e) {
                    $$ = node(NodeKind::var_use, lua_things::Type::NIL);
                }
                add_namelist(global::last_identifier);
            }
            $$.expr.name = global::last_identifier;
        } else {
            auto expr = lua_things::expression(lua_things::Type::TABLE);
            $$ = node(NodeKind::var_use, expr);
        }
    }
|   primary { global::is_index = true; } index { global::is_index = false; TRY_INDEX($$, $1, $2); }
|   var     { global::is_index = true; } index { global::is_index = false; TRY_INDEX($$, $1, $2); }
|   call    { global::is_index = true; } index {
        global::is_index = false;
        auto return_node = node(NodeKind::table, luae(luat::TABLE));
        TRY_INDEX($$, return_node, $2); 
        pop_namelist();
        add_namelist(global::null_identifier);
    }
;

index:
    "[" { global::lock_list = true; } exp { global::lock_list = false; } "]"       { $$ = $2; pop_namelist(); add_namelist(global::null_identifier); }
|   "." IDENTIFIER    { $$ = $2; pop_namelist(); add_namelist(global::null_identifier); }
;

namelist:
    IDENTIFIER                 {
        add_namelist(global::last_identifier);
        // AST
        auto expr = luae();
        expr.name = global::last_identifier;
        // $$ = node(NodeKind::var_name, expr);
        // $$.kind = NodeKind::var_name;
        $$ = node();
        $$.kind = NodeKind::var_list;
        node new_node = node();
        new_node.kind = NodeKind::var_name;
        new_node.expr = expr;
        $$.add_child(std::move(new_node));
    }
|   namelist "," IDENTIFIER    {
        add_namelist(global::last_identifier);
        // AST
        luae expr;
        expr.name = global::last_identifier;
        node new_node = node(NodeKind::var_name, expr);
        $1.add_child(std::move(new_node));
        $$ = std::move($1);
    }
;

explist:
    exp                   { add_explist($1.expr); /* AST */ $$ = node(); $$.kind = NodeKind::exp_list; $$.add_child(std::move($1)); }
|   explist "," exp       { add_explist($3.expr); /* AST */ $1.add_child(std::move($3)); $$ = std::move($1); }
;

exp:
    primary     %prec ";"  { $$ = std::move($1); }
|   var         %prec ";"  { $$ = std::move($1); }
|   call        %prec ";"  { $$ = std::move($1); $$.expr.is_return = true;}
|   binop                  { $$ = std::move($1); }
|   unop                   { $$ = std::move($1); }
;

primary:
    "nil"            { $$ = node(NodeKind::nil_val,  luae(lua_things::Type::NIL));                         }
|   "false"          { $$ = node(NodeKind::bool_val, luae(lua_things::Type::BOOL));  $$.b_data = false;     }
|   "true"           { $$ = node(NodeKind::bool_val, luae(lua_things::Type::BOOL));  $$.b_data = true;      }
|   numeral          { $$ = node(NodeKind::num_val,  luae(lua_things::Type::NUM));   $$.d_data = $1.d_data; }
|   STRINGCONST      { $$ = node(NodeKind::str_val,  luae(lua_things::Type::STR));   $$.s_data = yytext;     }
|   "..."            { $$ = node(NodeKind::table,    luae(lua_things::Type::TABLE));    }
|   functiondef      { $$ = node(NodeKind::func_def, luae(lua_things::Type::FUNCTION)); }
|   tableconstructor { $$ = node(NodeKind::table,    luae(lua_things::Type::TABLE));    }
|   "(" exp ")"      { $$ = $2; }
;

call:
    primary args                   {
        TRY_CALL($$, $1);
        $$.add_child(std::move($2));
        $$.kind = NodeKind::call;
    }
|   primary ":" IDENTIFIER args    {
        auto call_node = node(NodeKind::index, luae(luat::STR));
        TRY_INDEX($$, $1, call_node);
        $$.kind = NodeKind::index;
    }
|   var args                       { TRY_CALL($$, $1); $$.add_child(std::move($2)); $$.kind = NodeKind::call; }
|   var ":" IDENTIFIER args        {
        auto call_node = node(NodeKind::index, luae(luat::STR));
        TRY_INDEX($$, $1, call_node);
        $$.kind = NodeKind::index;
    }
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
    "(" opt_parlist ")" block "end"  {
        $$ = node();
        $$.kind = NodeKind::func_body;
        $$.add_child(std::move($2)); // args
        $$.add_child(std::move($4)); // block
    }
;

parlist:
   namelist opt_comma_elip   { $$ = std::move($1); }
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
    exp "+"   exp { $$ = node(); TRY_ARITHM("+", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "+"); }
|   exp "-"   exp { $$ = node(); TRY_ARITHM("-", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "-"); }
|   exp "*"   exp { $$ = node(); TRY_ARITHM("*", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "*"); }
|   exp "/"   exp { $$ = node(); TRY_ARITHM("/", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "/"); }
|   exp "//"  exp { $$ = node(); TRY_ARITHM("/", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "//"); }
|   exp "^"   exp { $$ = node(); TRY_ARITHM("^", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "^"); }
|   exp "%"   exp { $$ = node(); TRY_ARITHM("%", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "%"); }
|   exp "&"   exp { $$ = node(); TRY_BITWISE("&", $$, $1, $3);   unify_binop_nodes($$, std::move($1), std::move($3), "&"); }
|   exp "~"   exp { $$ = node(); TRY_BITWISE("~", $$, $1, $3);   unify_binop_nodes($$, std::move($1), std::move($3), "~"); }
|   exp "|"   exp { $$ = node(); TRY_BITWISE("|", $$, $1, $3);   unify_binop_nodes($$, std::move($1), std::move($3), "|"); }
|   exp ">>"  exp { $$ = node(); TRY_BITWISE(">>", $$, $1, $3);  unify_binop_nodes($$, std::move($1), std::move($3), ">>"); }
|   exp "<<"  exp { $$ = node(); TRY_BITWISE("<<", $$, $1, $3);  unify_binop_nodes($$, std::move($1), std::move($3), "<<"); }
|   exp ".."  exp { $$ = node(); TRY_CAT("..", $$, $1, $3);      unify_binop_nodes($$, std::move($1), std::move($3), ".."); }
|   exp "<"   exp { $$ = node(); TRY_ORDER("<", $$, $1, $3);     unify_binop_nodes($$, std::move($1), std::move($3), "<"); }
|   exp "<="  exp { $$ = node(); TRY_ORDER("<=", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), "<="); }
|   exp ">"   exp { $$ = node(); TRY_ORDER(">", $$, $1, $3);     unify_binop_nodes($$, std::move($1), std::move($3), ">"); }
|   exp ">="  exp { $$ = node(); TRY_ORDER(">=", $$, $1, $3);    unify_binop_nodes($$, std::move($1), std::move($3), ">="); }
|   exp "=="  exp { $$ = node(); TRY_EQ("==", $$, $1, $3);       unify_binop_nodes($$, std::move($1), std::move($3), "=="); }
|   exp "~="  exp { $$ = node(); TRY_NEQ("~=", $$, $1, $3);      unify_binop_nodes($$, std::move($1), std::move($3), "~="); }
|   exp "and" exp { $$ = node(); TRY_LOGICAL("and", $$, $1, $3); unify_binop_nodes($$, std::move($1), std::move($3), "and"); }
|   exp "or"  exp { $$ = node(); TRY_LOGICAL("or", $$, $1, $3);  unify_binop_nodes($$, std::move($1), std::move($3), "or"); }
;

unop:
    "-"   exp     %prec "not" { TRY_UARITHM("-", $$, $2);  unify_uop_nodes($$, std::move($2), "-");   }
|   "not" exp                 { TRY_NOT("not", $$, $2);    unify_uop_nodes($$, std::move($2), "not"); }
|   "#"   exp                 { TRY_LEN("#", $$, $2);      unify_uop_nodes($$, std::move($2), "#");   }
|   "~"   exp     %prec "not" { TRY_UBITWISE("~", $$, $2); unify_uop_nodes($$, std::move($2), "~");   }
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

    root.print_dot();
    generate_code(root);
    return 0;
}
