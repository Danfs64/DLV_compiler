#include "common_utils.hpp"
#include "lua_things.hpp"

const char* type_error_message = "Incompatible types.";

using lt = lua_things::Type;

lua_things::Type lua_things::check_arithm(lua_things::Type t1, lua_things::Type t2) { 
    if (t1 == lt::NUM && t2 == lt::NUM) {                
        return lt::NUM;                                    
    } else if (t1 == lt::TABLE || t2 == lt::TABLE) {     
        return lt::TABLE;                                  
    } else if (t1 == lt::STR && t2 == lt::NUM ||         
                t1 == lt::NUM && t2 == lt::STR) {         
        /* Suponhamos que a string é um float no             
            formato correto                                   
        */                                                   
        return lt::NUM;                                    
    } else {                                                 
        throw lua_things::type_error(type_error_message);                
    }                                                        
};

lua_things::Type lua_things::check_arithm(lua_things::Type t) { 
    if (t == lt::NUM) {                
        return lt::NUM;                                    
    } else if (t == lt::TABLE) {     
        return lt::TABLE;                                  
    } else if (t == lt::STR) {         
        /* Suponhamos que a string é um float no             
            formato correto                                   
        */                                                   
        return lt::NUM;                                    
    } else {                                                 
        throw lua_things::type_error(type_error_message);                
    }                                                        
};

lua_things::Type lua_things::check_eq(lua_things::Type t1, lua_things::Type t2) {
    if (t1 == lt::TABLE || t2 == lt::TABLE) {
        return lt::TABLE;
    } else {
        return lt::BOOL;
    }
}

lua_things::Type lua_things::check_neq(lua_things::Type t1, lua_things::Type t2) {
    if (t1 == lt::TABLE || t2 == lt::TABLE) {
        return lt::TABLE;
    } else {
        return lt::BOOL;
    }
}

lua_things::Type lua_things::check_order(lua_things::Type t1, lua_things::Type t2) { 
    if (t1 == lt::TABLE || t2 == lt::TABLE) { 
        return lt::TABLE;
    } else if (t1 == lt::NIL || t2 == lt::NIL) {
        throw lua_things::type_error(type_error_message);
    } else if (t1 == t2) {
        return lt::BOOL; 
    } else { 
        throw lua_things::type_error(type_error_message);
    }
} 

lua_things::Type lua_things::check_logical(lua_things::Type t1, lua_things::Type t2) { 
//     if (t1 == lt::TABLE || t2 == lt::TABLE) { 
//         return lt::TABLE;
//     } else {
//         return lt::BOOL;
//     }
    return lt::TABLE;
}

lua_things::Type lua_things::check_bitwise(lua_things::Type t1, lua_things::Type t2) { 
    if (t1 == lt::TABLE || t2 == lt::TABLE) { 
        return lt::TABLE;
    } else if (t1 == lt::NIL || t2 == lt::NIL) {
        throw lua_things::type_error(type_error_message);
    } else {
        return lt::NUM;
    }
}

lua_things::Type lua_things::check_bitwise(lua_things::Type t) {
    if (t == lt::TABLE) { 
        return lt::TABLE;
    } else if (t == lt::NIL) {
        throw lua_things::type_error(type_error_message);
    } else {
        return lt::BOOL;
    }
}

lua_things::Type lua_things::check_cat(lua_things::Type t1, lua_things::Type t2) { 
    if (t1 == lt::TABLE || t2 == lt::TABLE) { 
        return lt::TABLE;
    } else if (t1 == lt::NIL || t2 == lt::NIL) {
        throw lua_things::type_error(type_error_message);
    } else {
        return lt::STR;
    }
}

lua_things::Type lua_things::check_not(lua_things::Type t) {
    if (t == lt::TABLE) { 
        return lt::TABLE;
    } else {
        return lt::BOOL;
    }
}

lua_things::Type lua_things::check_len(lua_things::Type t) {
    if (t == lt::TABLE) { 
        return lt::TABLE;
    } else if (t == lt::STR) {
        return lt::NUM;
    } else {
        throw lua_things::type_error(type_error_message);
    }
}

lua_things::Type lua_things::check_call(lua_things::Type t) {
    if (t == lt::FUNCTION || t == lt::TABLE) {
        return lt::TABLE;
    } else {
        throw lua_things::type_error(type_error_message);
    }
}

lua_things::Type lua_things::check_index(lua_things::Type t1, lua_things::Type t2) {
    if (t1 == lt::TABLE /*&& t2 != lt::NIL*/) {
        return lt::TABLE;
    } else {
        throw lua_things::type_error(type_error_message);
    }
}

#define o(func)                                                                                        \
    lua_things::expression lua_things:: func (lua_things::expression t1, lua_things::expression t2) {  \
        lt t = func (t1.type, t2.type);                                                                \
        return expression(t);                                                                          \
    }
o(check_arithm)
o(check_eq)
o(check_neq)
o(check_order)
o(check_logical)
o(check_bitwise)
o(check_cat)
o(check_index)
#undef o

#define o(func)                                                             \
    lua_things::expression lua_things:: func (lua_things::expression t1) {  \
        lt t = func (t1.type);                                              \
        return expression(t);                                               \
    }
o(check_arithm)
o(check_bitwise)
o(check_not)
o(check_len)
o(check_call)
#undef o