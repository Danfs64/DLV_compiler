all: parser.cc scanner.cc
	g++ -std=c++17 parser.cc scanner.cc -ly 

scanner.cc: scanner.l
	flex scanner.l

parser.cc: parser.y
	bison parser.y --defines=parser.h --report=all

clean:
	rm parser.cc scanner.cc parser.hpp
