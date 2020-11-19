#include <string>
#include <vector>
#include "data_structures.hpp"
#include "lua_things.hpp"
#include "common_utils.hpp"


namespace global {
    std::vector<std::string> namelist;
    std::vector<lua_things::expression> explist;
    data_structures::assign_type assign_type;
    std::vector<std::tuple<std::string, var_type>> varlist;
    std::string last_identifier;
    std::vector<std::string> full_funcname;
    list_type assign_list_type;
    list_type prev_assign_list_type;
    std::string for_init_id;
    const std::string null_identifier;
    bool is_args = false;
    bool is_index = false;
    bool lock_list = false;
}
