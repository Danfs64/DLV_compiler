#include "error_messages.hpp"

#include <memory>
#include <iostream>
#include <stdio.h>
#include "lua_things.hpp"

extern int yylineno;

void error_binop(const char* op, lua_things::Type t1, lua_things::Type t2) {
    const char* message_template = "Type error (%d) for operator %s, lhs is %s and rhs is %s\n";
    auto string = std::make_unique<char[]>(100);
    sprintf(string.get(), message_template, yylineno, op,
            lua_things::type_string(t1), lua_things::type_string(t2));
    std::cerr << string.get();
    exit(2);
}

void error_unop(const char* op, lua_things::Type t) {
    const char* message_template = "Type error (%d) for operator %s, expression is %s\n";
    auto string = std::make_unique<char[]>(100);
    sprintf(string.get(), message_template, yylineno, op,
            lua_things::type_string(t));
    std::cerr << string.get();
    exit(3);
}

void error_call(lua_things::Type t) {
    const char* message_template = "Type error (%d), attempt to call a %s\n";
    auto string = std::make_unique<char[]>(100);
    sprintf(string.get(), message_template, yylineno, lua_things::type_string(t));
    std::cerr << string.get();
    exit(4);
}

void error_index(lua_things::Type t1, lua_things::Type t2) {
    const char* message_template = "Type error (%d) for index lhs is %s and rhs is %s\n";
    auto string = std::make_unique<char[]>(100);
    sprintf(string.get(), message_template, yylineno,
            lua_things::type_string(t1), lua_things::type_string(t2));
    std::cerr << string.get();
    exit(5);
}

void error_break() {
    const char* message_template = "(%d) break used in a non-loop block.\n";
    char error_string[100];
    sprintf(error_string, message_template, yylineno);
    std::cerr << error_string;
    exit(6);
}