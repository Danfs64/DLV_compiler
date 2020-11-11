#include "error_messages.hpp"

#include <memory>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <string>
#include "lua_things.hpp"

extern int yylineno;

void print_semerror_start() {
    const char* message_template = "SEMANTIC ERROR (%d): ";
    char semantic_start[100];
    std::sprintf(semantic_start, message_template, yylineno);
    std::cerr << semantic_start;
}

void error_binop(const char* op, lua_things::Type t1, lua_things::Type t2) {
    print_semerror_start();
    const char* message_template = "Binary operator '%s'. LHS is %s and RHS is %s\n";
    auto string = std::make_unique<char[]>(100);
    std::sprintf(string.get(), message_template, op,
                 lua_things::type_string(t1), lua_things::type_string(t2));
    std::cerr << string.get();
    std::exit(2);
}

void error_unop(const char* op, lua_things::Type t) {
    print_semerror_start();
    const char* message_template = "Unary operator '%s' error. Expression is %s\n";
    auto string = std::make_unique<char[]>(100);
    std::sprintf(string.get(), message_template, op, lua_things::type_string(t));
    std::cerr << string.get();
    std::exit(3);
}

void error_call(lua_things::Type t) {
    print_semerror_start();
    const char* message_template = "Calling error. Attempt to call a %s\n";
    auto string = std::make_unique<char[]>(100);
    std::sprintf(string.get(), message_template, lua_things::type_string(t));
    std::cerr << string.get();
    std::exit(4);
}

void error_index(lua_things::Type t1, lua_things::Type t2) {
    print_semerror_start();
    const char* message_template = "Error for index operator. LHS is %s and RHS is %s\n";
    auto string = std::make_unique<char[]>(100);
    std::sprintf(string.get(), message_template, lua_things::type_string(t1),
                 lua_things::type_string(t2));
    std::cerr << string.get();
    std::exit(5);
}

void error_break() {
    print_semerror_start();
    const char* message_template = "break used in a non-loop block.\n";
    std::cerr << message_template;
    std::exit(6);
}

void error_identifier_dont_exist(const std::string& id) {
    print_semerror_start();
    const char* message_template = "identifier '%s' does not exist.\n";
    auto c_id = std::make_unique<char[]>(id.size() + 2);
    std::strcpy(c_id.get(), id.c_str());
    auto error_message = std::make_unique<char[]>(std::strlen(message_template) + id.size());
    std::sprintf(error_message.get(), message_template, c_id.get());
    std::cerr << error_message.get();
    std::exit(7);
}
