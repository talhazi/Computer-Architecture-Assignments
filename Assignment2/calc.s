%macro print_format 2
	pushad

	push %2
	push %1
	call printf
	add esp,8

	popad
%endmacro

%macro print_format_err 2
	pushad

	push %2
	push %1
	push dword[stderr]
	call fprintf
	add esp,12

	popad
%endmacro

%macro is_special 0
	cmp byte [buffer],'+'
	je adder

	cmp byte [buffer],'q'
	je quit

	cmp byte [buffer],'p'
	je pop_and_print

	cmp byte [buffer],'d'
	je duplicate

	cmp byte [buffer],'&'
	je and_bitwise

	cmp byte [buffer],'n'
	je num_of_bytes

%endmacro

%macro oct_to_decimal 1		;converting octal to decimal
	pushad
	mov [STKSZ_arg], %1       ;CHANGE 0q...
	popad
%endmacro

%macro call_func_1p 1
	pushad
	call %1
	mov dword [return_ptr],eax
	popad
%endmacro

%macro call_func_2p 2
	pushad
	push %2
	call %1
	add esp, 4
	mov dword [return_ptr],eax
	popad
%endmacro

%macro call_func_3p 3
	pushad
	push %3
	push %2
	call %1
	add esp, 8
	mov dword [return_ptr],eax
	popad
%endmacro

%macro get_input 0
	pushad

	push dword [stdin]
	push MAX_LENGTH
	push buffer
	call fgets
	add esp, 12

	popad
%endmacro

%macro if_debug 1 
	cmp dword [debug],1
	jne %%end_if
	%1
	%%end_if:
%endmacro

%macro print_debug 2
	pushad
	push %1
	push %2
	push dword [stderr]
	call fprintf
	add esp, 12
	popad
%endmacro


%macro make_link 1
	push 5
	call malloc
	add esp, 4

	mov byte [eax+DATA], %1
%endmacro

%define DATA 0
%define	NEXT 1
%define LINK_SIZE 5
%define	MAX_LENGTH 80			;MAX length for buffer

%define PRINTF(fmt, value)	print_format fmt, value

%define PRINTF_ERR(fmt, value)	print_format_err fmt, value


section .data
    active: dd 1
    STKSZ_arg: dd 5
    debug: dd 0					; DEBUG
	count_operation: dd 0       ; the number of operation
    count_stack: dd 0           ; count the numbers in the stack
    base: dd 1
    result: dd 1        		; HOLDS the result of converted input
	link_first: dd 0
	link_curr: dd 0
	carry_flag: db 0
	n_bytes: dd 0
	link_first_free: dd 0
	link_second_free: dd 0

section .rodata
	calc_line: db "calc: ", 0
	error_msg_overflow: db "Error: Operand Stack Overflow",10,0
    error_msg_insufficient: db "Error: Insufficient Number of Arguments on Stack",10,0
	check: db "when will this end",10,0
	newline: db 10,0
	fmt_s: db "%s", 0
	fmt_c: db "%c",10,0
	fmt_d: db "%d",0
	fmt_o: db "%o", 0
	new_line: db 10, 0
	debug_push_msg: db "Pushed number: %s", 0
	debug_pop_msg: db "Popped number: ", 0
	debug_push_result: db "Pushed result: ",0


section .bss
	return_ptr: resb 4
	SPP: resb 4
	SPP_main: resb 4
	buffer: resb MAX_LENGTH
	link_print: resb 5


section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern getchar 
  extern fgets 
  extern stdout
  extern stdin
  extern stderr


main:
	push ebp
	mov ebp, esp
	mov ebx, dword[ebp+8]	;ARGC arg
	mov ecx, dword[ebp+12]	; ptr to argv

	mov eax, dword [STKSZ_arg]

	cmp ebx, 1
	je .no_size

	cmp ebx,2
	jne .debug_and_size

	.debug_or_size:
	add ecx,4
	mov edx,ecx
	mov ecx,dword[ecx]
	cmp word[ecx],'-d'
	jne .size

	mov dword[debug],1
	jmp .no_size

	.size:
	mov ecx,edx
	mov ecx, dword [ecx]			; ecx = argv[1]

	push ecx
	call oatoi
	add esp, 4

	mov dword [STKSZ_arg], eax
	jmp .no_size

	.debug_and_size:
	mov dword[debug],1
	add ecx, 4
	mov edx,ecx
	mov ecx,dword[ecx]

	cmp word[ecx],'-d'
	jne .change_stack_arg

	mov ecx,edx
	add ecx,4
	mov ecx,dword[ecx]

	.change_stack_arg:	

	push ecx
	call oatoi
	add esp, 4

	mov dword [STKSZ_arg], eax

	.no_size:
	shl eax, 2
	push 1
	push eax
	call calloc
	add esp, 8

	; eax = address of stack
	mov dword [SPP], eax
	mov dword [SPP_main], eax

	call myCalc

	xor edx,edx
	mov edx, dword [count_operation]
	PRINTF(fmt_o,edx)
	PRINTF(fmt_s,new_line)
	mov esp,ebp
	pop ebp
	ret


end:
	pop ebp
	ret

myCalc:
	push ebp
	mov ebp, esp

	myCalc_loop:
	cmp dword [active],0
	je .end

	print_format fmt_s, calc_line
	get_input
	is_special
	jmp add_new_list
	jmp myCalc_loop

	.end:
	pop ebp
	ret


add_new_list:	;adding the number to the stack
	; check if overflow
	xor ebx,ebx
	mov ebx, dword [count_stack]
	cmp ebx, dword [STKSZ_arg]
	jl .ok
	PRINTF(fmt_s,error_msg_overflow)
	jmp myCalc_loop

	.ok:
	xor ebx,ebx
	mov ebx, buffer

	if_debug{print_debug ebx,debug_push_msg}

	.loop:
	cmp byte [ebx], 10
	je .return
	push ebx
	push LINK_SIZE
	call malloc
	add esp, 4
	pop ebx
	movzx ecx, byte [ebx]			
	sub ecx, '0'
	mov byte [eax+DATA], cl			; set link data
	mov edx, dword [SPP]
	mov edx, dword [edx]
	mov dword [eax+NEXT], edx		; set link next
	mov edx, dword [SPP]
	mov dword [edx], eax
	inc ebx
	jmp .loop

	.return:

	add dword [SPP], 4
	inc dword [count_stack]
	jmp myCalc_loop


oatoi:
	push ebp
	mov ebp, esp

	mov ebx, dword [ebp+8]			; ebx= char* str
	mov eax, 0

	.loop:
	cmp byte [ebx], 0
	je .return

	movzx ecx, byte [ebx]
	sub ecx, '0'
	shl eax, 3
	add eax, ecx

	inc ebx
	jmp .loop

	.return:
	pop ebp
	ret

pop_and_print:
	inc dword [count_operation]
	mov eax, dword [SPP]
	mov ebx, dword[SPP_main]
	cmp eax, dword [SPP_main]

	jne .ok
	PRINTF(fmt_s,error_msg_insufficient)
	jmp myCalc_loop

	.ok:
	sub eax, 4
	mov eax, dword [eax]		; eax = link* first

	mov dword[link_first_free],eax

	cmp dword[debug],0
	je .dont_print

	PRINTF_ERR(fmt_s,debug_pop_msg)

	.dont_print:
	push eax
	call print_list
	add esp, 4

	PRINTF(fmt_s, new_line)		

	.return:

	push dword[link_first_free]
	call free_operand
	add esp,4

	sub dword [SPP], 4
	mov eax, dword [SPP]
	mov dword [eax], 0
	dec dword[count_stack]
	jmp myCalc_loop


print_list:
	push ebp
	mov ebp, esp

	mov eax, dword [ebp+8]
	cmp eax, 0
	je .return

	push eax
	push dword [eax+NEXT]
	call print_list
	add esp, 4

	pop eax

	movzx ebx, byte [eax+DATA]
	PRINTF(fmt_o,ebx)

	.return:
	pop ebp
	ret

adder:
	inc dword [count_operation]

	cmp dword [count_stack],2
	jge .ok
	PRINTF(fmt_s,error_msg_insufficient)
	jmp myCalc_loop

	.ok:
	push ebp
	mov ebp, esp
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	mov eax, dword [SPP]
	sub eax,4
	mov ebx, dword [eax]
	sub eax,4
	mov ecx, dword [eax]
	push ebx
	push ecx

	call make_add_list
	add esp,8

	.return:
	dec dword[count_stack]
	mov esp,ebp
	pop ebp
	jmp myCalc_loop

make_add_list:
	push ebp
	mov ebp,esp
	xor edx,edx
	xor eax,eax
	mov ebx, [ebp+8]
	mov ecx, [ebp+12]

	mov dword[link_first_free],ebx
	mov dword[link_second_free],ecx

	mov dword [carry_flag],0
	mov dword[link_curr],0
	mov dword[link_first],0

	.loop:
	cmp ebx,0		;checking if null
	je .first_null
	cmp ecx,0
	je .second_null		

	xor edx,edx
	movzx edx, byte[ebx+DATA]
	add dl, byte[ecx+DATA]
	add edx, dword[carry_flag]
	mov dword[carry_flag],8
	and dword[carry_flag],edx
	shr byte[carry_flag],3

	and edx,7						;edx has the 3 bits of the number, and carry_flag has the carry

	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte [eax+DATA], dl

	cmp dword[link_curr],0
	jne .move_on

	mov dword[link_first],eax

	.move_on:
	cmp dword[link_curr],0
	je .dont_att

	mov edx,dword[link_curr]
	mov dword[edx+NEXT],eax

	.dont_att:
	mov dword[link_curr],eax

	mov dword[eax+NEXT],0

	mov ebx,dword[ebx+NEXT]
	mov ecx,dword[ecx+NEXT]

	jmp .loop

	.first_null:
	cmp ecx,0
	je .both_null
	
	xor edx,edx
	movzx edx, byte[ecx+DATA]
	add edx, dword[carry_flag]
	mov dword[carry_flag],8
	and dword[carry_flag],edx
	shr byte[carry_flag],3

	and edx,7

	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte [eax+DATA], dl

	mov edx,dword[link_curr]
	mov dword[edx+NEXT],eax
	mov dword[eax+NEXT],0
	mov dword[link_curr],eax

	mov ecx,dword[ecx+NEXT]

	jmp .first_null

	.second_null:
	cmp ebx,0
	je .both_null


	xor edx,edx
	movzx edx, byte[ebx+DATA]
	add edx, dword[carry_flag]
	mov dword[carry_flag],8
	and dword[carry_flag],edx
	shr byte[carry_flag],3

	and edx,7

	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte [eax+DATA], dl

	mov edx,dword[link_curr]
	mov dword[edx+NEXT],eax
	mov dword[eax+NEXT],0
	mov dword[link_curr],eax

	mov ebx,dword[ebx+NEXT]

	jmp .second_null

	.both_null:
	cmp dword[carry_flag],0
	je .end
	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte [eax+DATA], 1
	mov dword [eax+NEXT],0
	mov edx, dword[link_curr]
	mov dword[edx+NEXT],eax

	.end:

	push dword[link_first_free]
	call free_operand
	add esp,4

	push dword[link_second_free]
	call free_operand
	add esp,4

	sub dword[SPP],4
	mov eax,dword[SPP]
	mov dword[eax],0		
	sub dword[SPP],4
	mov eax,dword[SPP]
	mov dword[eax],0		
	mov edx, dword[link_first]
	mov dword[eax],edx

	cmp dword[debug],0
	je .dont_print

	PRINTF_ERR(fmt_s,debug_push_result)

	mov eax,[link_first]
	push eax
	call print_list_debug
	add esp,4

	PRINTF_ERR(fmt_s,new_line)

	.dont_print:
	add dword[SPP],4
	pop ebp
	ret

quit:
	push ebp
	mov ebp,esp
	.loop:

	cmp dword [count_stack], 0
	je .end

	sub dword[SPP],4
	mov eax,dword[SPP]
	mov eax, dword [eax]		; eax = link* first

	push eax
	call free_operand
	add esp,4

	dec dword [count_stack]

	jmp .loop

	.end:

	mov eax,[SPP_main]

	push eax
	call free
	add esp,4

	mov dword [active],0
	mov esp,ebp
	pop ebp
	jmp myCalc_loop


duplicate:
	inc dword [count_operation]

	cmp dword [count_stack],1
	jge .overflow_check
	PRINTF(fmt_s,error_msg_insufficient)
	jmp myCalc_loop

	.overflow_check:
	xor ebx,ebx
	mov ebx, dword [count_stack]
	cmp ebx, dword [STKSZ_arg]
	jl .ok
	PRINTF(fmt_s,error_msg_overflow)
	jmp myCalc_loop

	.ok:
	push ebp
	mov ebp, esp
	xor ebx, ebx
	xor edx, edx
	mov eax, dword [SPP]
	sub eax,4
	mov ebx, dword [eax]
	push ebx

	call make_duplicate_list
	add esp,4

	.return:
	inc dword[count_stack]
	mov esp,ebp
	pop ebp
	jmp myCalc_loop

make_duplicate_list: 	
	push ebp
	mov ebp,esp
	xor edx,edx
	xor eax,eax
	mov ebx, [ebp+8]	; get the above list-number

	mov dword[link_curr],0
	mov dword[link_first],0

	.loop:
	cmp ebx,0		;checking if null
	je .end	

	xor edx,edx
	movzx edx, byte[ebx+DATA]

	xor eax,eax
	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte [eax+DATA], dl
	cmp dword[link_curr],0
	jne .move_on
	mov dword[link_first],eax

	.move_on:
	cmp dword[link_curr],0
	je .dont_att
	mov edx,dword[link_curr]
	mov dword[edx+NEXT],eax

	.dont_att:
	mov dword[eax+NEXT],0
	mov dword[link_curr],eax
	
	mov ebx,dword[ebx+NEXT]
	jmp .loop

	.end:
	mov eax,dword[SPP]
	mov edx, dword[link_first]
	mov dword[eax],edx

	cmp dword[debug],0
	je .dont_print

	PRINTF_ERR(fmt_s,debug_push_result)

	mov eax,[link_first]
	push eax
	call print_list_debug
	add esp,4

	PRINTF_ERR(fmt_s,new_line)

	.dont_print:
	add dword[SPP],4
	pop ebp
	ret

and_bitwise:
	inc dword [count_operation]

	cmp dword [count_stack],2
	jge .ok
	PRINTF(fmt_s,error_msg_insufficient)
	jmp myCalc_loop

	.ok:
	push ebp
	mov ebp, esp
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	mov eax, dword [SPP]
	sub eax,4
	mov ebx, dword [eax]
	sub eax,4
	mov ecx, dword [eax]
	push ebx
	push ecx

	call make_and_list
	add esp,8

	.return:
	dec dword[count_stack]
	mov esp,ebp
	pop ebp
	jmp myCalc_loop

make_and_list:
	push ebp
	mov ebp,esp
	xor edx,edx
	xor eax,eax
	mov ebx, [ebp+8]
	mov ecx, [ebp+12]

	mov dword[link_first_free],ebx
	mov dword[link_second_free],ecx

	mov dword[link_curr],0
	mov dword[link_first],0

	.loop:
	cmp ebx,0		;checking if null
	je .end
	cmp ecx,0
	je .end	

	xor edx,edx
	movzx edx, byte[ebx+DATA]
	and dl, byte[ecx+DATA]

	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte [eax+DATA], dl

	cmp dword[link_curr],0
	jne .move_on

	mov dword[link_first],eax

	.move_on:
	cmp dword[link_curr],0
	je .dont_att

	mov edx,dword[link_curr]
	mov dword[edx+NEXT],eax

	.dont_att:
	mov dword[link_curr],eax

	mov dword[eax+NEXT],0

	mov ebx,dword[ebx+NEXT]
	mov ecx,dword[ecx+NEXT]

	jmp .loop

	.end:

	push dword[link_first_free]
	call free_operand
	add esp,4

	push dword[link_second_free]
	call free_operand
	add esp,4

	sub dword[SPP],4
	mov eax,dword[SPP]
	mov dword[eax],0			
	sub dword[SPP],4
	mov eax,dword[SPP]
	mov dword[eax],0			
	mov edx, dword[link_first]
	mov dword[eax],edx


	cmp dword[debug],0
	je .dont_print

	PRINTF_ERR(fmt_s,debug_push_result)

	mov eax,[link_first]
	push eax
	call print_list_debug
	add esp,4

	PRINTF_ERR(fmt_s,new_line)

	.dont_print:
	add dword[SPP],4
	pop ebp
	ret

num_of_bytes:
	inc dword [count_operation]

	cmp dword [count_stack],1
	jge .ok
	PRINTF(fmt_s,error_msg_insufficient)
	jmp myCalc_loop

	.ok:
	push ebp
	mov ebp, esp
	xor ebx, ebx
	xor edx, edx
	mov eax, dword [SPP]
	sub eax,4
	mov ebx, dword [eax]
	push ebx

	call make_n_list
	add esp,4

	.return:
	mov esp,ebp
	pop ebp
	jmp myCalc_loop

make_n_list: 	
	push ebp
	mov ebp,esp
	xor edx,edx
	xor eax,eax
	xor ecx,ecx 		;hold the number of bits
	mov ebx, [ebp+8]	; get the above list-number

	mov dword[link_first_free],ebx

	mov dword[link_curr],0
	mov dword[link_first],0

	.loop:
	cmp dword[ebx+NEXT],0		;checking if next is null
	je .next_is_null	

	add ecx,3

	mov ebx,dword [ebx+NEXT]

	jmp .loop

	.next_is_null:
	
	mov edx,7
	
	and dl,byte[ebx+DATA]

	cmp edx,0
	je .make_byte_list

	cmp edx,1
	je .add_1

	cmp edx,3
	jle .add_2

	add ecx,3
	jmp .make_byte_list

	.add_1:
	add ecx,1
	jmp .make_byte_list

	.add_2:
	add ecx,2
	jmp .make_byte_list

	.make_byte_list:
	xor edx,edx
	call add_new_byte_link
	mov dword[link_first],eax


	.loop_2:				;ecx holds the number of bits

	cmp ecx,0
	jle .end

	mov eax,[link_first]

	.inner_loop:

	cmp byte[eax+DATA],7
	jne .move_on

	mov byte[eax+DATA],0

	mov eax,dword[eax+NEXT]

	cmp eax,0
	jne .inner_loop

	call add_new_byte_link

	.move_on:
	add byte[eax+DATA],1
	sub ecx,8

	jmp .loop_2

	.end:

	push dword[link_first_free]
	call free_operand
	add esp,4

	sub dword[SPP],4
	mov eax,dword[SPP]
	mov dword[eax],0			
	mov edx, dword[link_first]
	mov dword[eax],edx

	cmp dword[debug],0
	je .dont_print

	PRINTF_ERR(fmt_s,debug_push_result)

	mov eax,[link_first]
	push eax
	call print_list_debug
	add esp,4

	PRINTF_ERR(fmt_s,new_line)

	.dont_print:
	add dword[SPP],4
	pop ebp
	ret


add_new_byte_link:
	push ebp
	mov ebp,esp

	call_func_2p malloc, LINK_SIZE
	mov eax, dword [return_ptr]
	mov byte[eax+DATA],0
	mov dword[eax+NEXT],0

	cmp dword[link_curr],0
	je .move_on

	mov edx,dword[link_curr]
	mov dword[edx+NEXT],eax

	.move_on:
	mov dword[link_curr],eax

	pop ebp
	ret

free_operand:
	;param1: pointer to the link to be print
	push ebp
	mov ebp,esp
	mov ecx, dword [ebp+8]	;pointer for the link
	mov edx, ecx

	.free:
	mov ebx, ecx

	mov ecx, [ecx+NEXT]

	call_func_2p free, ebx

	cmp ecx, 0
	je .end
	jmp .free

	.end:
	mov edx, 0
	mov esp,ebp
	pop ebp
	ret

print_list_debug:
	push ebp
	mov ebp, esp

	mov eax, dword [ebp+8]
	cmp eax, 0
	je .return

	push eax

	push dword [eax+NEXT]
	call print_list_debug
	add esp, 4

	pop eax

	movzx ebx, byte [eax+DATA]

	push ebx
	push fmt_d
	push dword [stderr]
	call fprintf
	add esp,12

	.return:
	pop ebp
	ret