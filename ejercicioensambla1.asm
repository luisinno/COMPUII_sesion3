programa:
	; PRIMER NUMERO, lee el primero de los números y lo almacena en A
	lda teclado
	suba #48
	lsla
	lsla
	lsla
	lsla
	sta n1 ; 0xX0


	; SEGUNDO NÚMERO, lee el segundo de los números y lo almacena en A
	lda teclado
	suba #48 ; 0xX0


	; se suman

	adda n1 ; se tuene el número
	sta n2 ; ya estaría el segundo número
	
	;OPERAMOS
	;	op1=n1+n2
	lda n1
	adda n2
	daa
	sta op;

para :

	; RESULTADO PANTALLA