#include "error_messages.hpp"

#include <memory>
#include <iostream>
#include <stdio.h>
#include "lua_things.hpp"

void error_binop(const char* op, lua_things::Type t1, lua_things::Type t2) {
    const char* message_template = "Type error for operator %s, lhs is %s and rhs is %s\n";
    auto string = std::make_unique<char[]>(100);
    sprintf(string.get(), message_template, op,
            lua_things::type_string(t1), lua_things::type_string(t2));
    std::cout << string.get();
    exit(1);
}

void error_unop(const char* op, lua_things::Type t) {
    const char* message_template = "Type error for operator %s, expression is %s\n";
    auto string = std::make_unique<char[]>(100);
    sprintf(string.get(), message_template, op,
            lua_things::type_string(t));
    std::cout << string.get();
    exit(1);
}
