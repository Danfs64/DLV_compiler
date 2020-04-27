


scanner.c: scanner.l
	flex scanner.l

parser.c: parser.y
	bison parser.y --defines=parser.h --report=all
parser.h: parser.c
	bison parser.y --defines=parser.h --report=all

all: parser.c scanner.c parser.h
	gcc parser.c scanner.c -ly 

clean:
	rm parser.c scanner.c parser.h
