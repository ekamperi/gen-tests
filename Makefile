CC = gcc
CFLAGS=-Wall -W -ansi

chkml: chkml.c
	$(CC) $(CFLAGS) chkml.c -o chkml

