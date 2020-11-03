#ifndef DATA_STRUCTURES_HPP
#define DATA_STRUCTURES_HPP

#include <string>
#include <map>
#include <tuple>
#include <set>
#include <vector>
#include <algorithm>

#include "lua_things.hpp"

namespace data_structures {
    namespace {
        using label_set = std::set<std::string>;
    }

    enum class scope_type : int {
        LOOP,
        NON_LOOP,
        FUNCTION,
    };

    class variable_data {
        int linenum;
        lua_things::Type type;

        public:
        variable_data() = default;
        variable_data(int linenum, lua_things::Type type) :
            linenum(linenum), type(type) {}
       
        int getline() {
            return linenum;
        }

        lua_things::Type gettype() {
            return type;
        }
    };

    class symbol_table {
        std::map<std::string, variable_data, std::less<>> table;

        public:
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

    struct scope {
        const scope_type type;
        symbol_table table;
        label_set goto_labels;
        label_set goto_calls;

        scope(scope_type type) : type(type) {}
    };

    struct context {
        std::vector<scope> scope_stack;

        bool verify_break() const {
            for (auto iter = std::rbegin(scope_stack); iter != std::rend(scope_stack); ++iter) {
                auto& s = *iter;
                
                if (s.type == scope_type::LOOP) {
                    return true;
                } else if (s.type == scope_type::FUNCTION) {
                    return false;
                }
            }
            return false;
        }

        bool verify_goto_calls() const {
            label_set all_labels;
            label_set all_calls;
            for (const auto& s : scope_stack) {
                /* union of all labels sets */
                all_labels.insert(std::begin(s.goto_labels), std::end(s.goto_labels));
                all_calls.insert(std::begin(s.goto_calls), std::end(s.goto_calls));
            }

            label_set difference;
            std::set_difference(
                std::begin(all_calls),
                std::end(all_calls),
                std::begin(all_labels),
                std::end(all_labels),
                std::inserter(difference, std::begin(difference))
            );
            return difference.size() == 0;
        }
    };
};

#endif
