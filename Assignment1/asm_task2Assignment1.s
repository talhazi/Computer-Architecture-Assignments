section	.rodata							; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0		; format string

section .bss							; we define (global) uninitialized variables in .bss section
	an: resb 33							; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp
	pushad
	mov ecx, dword [ebp+8]				; get function argument (pointer to string)
	mov edx,0
	mov ebx,0

nextChar:
	mov edx,ecx
	cmp byte[edx], 10
	je end
	xor eax, eax
	add eax, 1
	cmp byte[edx], 'A'
	jge letters
	sub byte[edx], '0'
	jmp addToReg0

letters:
	sub byte[edx], 55

addToReg0:
	xor eax, eax
	add eax, 8
	and al, [edx]
	shr al,3
	add al, 48
	mov byte[an+ ebx], al
	inc ebx

addToReg1:
	xor eax, eax
	add eax, 4
	and al, [edx]
	shr al,2
	add al, 48
	mov byte[an+ ebx], al
	inc ebx

addToReg2:
	xor eax, eax
	add eax, 2
	and al, [edx]
	shr al,1
	add al, 48
	mov byte[an+ ebx], al
	inc ebx

addToReg3:
	xor eax, eax
	add eax, 1
	and al, [edx]
	add al, 48
	mov byte[an + ebx], al
	inc ebx
	inc ecx
	jmp nextChar

end:
	mov byte[an + ebx], 0
	push an											; call printf with 2 arguments -
	push format_string					; pointer to str and pointer to format string
	call printf
	add esp, 8									; clean up stack after call

	popad
	mov esp, ebp
	pop ebp
	ret
