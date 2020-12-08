#include <iostream>
#include <fstream>
#include <filesystem>
#include <cstring>
#include <cstdio>

#include "code.hpp"
#include "ast.hpp"

namespace fs = std::filesystem;

const char* jasmin_template = R"(
.class public Jasmin
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
    %s ; <- code comes here
	return	
.end method
)";

void generate_code(node& root) {
    fs::path jasmin_path = "cuspido2.j";
    std::ofstream stream(jasmin_path);
    char program[1000];

    auto& var_decl = root.children.at(0);
    auto& var_list = var_decl.children.at(0);
    auto& exp_list = var_decl.children.at(1);
    auto& exp = exp_list.children.at(0);

    const char* basic_template = R"(
        .limit locals 2
        .limit stack 4

        ldc2_w %f 
        ldc2_w %f 
        dadd
        dstore 0

        getstatic java/lang/System/out Ljava/io/PrintStream;
        dload 0
        invokevirtual java/io/PrintStream/println(D)V
    )";

    std::sprintf(program, basic_template,
        exp.children[0].d_data,
        exp.children[1].d_data
    );

    char other_program[2000];
    std::sprintf(other_program, jasmin_template, program);
    stream << other_program << std::endl;

    return;
}


void foo(node& n) {

    for (auto& i : n.children) {
        foo(i);
    }
    /*
        Cuspo código do nó pai
    */
}