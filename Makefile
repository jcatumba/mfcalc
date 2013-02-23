# Makefile for mfcalc

mfcalc.bin: parserl.o parsery.o main.o
	gcc -g -o $@ main.o parserl.o parsery.o -lm -I.

parserl.o: lex.yy.c
	gcc -g -c $< -o $@

lex.yy.c: parser.lex parser.tab.c
	flex $<

parsery.o: parser.tab.c
	gcc -g -c $< -o $@

parser.tab.c: parser.y
	bison --defines=parser.tab.h $<

main.o:	main.c
	gcc -g -c $< -o $@

clean:
	rm -r *.tab.c
	rm -r *.tab.h
	rm -r *.yy.c
	rm -r *.o
	rm -r *.bin
