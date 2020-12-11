#!/bin/env bash

[ ! -e './dlvc' ] && { printf "dlvc binary doesn't exist!\n"; exit 1; }
IFS=$'\n'

printf "RUNNING TESTS\n"
for i in $(ls ./testes_novos/*.lua)
do
    printf "FILE: %s\n" "$i"
    ./dlvc < "$i"
    java -jar jasmin.jar -g jasminout.j
    java -cp "dlvc_jar.jar:." Jasmin
    printf "\n"
done

