
void add_symbol_last_scope(const char *Name, int lineno, lua_things::Type type) {
    auto& last_scope = ctx.last_scope();
    last_scope.table.add_var(Name, lineno, type);
}

void add_symbol_last_scope(const std::string& Name, int lineno, lua_things::Type type) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_symbol_last_scope ------" << std::endl;
    std::cerr << "+++ " << Name << std::endl;
    std::cerr << "%%% " << lua_things::type_string(type) << std::endl;
    #endif
    auto& last_scope = ctx.last_scope();
    last_scope.table.add_var(Name, lineno, type);
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_symbol_global_scope(const char *Name, int lineno, lua_things::Type type) {
    auto& last_scope = ctx.scope_stack[0];
    last_scope.table.add_var(Name, lineno, type);
}

void add_symbol_global_scope(const std::string& Name, int lineno, lua_things::Type type) {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_symbol_last_scope ------" << std::endl;
    std::cerr << "+++ " << Name << std::endl;
    std::cerr << "%%% " << lua_things::type_string(type) << std::endl;
    #endif
    auto& last_scope = ctx.scope_stack[0];
    last_scope.table.add_var(Name, lineno, type);
    #ifdef DLVCDEBUG
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
}

void add_label(const char* label_name) {
    auto& last_scope = ctx.last_scope();
    last_scope.add_label(label_name);
}

void add_assign_list() {
    #ifdef DLVCDEBUG
    std::cerr << "----- add_assign_list ------" << std::endl;
    std::cerr << "Number of expressions: " << tmp::explist.size() << std::endl;
    std::cerr << "Number of variables/names: " << tmp::namelist.size() << std::endl;
    #endif
    if (tmp::explist.size() > 0 && tmp::namelist.size() != tmp::explist.size()) {
        /*
        TODO: verificar quando o último for uma chamada de função
        */
        std::cout << "Assignment list error(" << yylineno << "): number of variables "
                        "doesn't match expressions\n";
        exit(1);
    }

    auto& scope = tmp::assign_type == data_structures::assign_type::LOCAL
                  ? ctx.last_scope()
                  : ctx.global_scope();
    if (tmp::explist.size() == 0) {
        for (const auto& i : tmp::namelist) {
            scope.table.add_var(i, yylineno, lua_things::Type::NIL);
        }
    } else {
        for (size_t i = 0; i < tmp::namelist.size(); ++i) {
            const auto& name = tmp::namelist[i];
            const auto& exp_type = tmp::explist[i];

            #ifdef DLVCDEBUG
            std::cerr << "+++ " << name << std::endl;
            std::cerr << "%%% " <<lua_things::type_string(exp_type) << std::endl;
            #endif
            scope.table.add_var(name, yylineno, exp_type);
        }
    }

    #ifdef DLVCDEBUG
    std::cerr << "-----------" << std::endl;
    #endif
}

lua_things::Type add_func() {
    if (tmp::full_funcname.size() > 1) {
        add_symbol_last_scope(tmp::full_funcname[0], yylineno, lua_things::Type::TABLE);
        return lua_things::Type::TABLE;
    } else {
        add_symbol_last_scope(tmp::full_funcname[0], yylineno, lua_things::Type::FUNCTION);
        return lua_things::Type::FUNCTION;
    }
}

lua_things::Type identifier_check(const std::string& identifier ) {
    #ifdef DLVCDEBUG
    std::cerr << "----- identifier_check ------" << std::endl;
    std::cerr << "+++ " << identifier << std::endl;
    #endif
    for (int i = ctx.scope_stack.size()-1; i >= 0; --i) {
        auto& scope = ctx.scope_stack[i];
        bool is_there = scope.table.lookup_var(identifier);
        if (!is_there) {
            continue;
        }
        data_structures::variable_data data = scope.table.var_data(identifier);
        auto type = data.gettype();
        #ifdef DLVCDEBUG
        std::cerr << "%%% " << lua_things::type_string(type) << std::endl;
        std::cerr << "-----------" << std::endl;
        #endif
        return type;
    }
    #ifdef DLVCDEBUG
    std::cerr << "Nothing found" << std::endl;
    std::cerr << "-------------------------------------------------" << std::endl;
    #endif
    throw std::runtime_error("identifier does not exists.\n");
}