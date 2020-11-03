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
    if (t1 == lt::TABLE || t2 == lt::TABLE) { 
        return lt::TABLE;
    } else {
        return lt::BOOL;
    }
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