#ifndef ERROR_MESSAGES_HPP
#define ERROR_MESSAGES_HPP

#include "lua_things.hpp"

void error_binop(const char* op, lua_things::Type t1, lua_things::Type t2);
void error_unop(const char* op, lua_things::Type t);

#endif