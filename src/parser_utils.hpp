#ifndef PARSER_UTILS_HPP
#define PARSER_UTILS_HPP

#include <vector>
#include <tuple>
#include <string>

#include "lua_things.hpp"
#include "data_structures.hpp"

void add_namelist(const std::string& name);
void pop_namelist();
void add_explist(lua_things::Type type);
void pop_explist();
void add_symbol_last_scope(const char *Name, int lineno, lua_things::Type type);
void add_symbol_last_scope(const std::string& Name, int lineno, lua_things::Type type);
void add_symbol_global_scope(const char *Name, int lineno, lua_things::Type type);
void add_symbol_global_scope(const std::string& Name, int lineno, lua_things::Type type);
void add_label(const char* label_name);
void add_assign_list();
lua_things::Type add_func();
lua_things::Type identifier_check(const std::string& identifier);
void add_builtin();

#endif
