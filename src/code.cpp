#include <iostream>
#include <fstream>
#include <sstream>
#include <ios>
#include <functional>
#include <map>
#include <filesystem>
#include <cstring>
#include <cstdio>

#include "code.hpp"
#include "ast.hpp"

#define ASTORE(I, N) \
    stream << "astore " << std::to_string(I) \
           << " ; " << N << std::endl;

#define BOOLVALUE() \
    stream << "invokeinterface dlvc/LuaType/boolValue()Z 1" << std::endl;

namespace fs = std::filesystem;

static fs::path jasmin_path = "jasminout.j";
static std::ofstream fstream(jasmin_path);
static const char* luaTypeDescriptor = "Ldlvc/LuaType;";


void gen_block_code(node& n, std::stringstream& stream,
                    std::map<std::string, int>& varToLocal);

std::vector<std::stringstream> all_streams;

static const char* print_jasmin = R"(
.method public static print(Ldlvc/LuaType;)Ldlvc/LuaType;
.limit locals 10
.limit stack 10
getstatic java/lang/System/out Ljava/io/PrintStream;
aload 0
invokevirtual java/io/PrintStream/println(Ljava/lang/Object;)V

new dlvc/LuaNil
dup
invokespecial dlvc/LuaNil/<init>()V
areturn
.end method
)";

static const char* read_jasmin = R"(
.method public static read()Ldlvc/LuaType;
.limit locals 10
.limit stack 10

invokestatic dlvc/LuaOpResolver/readLine()Ldlvc/LuaType;

areturn
.end method
)";

const char* jasmin_start = R"(
.class public Jasmin
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
    .limit locals 50
    .limit stack 50
)";

const char* jasmin_end = R"(
    ; getstatic java/lang/System/out Ljava/io/PrintStream;
    ; aload 0
    ; invokevirtual java/io/PrintStream/println(Ljava/lang/Object;)V
    return	
.end method
)";

void generate_code(node& root) {

    fstream << jasmin_start << std::endl;

    std::stringstream ss;
    std::map<std::string, int> varToLocal;
    gen_block_code(root, ss, varToLocal);
    fstream << ss.str();
    fstream << jasmin_end << std::endl;

    for (auto& ss : all_streams) {
        fstream << ss.str() << std::endl;
    }

    fstream << print_jasmin << std::endl;
    fstream << read_jasmin << std::endl;
}

void gen_block_code(node& n, std::stringstream& stream,
                    std::map<std::string, int>& varToLocal) {
    std::function<void(node&)> stat_analyser;
    std::function<void(node&)> var_decl_analyser;
    std::function<void(node&)> block_analyser;
    std::function<void(node&)> if_analyser;
    std::function<void(node&)> for_analyser;
    std::function<void(node&)> while_analyser;
    std::function<void(node&)> assign_analyser;
    std::function<void(node&)> function_analyser;
    std::function<void(node&)> call_analyser;
    std::function<void(node&)> var_use_analyser;
    std::function<void(node&)> return_analyser;
    std::function<void(node&)> repeat_analyser;
    std::function<void(node&)> exp_generator;
    std::function<void(node&)> table_generator;
    int total_labels = 1;
    int total_vars = varToLocal.size() + 1;


    repeat_analyser = [&] (node& repeat_node) {
        std::string repeat_start_label = "LABEL" + std::to_string(total_labels++);
        node& block = repeat_node.get_child(0);
        node& until = repeat_node.get_child(1);

        stream << repeat_start_label << ":" << std::endl;
        block_analyser(block);
        exp_generator(until);
        BOOLVALUE();
        stream << "ifeq " << repeat_start_label << std::endl;
    };

    var_use_analyser = [&] (node& var_node) {
        std::string& var_name = var_node.expr.name;
        int local_number = varToLocal.at(var_name);
        stream << "aload " << local_number << " ; " << var_name << std::endl;
        if (var_node.get_child_count() == 1) { // É uma tabela
            node& child = var_node.get_child(0);
            exp_generator(child);
            // stream << "new dlvc/LuaString" << std::endl;
            // stream << "ldc " << child.expr.name << std::endl;
            // stream << "invokespecial dlvc/LuaString/<init>(Ljava/lang/String;)V" << std::endl;
            stream << "invokestatic dlvc/LuaTable/get(Ldlvc/LuaType;Ldlvc/LuaType;)Ldlvc/LuaType; " << std::endl;
        } else {
            // stream << "aload " << varToLocal[var_name]  << std::endl;
        }
    };


    table_generator = [&] (node& table_node) {
        // std::cout << kind2str(table_node.kind) << std::endl;
        stream << R"(
            new dlvc/LuaTable
            dup
            invokespecial dlvc/LuaTable/<init>()V)" << std::endl;
        double start_num_key = 1;
        for (auto& i : table_node.children) {
            stream << "dup ; duplica referencia para cada set" << std::endl;
            if (i.get_child_count() == 1) {
                stream << "new dlvc/LuaNumber" << std::endl;
                stream << "dup" << std::endl;
                stream << "ldc2_w " << std::to_string(start_num_key++) << std::endl;
                stream << "invokespecial dlvc/LuaNumber/<init>(D)V" << std::endl;
                // std::cout << kind2str(i.get_child(0).kind) << std::endl;
                exp_generator(i.get_child(0));
            } else {
                exp_generator(i.get_child(0));
                exp_generator(i.get_child(1));
            }
            stream << "invokevirtual dlvc/LuaTable/set("
                   << luaTypeDescriptor << luaTypeDescriptor << ")V"
                   << std::endl;
        }
    };

    call_analyser = [&] (node& call_node) {
        std::string& fname = call_node.get_child(0).expr.name;
        if (call_node.get_child_count() > 1) {
            node& exp_list = call_node.get_child(1);
            for (auto& i : exp_list.children)
                exp_generator(i);

            stream << "invokestatic Jasmin/" << fname << "(";
            for (int i = 0; i < exp_list.get_child_count(); ++i)
                stream << luaTypeDescriptor;
            stream << ")" << luaTypeDescriptor << std::endl;
        } else {
            stream << "invokestatic Jasmin/" << fname << "(" << ")" << luaTypeDescriptor << std::endl;;
        }
    };

    return_analyser = [&] (node& return_node) {
        if (return_node.get_child_count() > 0) {
            node& exp = return_node.children.at(0).get_child(0);
            exp_generator(exp);
            stream << "areturn" << std::endl;
        }
    };
    
    function_analyser = [&] (node& func_node) {
        std::stringstream new_stream;
        std::map<std::string, int> newVarToLocal;

        std::string funcname = func_node.children.at(0).expr.name;
        node& fbody = func_node.children.at(1);
        bool has_args = fbody.get_child_count() > 1;

        if (has_args) {
            node& var_list = fbody.children.at(0);
            int newTotalVars = 0; // Zero porque o método é estático
            for (auto& i : var_list.children) {
                std::string arg_name = i.expr.name;
                newVarToLocal.emplace(arg_name, newTotalVars++);
            }
        }

        node& block_node = fbody.children.at(has_args ? 1 : 0);

        // Adicionar metadados main([Ljava/lang/String;)V"
        new_stream << ".method public static " << funcname
                   << "(";
        if (has_args) {
            node& var_list = fbody.children.at(0);
            for (int i = 0; i < var_list.get_child_count(); ++i) {
                new_stream << "Ldlvc/LuaType;";
            }
        }
        new_stream << ")Ldlvc/LuaType;" << std::endl;
        new_stream << "    .limit locals 50" << std::endl;
        new_stream << "    .limit stack 50" << std::endl;

        gen_block_code(block_node, new_stream, newVarToLocal);

        // default nil return type
        
        new_stream << R"(
            ; [[DEFAULT RETURN VALUE]]
            new dlvc/LuaNil
            dup
            invokespecial dlvc/LuaNil/<init>()V
            areturn
            .end method)" << std::endl;
        all_streams.push_back(std::move(new_stream));
    };

    assign_analyser = [&] (node& assign_node) {
        stream << " ; ASSIGN" << std::endl;
        node& var_list = assign_node.children.at(0);
        node& exp_list = assign_node.children.at(1);

        for (node& i : exp_list.children) {
            exp_generator(i);
        }

        for (auto iter = std::rbegin(var_list.children);
             iter != std::rend(var_list.children);
             ++iter) {
            node& var_name_node = *iter;
            std::string& var_name = var_name_node.expr.name;

            int local = varToLocal.at(var_name);
            if (var_name_node.get_child_count() > 0) {
                stream << "aload " << std::to_string(local) << std::endl;
                // Atualizar dado de uma tabela
                node* start_node = &var_name_node.get_child(0);
                while (start_node->get_child_count() > 0) {
                    exp_generator(*start_node);
                    // stream << "ldc " << start_node->expr.name << std::endl;
                    stream << "invokestatic dlvc/LuaTable/get(Ldlvc/LuaType;Ldlvc/LuaType;)Ldlvc/LuaType; "
                           << std::endl;
                    start_node = &start_node->get_child(0);
                }
                stream << "swap ; Mantém a expressão acima da tabela" << std::endl;
                exp_generator(*start_node);
                // stream << "ldc " << start_node->expr.name << std::endl;
                stream << "swap ; Mantém a expressão acima da string" << std::endl;
                stream << "invokestatic dlvc/LuaTable/put(Ldlvc/LuaType;Ldlvc/LuaType;Ldlvc/LuaType;)V "
                       << std::endl;
            } else {
                ASTORE(local, var_name);
            }
        }
    };

    while_analyser = [&] (node& while_node) {
        std::string while_exit_label = "EXIT_LABEL" + std::to_string(total_labels);
        std::string while_start_label = "START_LABEL" + std::to_string(total_labels);
        total_labels++;
        node& exp = while_node.children.at(0);
        node& block_node = while_node.children.at(1);

        stream << while_start_label << ":" << std::endl;
        stream << " ; while expression" << std::endl;
        exp_generator(exp);
        stream << "invokeinterface dlvc/LuaType/boolValue()Z 1" << std::endl;
        stream << "ifeq " << while_exit_label << std::endl; // Se o valor retornado for 0 (falso) ir para label

        stream << "\t ; [WHILE] block start" << std::endl;
        block_analyser(block_node);
        stream << "goto " << while_start_label << std::endl;
        stream << while_exit_label << ":" << std::endl;
    };

    if_analyser = [&] (node& if_node) {
        node& if_exp = if_node.children[0];
        node& if_block = if_node.children[1];
        std::string if_label_name = "LABEL" + std::to_string(total_labels);
        std::string if_exit_label = "IF_EXIT_LABEL" + std::to_string(total_labels++);

        exp_generator(if_exp);
        stream << "invokeinterface dlvc/LuaType/boolValue()Z 1" << std::endl;
        stream << "ifeq " << if_label_name << std::endl; // Se o valor retornado for 0 (falso) ir para label
        // total_labels++;
        block_analyser(if_block);
        stream << "goto " << if_exit_label << std::endl;
        stream << if_label_name << ":" << std::endl;

        // Ver elseif-else
        
        if (if_node.get_child_count() > 2) {
            for (auto iter = std::begin(if_node.children) + 2;
                 iter != std::end(if_node.children);
                 ++iter) {
                auto& i = *iter;
                if (i.get_child_count() > 1) {
                    std::string i_label_name = "LABEL" + std::to_string(total_labels++);
                    node& i_exp = i.get_child(0);
                    node& i_block = i.get_child(1);
                    exp_generator(if_exp);
                    stream << "invokeinterface dlvc/LuaType/boolValue()Z 1" << std::endl;
                    stream << "ifeq " << i_label_name << std::endl;
                    block_analyser(i_block);
                    stream << "goto " << if_exit_label << std::endl;
                    stream << i_label_name << ":" << std::endl;
                } else {
                    node& i_block = i.get_child(0);
                    block_analyser(i_block);
                }
            }
        }
        
        stream << if_exit_label << ":" << std::endl;
    };

    for_analyser = [&] (node& for_node) {
        bool custom_inc = false;
        node& var_node = for_node.children.at(0);
        node& exp1 = for_node.children.at(1);
        node& exp2 = for_node.children.at(2);
        std::string for_start_label = "LABEL" + std::to_string(total_labels);
        total_labels++; 

        if (for_node.get_child_count() == 5) {
            custom_inc = true;
        }

        auto& inc_var = for_node.children[0];

        // Increment start value
        exp_generator(exp1);
        varToLocal.emplace(var_node.expr.name, total_vars);
        int var_label_num = total_vars;
        total_vars++;
        stream << "astore " << std::to_string(var_label_num) << " ; " << var_node.expr.name << std::endl;

        stream << for_start_label << ":" << std::endl;
        // BLOCK code
        stream << " ; for loop block" << std::endl;
        if (custom_inc) {
            node& block_node = for_node.children.at(4);
            block_analyser(block_node);
        } else {
            node& block_node = for_node.children.at(3);
            block_analyser(block_node);
        }
        // node& block_node = for_node.children.at(custom_inc ? 4 : 3);
        // block_analyser(block_node);

        // Increment
        stream << "aload " + std::to_string(var_label_num) << " ; " << var_node.expr.name << std::endl;
        if (custom_inc) {
            node& inc_exp = for_node.children.at(3);
            exp_generator(inc_exp);
            stream << "invokestatic dlvc/LuaOpResolver/plus(Ldlvc/LuaType;Ldlvc/LuaType;)Ldlvc/LuaType; " << std::endl;
        } else {
            // Generate LuaNumber with 1
            stream << R"(
                new dlvc/LuaNumber
                dup
                ldc2_w 1.0
                invokespecial dlvc/LuaNumber/<init>(D)V
                invokestatic dlvc/LuaOpResolver/plus(Ldlvc/LuaType;Ldlvc/LuaType;)Ldlvc/LuaType;
            )" << std::endl;
        }
        stream << "astore " << std::to_string(var_label_num) << " ; " << var_node.expr.name << std::endl;


        // Exp2 limit
        stream << "aload " + std::to_string(var_label_num) << " ; " << var_node.expr.name << std::endl;
        exp_generator(exp2);
        stream << "invokestatic dlvc/LuaOpResolver/gt(Ldlvc/LuaType;Ldlvc/LuaType;)Ldlvc/LuaType;"
               << std::endl;
        stream << "invokeinterface dlvc/LuaType/boolValue()Z 1" << std::endl;
        stream << "ifeq " << for_start_label << std::endl; // Se o valor retornado for 0 (falso) sair do for
    };

    exp_generator = [&] (node& exp) {
        if (exp.kind != NodeKind::table and
            exp.kind != NodeKind::call  and
            exp.kind != NodeKind::var_use) {
            for (auto& i : exp.children) {
                // table_entry não é uma expressão
                    exp_generator(i);
            }
        }

        #define o(OP)\
            "invokestatic dlvc/LuaOpResolver/"              \
            OP                                              \
            "(Ldlvc/LuaType;Ldlvc/LuaType;)Ldlvc/LuaType; " \

        #define u(OP)\
            "invokestatic dlvc/LuaOpResolver/"              \
            OP                                              \
            "(Ldlvc/LuaType;)Ldlvc/LuaType; " \

        std::string& var_name = exp.expr.name;
        int local_number = -1;
        switch (exp.kind) {
            case NodeKind::plus:
                stream << o("plus") << std::endl;
                break;
            case NodeKind::minus:
                if (exp.get_child_count() == 2) {
                    stream << o("minus") << std::endl;
                } else {
                    stream << u("negative") << std::endl;
                }
                break;
            case NodeKind::times:
                stream << o("times") << std::endl;
                break;
            case NodeKind::pow:
                stream << o("pow") << std::endl;
                break;
            case NodeKind::over:
                stream << o("over") << std::endl;
                break;
            case NodeKind::iover:
                stream << o("iover") << std::endl;
                break;
            case NodeKind::mod:
                stream << o("mod") << std::endl;
                break;
            case NodeKind::cat:
                stream << o("cat") << std::endl;
                break;
            case NodeKind::len:
                stream << u("len") << std::endl;
                break;
            case NodeKind::not_:
                stream << u("not") << std::endl;
                break;
            case NodeKind::and_:
                stream << o("and") << std::endl;
                break;
            case NodeKind::or_:
                stream << o("or") << std::endl;
                break;
            case NodeKind::bnot:
                if (exp.get_child_count() == 1) {
                    stream << u("bnot") << std::endl;
                } else {
                    stream << o("bxor") << std::endl;
                }
                break;
            case NodeKind::band:
                stream << o("band") << std::endl;
                break;
            case NodeKind::bor:
                stream << o("bor") << std::endl;
                break;
            case NodeKind::rshift:
                stream << o("rshift") << std::endl;
                break;
            case NodeKind::lshift:
                stream << o("lshift") << std::endl;
                break;
            case NodeKind::gt:
                stream << o("gt") << std::endl;
                break;
            case NodeKind::ge:
                stream << o("ge") << std::endl;
                break;
            case NodeKind::le:
                stream << o("le") << std::endl;
                break;
            case NodeKind::lt:
                stream << o("lt") << std::endl;
                break;
            case NodeKind::eq:
                stream << o("eq") << std::endl;
                break;
            case NodeKind::neq:
                stream << o("neq") << std::endl;
                break;
            case NodeKind::table:
                table_generator(exp);
                break;
            case NodeKind::call:
                call_analyser(exp);
                break;
            case NodeKind::num_val:
                stream << "new dlvc/LuaNumber" << std::endl;
                stream << "dup" << std::endl;
                stream << "ldc2_w " << std::to_string(exp.d_data) << std::endl;
                stream << "invokespecial dlvc/LuaNumber/<init>(D)V" << std::endl;
                break;
            case NodeKind::bool_val:
                stream << "new dlvc/LuaBool" << std::endl;
                stream << "dup" << std::endl;
                stream << "ldc " << std::to_string(exp.b_data) << std::endl;
                stream << "invokespecial dlvc/LuaBool/<init>(Z)V" << std::endl;
                break;
            case NodeKind::nil_val:
                stream << "new dlvc/LuaNil" << std::endl;
                stream << "dup" << std::endl;
                stream << "invokespecial dlvc/LuaNil/<init>()V" << std::endl;
                break;
            case NodeKind::str_val:
                stream << "new dlvc/LuaString" << std::endl;
                stream << "dup" << std::endl;
                stream << "ldc " << '\"' << exp.s_data << '\"' << std::endl;
                stream << "invokespecial dlvc/LuaString/<init>(Ljava/lang/String;)V" << std::endl;
                break;
            case NodeKind::var_use:
                // local_number = varToLocal.at(var_name);
                // stream << "aload " << local_number << " ; " << var_name << std::endl;
                var_use_analyser(exp);
                break;
            default:
                std::cout << "Faltou implementar algo! " << kind2str(exp.kind) << std::endl;
                break;
        }

        #undef u
        #undef o
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
            // std::cout << "1!!" << std::endl;
            auto& exp_list = var_decl.children[1].children;
            for (int i = 0; i < exp_list.size(); ++i) {
                auto& name = var_names[i];
                auto& exp = exp_list[i];
                exp_generator(exp);
                stream << "astore " << varToLocal[name.expr.name] << " ; " + name.expr.name <<std::endl;
                // astore varToLocal[name]
            }
        } else {
            for (int i = 0; i < var_names.size(); ++i) {
                auto& name = var_names[i];
                // Preenche com nil
                stream << "new dlvc/LuaNil" << std::endl;
                stream << "dup" << std::endl;
                stream << "invokespecial dlvc/LuaNil/<init>()V" << std::endl;
                stream << "astore " << varToLocal[name.expr.name] << " ; " + name.expr.name <<std::endl;
            }
        }
    };

    stat_analyser = [&] (node& n) {
        //! NÃO PODE TER UM NODE BLOCK

        switch (n.kind) {
            case NodeKind::var_decl:
                var_decl_analyser(n);
                break;
            case NodeKind::if_:
                if_analyser(n);
                break;
            case NodeKind::for_:
                for_analyser(n);
                break;
            case NodeKind::while_:
                while_analyser(n);
                break;
            case NodeKind::assign:
                assign_analyser(n);
                break;
            case NodeKind::func_def:
                function_analyser(n);
                break;
            case NodeKind::return_:
                return_analyser(n);
                break;
            case NodeKind::repeat:
                repeat_analyser(n);
                break;
            case NodeKind::call:
                call_analyser(n);
                /*
                 * Se a chamada é um statement significa que o valor retornado
                 * deve ser jogado fora
                 */
                stream << "pop" << std::endl;
                break;
            case NodeKind::BLOCK:
                std::exit(254);
                break;
            default:
                std::cout << "Algo de errado não está certo! " << kind2str(n.kind) << std::endl;
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
