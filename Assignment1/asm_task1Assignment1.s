section .data
	result: dd 0
	fmtd: db "%d",10,0

section .text
	global assFunc
	extern c_checkValidity
	extern printf

assFunc:
	push ebp
	mov ebp, esp	
	pushad			

	mov ecx, dword [ebp+8]				; get function argument (pointer to string)
	pushad
	push ecx 							;x
	call c_checkValidity
	mov [result], eax
	add esp, 4
	popad

	cmp dword[result], 1
	jne zero
	shl ecx, 3
	jmp end

zero:
	shl ecx, 2

end:
	mov eax, ecx
	push eax							; call printf with 2 arguments -  
	push fmtd							; pointer to str and pointer to format string
	call printf
	add esp, 8							; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
