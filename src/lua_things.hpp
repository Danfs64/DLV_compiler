#ifndef LUA_THINGS_HPP
#define LUA_THINGS_HPP

#include <stdexcept>

namespace lua_things {
    namespace {
        const char* type_strings[] = {
            "NIL",
            "BOOL",
            "NUM",
            "STR",
            "FUNCTION",
            "TABLE"
        };
    };
    using type_error = std::runtime_error;

    enum class Type : int {
        NIL,
        BOOL,
        NUM,
        STR,
        FUNCTION,
        TABLE,
    };

    struct expression {
        Type type;
        bool is_named;
        std::string name;
        bool is_return;

        expression()
        : type(Type::NIL), is_named(false), name(""), is_return(false)  {}
        
        expression(lua_things::Type type, std::string name, bool is_named, bool is_return)
        : type(type), is_named(is_named), name(name), is_return(is_return)  {}

        expression(const expression& e)
        : type(e.type), is_named(e.is_named), name(e.name), is_return(e.is_return) {}
        
        expression(lua_things::Type type)
        : type(type), is_named(false), name(""), is_return(false)  {}
    };

    inline const char* type_string(Type t) {
        int idx = static_cast<int>(t);
        return type_strings[idx];
    }

    Type check_arithm(Type t1, Type t2);
    Type check_eq(Type t1, Type t2);
    Type check_neq(Type t1, Type t2);
    Type check_order(Type t1, Type t2);
    Type check_logical(Type t1, Type t2);
    Type check_bitwise(Type t1, Type t2);
    Type check_cat(Type t1, Type t2);
    Type check_bitwise(Type t);
    Type check_arithm(Type t);
    Type check_not(Type t);
    Type check_len(Type t);
    Type check_call(Type t);
    Type check_index(Type t1, Type t2);

    #define o(func)  \
        expression func (expression t1, expression t2);
    o(check_arithm)
    o(check_eq)
    o(check_neq)
    o(check_order)
    o(check_logical)
    o(check_bitwise)
    o(check_cat)
    o(check_index)
    #undef o

    #define o(func)  \
        expression func (expression t1);
    o(check_arithm)
    o(check_bitwise)
    o(check_not)
    o(check_len)
    o(check_call)
    #undef o
}

#endif