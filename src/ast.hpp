#ifndef ast_hpp_INCLUDED
#define ast_hpp_INCLUDED

#include <vector>
#include <string_view>
#include <string>
#include <array>
#include <initializer_list>

#include "lua_things.hpp"

enum class NodeKind : int {
    and_,
    assign,
    band,
    block,
    bnot,
    bool_val,
    bor,
    call,
    cat,
    eq,
    exp_list,
    func_def,
    ge,
    gt,
    if_,
    index,
    iover,
    le,
    len,
    lshift,
    lt,
    minus,
    mod,
    neq,
    nil_val,
    not_,
    num_val,
    or_,
    over,
    plus,
    pow,
    program,
    repeat,
    rshift,
    str_val,
    table,
    times,
    var_name,
    var_decl,
    var_list,
    var_use,
    while_,
    NO_KIND,  // Special kind for %empty rules

    // Todas as conversões são em tempo de execução
    // B2I_NODE,   // Conversion of types.
    // B2R_NODE,
    // B2S_NODE,
    // I2R_NODE,
    // I2S_NODE,
    // R2S_NODE
};

struct node {
// private:
    inline static int nr; 
    NodeKind kind = NodeKind::NO_KIND;
    lua_things::expression expr;
    std::vector<node> children;
    float f_data;
    double d_data;
    int   i_data;

    int print_node_dot();
    void print_dot();
// public:
    node() : kind(NodeKind::NO_KIND) {};
    node(NodeKind kind, lua_things::expression expr)
        : kind(kind), expr(expr) {}

    void add_child(node&& child);
    node& get_child(int idx);

    NodeKind get_kind();

    int get_data();
    void set_float_data(float data);
    float get_float_data();

    lua_things::expression& get_node_type();
    int get_child_count();

    void print_tree();
};

const char* kind2str(NodeKind kind);
NodeKind str2kind(const char* kindstr);
bool has_data(NodeKind kind);

#endif // ast_hpp_INCLUDED

