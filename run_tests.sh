#!/bin/env bash

[ ! -e './dlvc' ] && { printf "dlvc binary doesn't exist!\n"; exit 1; }
IFS=$'\n'

printf "RUNNING CORRECT TESTS\n"
for i in $(ls ./tests/correct/*.lua)
do
    printf "FILE: %s\n" "$i"
    ./dlvc < "$i"
    printf "\n"
done

printf "RUNNING ERROR TESTS\n"
for i in $(ls ./tests/error/*.lua)
do
    printf "FILE: %s\n" "$i"
    ./dlvc < "$i"
    printf "\n"
done
