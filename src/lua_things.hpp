#ifndef LUA_THINGS_HPP
#define LUA_THINGS_HPP

#include <stdexcept>

namespace lua_things {
    namespace {
        const char* type_error_message = "Incompatible types.";
        /*
        DEFINIR REGEX AQUI
        */
    };
    using type_error = std::runtime_error;

    enum class Type {
        NIL,
        BOOL,
        NUM,
        STR,
        FUNCTION,
        TABLE,
    };

    #define o(op)                                                \
    Type operator##op##(Type t1, Type t2) {                      \
        if (t1 == Type::NUM && t2 == Type::NUM) {                \
            return Type::NUM;                                    \
        } else if (t1 == Type::TABLE || t2 == Type::TABLE) {     \
            return Type::TABLE;                                  \
        } else if (t1 == Type::STR && t2 == Type::NUM ||         \
                   t1 == Type::NUM && t2 == Type::STR) {         \
            /* Suponhamos que a string é um float no             \
               formato correto                                   \
            */                                                   \
            return Type::NUM;                                    \
        } else {                                                 \
            throw type_error(type_error_message);                \
        }                                                        \
    };
    o(+)
    o(-)
    o(/)
    o(*)
    o(%)    
    o(^)
    #undef o
}

#endif