CC = gcc
CFLAGS=-Wall -W -ansi

chkml: chkml.c
	$(CC) $(CFLAGS) chkml.c -o chkml

t_dehum: t_dehum.c
	$(CC) $(CFLAGS) t_dehum.c -o t_dehum -lutil
