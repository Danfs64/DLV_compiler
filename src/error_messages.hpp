#ifndef ERROR_MESSAGES_HPP
#define ERROR_MESSAGES_HPP

#include "lua_things.hpp"

void error_binop(const char* op, lua_things::Type t1, lua_things::Type t2);
void error_unop(const char* op, lua_things::Type t);
void error_call(lua_things::Type t);
void error_index(lua_things::Type t1, lua_things::Type t2);
void error_break();
void error_identifier_dont_exist(const std::string& id);
void error_goto();
void assignment_list_error();

#endif
