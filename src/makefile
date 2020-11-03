all: parser.cc scanner.cc error_messages.cpp lua_things.cpp
	g++ -std=c++17 $? -ly 

scanner.cc: scanner.l
	flex scanner.l

parser.cc: parser.y
	bison parser.y --defines=parser.h --report=all

clean:
	rm parser.cc scanner.cc parser.hpp parser.output
