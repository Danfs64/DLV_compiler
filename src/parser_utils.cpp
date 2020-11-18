#include <array>
#include <iostream>
#include <tuple>
#include <string>
#include "common_utils.hpp"
#include "lua_things.hpp"
#include "data_structures.hpp"

extern data_structures::context ctx;
extern int yylineno;

void add_namelist(const std::string& name) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_namelist ------ " << yylineno << std::endl;
    #endif
    if (global::assign_list_type != list_type::EXPLIST) {
        #ifdef DLVCDEBUG
        std::cerr << "~~~ " << name << std::endl;
        #endif
        global::namelist.emplace_back(name);
    }
    #ifdef DLVCDEBUG
      else {
          std::cerr << "list_type is EXPLIST" << std::endl;
      }
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void pop_namelist() {
    #ifdef DLVCDEBUG
    std::cerr << "----- pop_namelist ------ " << yylineno << std::endl;
    #endif
    if (global::namelist.size() > 0 &&
        global::assign_type != data_structures::assign_type::LOCAL) {
        #ifdef DLVCDEBUG
        std::cerr << "POP" << std::endl;
        #endif
        global::namelist.pop_back();
    }
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_explist(lua_things::Type type) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_explist ------ " << yylineno << std::endl;
    #endif
    if (global::assign_list_type == list_type::EXPLIST and !global::is_args) {
        #ifdef DLVCDEBUG
        std::cerr << "~~~ " << lua_things::type_string(type) << std::endl;
        #endif
        global::explist.emplace_back(type);
    }
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_explist(lua_things::expression type) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_explist ------ " << yylineno << std::endl;
    #endif
    if (global::assign_list_type == list_type::EXPLIST and !global::is_args) {
        #ifdef DLVCDEBUG
        std::cerr << "~~~ " << lua_things::type_string(type.type) << std::endl;
        #endif
        global::explist.emplace_back(type);
    }
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void pop_explist() {
    #ifdef DLVCDEBUG
    std::cerr << "----- pop_explist ------ " << yylineno << std::endl;
    #endif
    if (global::explist.size() > 0) {
        #ifdef DLVCDEBUG
        std::cerr << "POP" << std::endl;
        #endif
        global::explist.pop_back();
    }
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_symbol_last_scope(const char *Name, int lineno, lua_things::Type type) {
    auto& last_scope = ctx.last_scope();
    last_scope.table.add_var(Name, lineno, type);
}

void add_symbol_last_scope(const std::string& Name, int lineno, lua_things::Type type) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_symbol_last_scope ------ " << yylineno << std::endl;
    std::cerr << "+++ " << Name << std::endl;
    std::cerr << "%%% " << lua_things::type_string(type) << std::endl;
    #endif
    auto& last_scope = ctx.last_scope();
    last_scope.table.add_var(Name, lineno, type);
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_symbol_global_scope(const char *Name, int lineno, lua_things::Type type) {
    auto& last_scope = ctx.scope_stack[0];
    last_scope.table.add_var(Name, lineno, type);
}

void add_symbol_global_scope(const std::string& Name, int lineno, lua_things::Type type) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_symbol_last_scope ------ " << yylineno << std::endl;
    std::cerr << "+++ " << Name << std::endl;
    std::cerr << "%%% " << lua_things::type_string(type) << std::endl;
    #endif
    auto& last_scope = ctx.scope_stack[0];
    last_scope.table.add_var(Name, lineno, type);
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_label(const char* label_name) {
    auto& last_scope = ctx.last_scope();
    last_scope.add_label(label_name);
}

void add_assign_list() {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_assign_list ------ " << yylineno << std::endl;
    std::cerr << "Number of expressions: " << global::explist.size() << std::endl;
    std::cerr << "Number of variables/names: " << global::namelist.size() << std::endl;
    if (global::assign_type == data_structures::assign_type::LOCAL) {
        std::cerr << "LOCAL" << std::endl;
    } else {
        std::cerr << "GLOBAL" << std::endl;
    }
    #endif
    if (global::explist.size() > 0 && global::namelist.size() != global::explist.size()) {
        /*
        TODO: verificar quando o último for uma chamada de função
        */
        #ifdef DLVCDEBUG
        for (const auto& i : global::namelist) {
            std::cerr << "¢¢¢ " << i << std::endl;
        }
        for (const auto& i : global::explist) {
            std::cerr << "§§§ " << lua_things::type_string(i.type) << std::endl;
        }
        #endif

        std::cerr << "Assignment list error(" << yylineno << "): number of variables "
                        "doesn't match expressions\n";
        exit(1);
    }

    auto& scope = global::assign_type == data_structures::assign_type::LOCAL
                  ? ctx.last_scope()
                  : ctx.global_scope();
    if (global::explist.size() == 0) {
        for (const auto& i : global::namelist) {
            scope.table.add_var(i, yylineno, lua_things::Type::NIL);
        }
    } else {
        for (size_t i = 0; i < global::namelist.size(); ++i) {
            const auto& name = global::namelist[i];
            const auto& exp_type = global::explist[i];

            #ifdef DLVCDEBUG
            std::cerr << "+++ " << name << std::endl;
            std::cerr << "%%% " <<lua_things::type_string(exp_type.type) << std::endl;
            #endif
            scope.table.add_var(name, yylineno, exp_type.type);
        }
    }

    #ifdef DLVCDEBUG
    std::cerr << "-----------" << std::endl;
    #endif
}

lua_things::Type add_func() {
    if (global::full_funcname.size() > 1) {
        add_symbol_last_scope(global::full_funcname[0], yylineno, lua_things::Type::TABLE);
        return lua_things::Type::TABLE;
    } else {
        add_symbol_last_scope(global::full_funcname[0], yylineno, lua_things::Type::FUNCTION);
        return lua_things::Type::FUNCTION;
    }
}

lua_things::Type identifier_check(const std::string& identifier ) {
    #ifdef DLVCDEBUG
    std::cerr << "----- identifier_check ------ " << yylineno << std::endl;
    std::cerr << "+++ " << identifier << std::endl;
    #endif
    for (int i = ctx.scope_stack.size()-1; i >= 0; --i) {
        auto& scope = ctx.scope_stack[i];
        bool is_there = scope.table.lookup_var(identifier);
        if (!is_there) {
            continue;
        }
        data_structures::variable_data data = scope.table.var_data(identifier);
        auto type = data.gettype();
        #ifdef DLVCDEBUG
        std::cerr << "%%% " << lua_things::type_string(type) << std::endl;
        std::cerr << "-----------" << std::endl;
        #endif
        return type;
    }
    #ifdef DLVCDEBUG
    std::cerr << "Nothing found" << std::endl;
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
    throw std::runtime_error("identifier does not exists.\n");
}

void add_builtin() {
    const constexpr std::array builtin {
        std::tuple{"rawget",         lua_things::Type::FUNCTION},
        std::tuple{"utf8",           lua_things::Type::TABLE   },
        std::tuple{"assert",         lua_things::Type::FUNCTION},
        std::tuple{"coroutine",      lua_things::Type::TABLE   },
        std::tuple{"tostring",       lua_things::Type::FUNCTION},
        std::tuple{"error",          lua_things::Type::FUNCTION},
        std::tuple{"pcall",          lua_things::Type::FUNCTION},
        std::tuple{"rawequal",       lua_things::Type::FUNCTION},
        std::tuple{"os",             lua_things::Type::TABLE   },
        std::tuple{"type",           lua_things::Type::FUNCTION},
        std::tuple{"require",        lua_things::Type::FUNCTION},
        std::tuple{"tonumber",       lua_things::Type::FUNCTION},
        std::tuple{"loadfile",       lua_things::Type::FUNCTION},
        std::tuple{"arg",            lua_things::Type::TABLE   },
        std::tuple{"load",           lua_things::Type::FUNCTION},
        std::tuple{"package",        lua_things::Type::TABLE   },
        std::tuple{"debug",          lua_things::Type::TABLE   },
        std::tuple{"ipairs",         lua_things::Type::FUNCTION},
        std::tuple{"xpcall",         lua_things::Type::FUNCTION},
        std::tuple{"table",          lua_things::Type::TABLE   },
        std::tuple{"dofile",         lua_things::Type::FUNCTION},
        std::tuple{"bit32",          lua_things::Type::TABLE   },
        std::tuple{"math",           lua_things::Type::TABLE   },
        std::tuple{"string",         lua_things::Type::TABLE   },
        std::tuple{"setmetatable",   lua_things::Type::FUNCTION},
        std::tuple{"io",             lua_things::Type::TABLE   },
        std::tuple{"_VERSION",       lua_things::Type::STR     },
        std::tuple{"next",           lua_things::Type::FUNCTION},
        std::tuple{"collectgarbage", lua_things::Type::FUNCTION},
        std::tuple{"rawset",         lua_things::Type::FUNCTION},
        std::tuple{"getmetatable",   lua_things::Type::FUNCTION},
        std::tuple{"print",          lua_things::Type::FUNCTION},
        std::tuple{"select",         lua_things::Type::FUNCTION},
        std::tuple{"_G",             lua_things::Type::TABLE   },
        std::tuple{"pairs",          lua_things::Type::FUNCTION},
        std::tuple{"rawlen",         lua_things::Type::FUNCTION},
    };

    for (const auto &[id, type] : builtin) {
        add_symbol_global_scope(id, 0, type);
    }
}
