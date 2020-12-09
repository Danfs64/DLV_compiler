#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <iostream>
#include <cstdio>
#include <cstring>
#include <memory>
#include <initializer_list>

#include "ast.hpp"
#include "lua_things.hpp"

using Type = lua_things::expression;

void node::add_child(node&& child) {
    if (child.kind != NodeKind::NO_KIND)
        children.push_back(child);
}

node& node::get_child(int idx) {
    return children[idx];
}

NodeKind node::get_kind() {
    return kind;
}

int node::get_data() {
  return i_data;   
}

void node::set_float_data(float data) {
    f_data = data;
}

float node::get_float_data() {
  return f_data;   
}

Type& node::get_node_type() {
    return expr;
}

int node::get_child_count() {
    return children.size();
}

int node::var_count() {
    if (kind == NodeKind::var_name) {
        return 1;
    }
    int total = 0;
    for (auto& i : children) {
        total += i.var_count();
    }
    return total;
}

int node::node_count() {
    int total = 1;
    for (auto& i : children) {
        total += i.node_count();
    }
    return total;
}


// Dot output

static int nr;

const char* kind2str(NodeKind kind) {
    switch(kind) {
        case NodeKind::and_:      return "and";
        case NodeKind::assign:    return "=";
        case NodeKind::band:      return "&";
        case NodeKind::block:     return "block";
        case NodeKind::bnot:      return "~";
        case NodeKind::bool_val:  return "bool_val";
        case NodeKind::bor:       return "|";
        case NodeKind::call:      return "(...)";
        case NodeKind::cat:       return "..";
        case NodeKind::else_:     return "else";
        case NodeKind::elif:   return "elseif";
        case NodeKind::eq:        return "==";
        case NodeKind::exp_list:  return "exp_list";
        case NodeKind::func_def:  return "function";
        case NodeKind::ge:        return ">=";
        case NodeKind::gt:        return ">";
        case NodeKind::if_:       return "if";
        case NodeKind::index:     return ".";
        case NodeKind::iover:     return "//";
        case NodeKind::len:       return "#";
        case NodeKind::le:        return "<=";
        case NodeKind::lshift:    return "<<";
        case NodeKind::lt:        return "<";
        case NodeKind::minus:     return "-";
        case NodeKind::mod:       return "%";
        case NodeKind::neq:       return "~=";
        case NodeKind::nil_val:   return "nil";
        case NodeKind::not_:      return "not";
        case NodeKind::num_val:   return "num_val";
        case NodeKind::or_:       return "or";
        case NodeKind::over:      return "/";
        case NodeKind::plus:      return "+";
        case NodeKind::pow:       return "^";
        case NodeKind::program:   return "program";
        case NodeKind::repeat:    return "repeat";
        case NodeKind::rshift:    return ">>";
        case NodeKind::str_val:   return "str_val";
        case NodeKind::table:     return "{}";
        case NodeKind::times:     return "*";
        case NodeKind::var_decl:  return "var_decl";
        case NodeKind::var_list:  return "var_list";
        case NodeKind::var_name:  return "var_name";
        case NodeKind::var_use:   return "var_use";
        case NodeKind::while_:    return "while";
        case NodeKind::BLOCK:     return "BLOCK";

        // case NodeKind::b2i_node:      return "B2I";
        // case NodeKind::b2r_node:      return "B2R";
        // case NodeKind::b2s_node:      return "B2S";
        // case NodeKind::i2r_node:      return "I2R";
        // case NodeKind::i2s_node:      return "I2S";
        // case NodeKind::r2s_node:      return "R2S";
        default:            return "ERROR!!";
    }
}

NodeKind str2kind(const char* kindstr) {
    static std::map<std::string, NodeKind> dict = {
        {"and",      NodeKind::and_},
        {"=",        NodeKind::assign},
        {"&",        NodeKind::band},
        {"block",    NodeKind::block},
        {"~",        NodeKind::bnot},
        {"bool_val", NodeKind::bool_val},
        {"|",        NodeKind::bor},
        {"(...)",    NodeKind::call},
        {"..",       NodeKind::cat},
        {"else",     NodeKind::else_},
        {"elseif",   NodeKind::elif},
        {"==",       NodeKind::eq},
        {"",         NodeKind::exp_list},
        {"function", NodeKind::func_def},
        {">=",       NodeKind::ge},
        {">",        NodeKind::gt},
        {"if",       NodeKind::if_},
        {".",        NodeKind::index},
        {"//",       NodeKind::iover},
        {"#",        NodeKind::len},
        {"<=",       NodeKind::le},
        {"<<",       NodeKind::lshift},
        {"<",        NodeKind::lt},
        {"-",        NodeKind::minus},
        {"%",        NodeKind::mod},
        {"~=",       NodeKind::neq},
        {"nil",      NodeKind::nil_val},
        {"not",      NodeKind::not_},
        {"",         NodeKind::num_val},
        {"or",       NodeKind::or_},
        {"/",        NodeKind::over},
        {"+",        NodeKind::plus},
        {"^",        NodeKind::pow},
        {"program",  NodeKind::program},
        {"repeat",   NodeKind::repeat},
        {">>",       NodeKind::rshift},
        {"str_val",  NodeKind::str_val},
        {"{}",       NodeKind::table},
        {"*",        NodeKind::times},
        {"var_decl", NodeKind::var_decl},
        {"var_list", NodeKind::var_list},
        {"var_name", NodeKind::var_name},
        {"var_use",  NodeKind::var_use},
        {"while",    NodeKind::while_},
    };

    NodeKind kind;
    try {
        kind = dict.at(kindstr);
    } catch (std::exception& e) {
        kind = NodeKind::program;
    }
    return kind;
}

bool has_data(NodeKind kind) {
    switch(kind) {
        case NodeKind::bool_val:
        case NodeKind::num_val:
        case NodeKind::str_val:
        case NodeKind::var_decl:
        case NodeKind::var_use:
            return true;
        default:
            return false;
    }
}


int node::print_node_dot() {
    int my_nr = nr++;
    const char* label_template = "node%d[label=\"%s\"];\n";
    const char* kindstr = kind2str(kind);
    /*
    auto& node = *this;
    std::fprintf(stderr, "node%d[label=\"", my_nr);
    auto node_type = node.get_node_type().type;
    auto node_kind = node.get_kind();
    if (node_type != Type::NO_TYPE) {
        std::fprintf(stderr, "(%s)",
                     Ezlang::get_type_text(node_type).data());
    }

    switch (node_kind) {
        case NodeKind::VAR_DECL_NODE:
        case NodeKind::VAR_USE_NODE:
            std::fprintf(stderr, "%s@",
                         "FOOBAR");
            break;
        default:
            std::fprintf(stderr, "%s", kind2str(node_kind).data());
    }

    if (has_data(node_kind)) {
        switch (node_kind) {
            case NodeKind::REAL_VAL_NODE:
                std::fprintf(stderr, "$.2f", node.f_data);
                break;
            case NodeKind::STR_VAL_NODE:
                std::fprintf(stderr, "@%d", node.i_data);
                break;
            default:
                std::fprintf(stderr, "%d", node.i_data);
                break;
        }
    }
    std::fprintf(stderr, "\"];\n");

    for (auto& i : node.children) {
        int child_nr = i.print_node_dot();
        std::fprintf(stderr, "node%d -> node%d;\n", my_nr, child_nr);
    }
    */

    std::string name_str = kindstr;
    switch (kind) {
        case NodeKind::var_use:
        case NodeKind::var_name:
            char label_str[100];
            name_str += "@" + expr.name;
            std::fprintf(stderr, label_template, my_nr, name_str.c_str());
            break;
        case NodeKind::num_val:
            name_str += "@" + std::to_string(d_data);
            std::fprintf(stderr, label_template, my_nr, name_str.c_str());
            break;
        case NodeKind::bool_val:
            name_str += "@" + std::to_string(b_data);
            std::fprintf(stderr, label_template, my_nr, name_str.c_str());
            break;
        case NodeKind::str_val:
            name_str += "@" + s_data;
            std::fprintf(stderr, label_template, my_nr, name_str.c_str());
            break;
        default:
            std::fprintf(stderr, label_template, my_nr, kindstr);
    }
    for (auto& i : this->children) {
        int child_nr = i.print_node_dot();
        std::fprintf(stderr, "node%d -> node%d;\n", my_nr, child_nr);
    }

    return my_nr;
}

void node::print_dot() {
    nr = 0;
    std::fprintf(stderr, "digraph {\ngraph [ordering=\"out\"];\n");
    print_node_dot();
    std::fprintf(stderr, "}\n");
}
