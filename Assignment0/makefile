all: exec

libs: asm-lib

asm-lib: asmAssignment0.s
	# flags meanings:
	# -g = debug symbolx
	# -f elf = output format (ELF 32 bit)
	# -o asmAssignment0.o = write assembled file to asmAssignment0.o
	nasm -g -f elf -o asmAssignment0.o asmAssignment0.s

exec: mainAssignment0.c libs
	gcc -g -m32 -c -o mainAssignment0.o mainAssignment0.c
	gcc -g -m32  mainAssignment0.o asmAssignment0.o -o mainAssignment0
	rm mainAssignment0.o asmAssignment0.o

.PHONY: clean
clean:
	rm -rf ./*.o main
