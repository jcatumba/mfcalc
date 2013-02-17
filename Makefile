# Makefile for mfcalc

mfcalc.bin: mfcalc.tab.c mfcalc.tab.h lex.yy.c
	gcc -o $@ mfcalc.tab.c lex.yy.c -lm -I.

mfcalc.tab.c: mfcalc.y
	bison --defines=mfcalc.tab.h mfcalc.y

lex.yy.c: mfcalc.lex
	flex mfcalc.lex
