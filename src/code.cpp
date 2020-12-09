#include <iostream>
#include <fstream>
#include <functional>
#include <map>
#include <filesystem>
#include <cstring>
#include <cstdio>

#include "code.hpp"
#include "ast.hpp"

namespace fs = std::filesystem;

static fs::path jasmin_path = "cuspido2.j";
static std::ofstream stream(jasmin_path);


void gen_block_code(node& n);
void gen_code_node(node& n);

const char* jasmin_start = R"(
.class public Jasmin
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
    .limit locals 50
    .limit stack 50
)";

const char* jasmin_end = R"(
    getstatic java/lang/System/out Ljava/io/PrintStream;
    swap
    invokevirtual java/io/PrintStream/println(D)V
	return	
.end method
)";

void generate_code(node& root) {
    char program[1000];

    auto& var_decl = root.children.at(0);
    auto& var_list = var_decl.children.at(0);
    auto& exp_list = var_decl.children.at(1);
    auto& exp = exp_list.children.at(0);

    stream << jasmin_start << std::endl;
    gen_block_code(root);
    stream << jasmin_end << std::endl;


    return;
}


void gen_code_node(node& n) {
    for (auto& i : n.children) {
        gen_code_node(i);
    }

    if (n.kind == NodeKind::num_val) {
        stream << "ldc2_w " << std::to_string(n.d_data) << std::endl;
    }

    switch (n.kind) {
        case NodeKind::plus:
            stream << "dadd" << std::endl;
            break;
        default:
            break;
    }
}

void gen_block_code(node& n) {
    std::function<void(node&)> stat_analyser;
    std::function<void(node&)> var_decl_analyser;
    std::function<void(node&)> block_analyser;
    std::function<void(node&)> exp_generator;
    std::map<std::string, int> varToLocal;
    int total_vars = 0;

    exp_generator = [&] (node& exp) {
        for (auto& i : exp.children) {
            exp_generator(i);
        }

        switch (exp.kind) {
            case NodeKind::plus:
                stream << "dadd" << std::endl;
                break;
            case NodeKind::minus:
                stream << "dsub" << std::endl;
                break;
            case NodeKind::times:
                stream << "dmul" << std::endl;
                break;
            case NodeKind::over:
                stream << "ddiv" << std::endl;
                break;
            case NodeKind::num_val:
                stream << "ldc2_w " << std::to_string(exp.d_data) << std::endl;
                break;
            default:
                std::cout << "Faltou implementar algo! " << kind2str(exp.kind) << std::endl;
                break;
        }
    };

    var_decl_analyser = [&] (node& var_decl) {
        //int old_total_vars = total_vars;
        node& var_list = var_decl.children[0];
        auto& var_names = var_list.children;

        for (node& i : var_names) {
            varToLocal.emplace(i.expr.name, total_vars);
            total_vars++;
        }
        
        if (var_decl.children.size() > 1) {
            std::cout << "1!!" << std::endl;
            auto& exp_list = var_decl.children[1].children;
            for (int i = 0; i < exp_list.size(); ++i) {
                auto& name = var_names[i];
                auto& exp = exp_list[i];
                exp_generator(exp);
                stream << "dstore " << varToLocal[name.expr.name] << " ; " + name.expr.name <<std::endl;
                // astore varToLocal[name]
            }
        } else {
            for (int i = 0; i < var_names.size(); ++i) {
                auto& name = var_names[i];
                /*
                TODO: recursão para gerar código NIL
                criar novo NIL
                inicializar?
                */
                // astore varToLocal[name]
            }
        }
    };

    stat_analyser = [&] (node& n) {
        //! NÃO PODE TER UM NODE BLOCK

        switch (n.kind) {
            case NodeKind::var_decl:
                var_decl_analyser(n);
                break;
            case NodeKind::BLOCK:
                std::exit(254);
                break;
            default:
                std::cout << "Algo de errado não está certo!" << std::endl;
                break;
        }
    };

    block_analyser = [&block_analyser, &stat_analyser] (node& n) {
        for (auto& i : n.children) {
            stat_analyser(i);
        }
        /* TODO */
    };

    block_analyser(n);
}