#ifndef DATA_STRUCTURES_HPP
#define DATA_STRUCTURES_HPP

#include <string>
#include <map>
#include <tuple>

#include "lua_things.hpp"

namespace data_structures {

    class variable_data {
        int linenum;
        lua_things::Type type;

        public:
        variable_data() = default;
        variable_data(int linenum, lua_things::Type type) :
            linenum(linenum), type(type)
        {
            
        }
       
        int getline() {
            return linenum;
        }

        lua_things::Type gettype() {
            return type;
        }
    };

    class symbol_table {
        std::map<std::string, variable_data, std::less<>> table;

        void add_var(const std::string& name, int linenum, lua_things::Type type) {
            table.emplace(name, variable_data(linenum, type));
        }

        bool lookup_var(const std::string& name) {
            return table.find(name) != std::end(table);
        }

        variable_data var_data(const std::string& name) {
            return table.at(name);
        }
    };
};

#endif