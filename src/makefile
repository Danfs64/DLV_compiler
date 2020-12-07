CC = g++
CFLAGS = -std=c++17 -O0

OBJECTS = obj/parser.o obj/scanner.o obj/error_messages.o obj/lua_things.o \
          obj/common_utils.o obj/parser_utils.o obj/ast.o

.PHONY: MKDIR clean

all: MKDIR dlvc

MKDIR:
	mkdir -p obj

dlvc: $(OBJECTS)
	$(CC) $(CFLAGS) $(USER_DEFINES) $^ -o $@

obj/parser.o: parser.cc
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@ 

obj/scanner.o: scanner.cc
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@ 

obj/error_messages.o: error_messages.cpp
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@ 

obj/lua_things.o: lua_things.cpp
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@

obj/common_utils.o: common_utils.cpp
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@

obj/parser_utils.o: parser_utils.cpp
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@

obj/ast.o: ast.cpp
	$(CC) $(CFLAGS) $(USER_DEFINES) -c $^ -o $@

scanner.cc: scanner.l
	flex scanner.l

parser.cc: parser.y
	bison parser.y --defines=parser.h --report=all

clean:
	rm parser.cc scanner.cc parser.hpp parser.output
	rm -r obj
