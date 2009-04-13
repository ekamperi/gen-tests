CC = gcc
CFLAGS=-Wall -W -ansi

all: chkml invchkml t_dehum

chkml: chkml.c
	$(CC) $(CFLAGS) chkml.c -o chkml

invchkml: invchkml.c
	$(CC) $(CFLAGS) invchkml.c -o invchkml

t_dehum: t_dehum.c
	$(CC) $(CFLAGS) t_dehum.c -o t_dehum -lutil
