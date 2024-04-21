.PHONY: bison main

CC = gcc
FLAGS = -w -lm
SOURCES = main.c y.tab.c y.tab.h yylex.c

all: bison main

bison:
	bison -y -Wcounterexamples -d parser.y

main:
	$(CC) $(SOURCES) -o main $(FLAGS)