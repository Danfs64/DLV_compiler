#ifndef common_utils_hpp_INCLUDED
#define common_utils_hpp_INCLUDED

#include <string>
#include <vector>
#include "data_structures.hpp"
#include "lua_things.hpp"

enum class var_type : int {
    NAME,
    INDEX,
};

enum class list_type : int {
    VARLIST,
    EXPLIST,
    NO_TYPE,
};

namespace global {
    /*
     * Várias variáveis globais em um namespace para ter o mínimo de
     * organização.
     */
    extern std::vector<std::string> namelist;
    extern std::vector<lua_things::Type> explist;
    extern data_structures::assign_type assign_type;
    extern std::vector<std::tuple<std::string, var_type>> varlist;
    extern std::string last_identifier;
    extern std::vector<std::string> full_funcname;
    extern list_type assign_list_type;
    extern list_type prev_assign_list_type;
    extern std::string for_init_id;
    extern const std::string null_identifier;
    extern bool is_args;
}
#endif // common_utils_hpp_INCLUDED

