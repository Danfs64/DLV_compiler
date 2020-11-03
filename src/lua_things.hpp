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
}

#endif