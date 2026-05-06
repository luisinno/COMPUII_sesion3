	.area PROG (ABS)

    ; --- DEFINICION DE CONSTANTES ---
fin   	 .equ	0xFF01
pantalla    .equ	0xFF00
teclado    .equ	0xFF02

    .org	0x100
    
    ; --- VARIABLES ---
p_termino:    .byte 0    ;primer termino
razon:   	 .byte 0    ;razon
num_terms:    .byte 0    ;numero de terminos (iniciadas a 0)

flag_op1:    .byte 0
flag_op2:    .byte 0    ;flags para bloquear opciones 3 y 4 si no se han seleccionado 1 y 2
temp:   	 .byte 0    ;variable temporal para lee_decimal

contador:    .byte 0    ;para el bucle del calculo
resultado_suma:    .word 0    ;guardamos el resultado de la suma de terminos aqui
temp_den:   	.byte 0		 ;guardar el denominador (r - 1)
temp_num:   	.word 0		 ;guardar el numerador (ult termino x r)-1er term.
temp_den_16:	.word 0		 ;denominador expandido a 16 bits para poder restarlo
temp_cociente:  .word 0		 ;el resultado de la division
ultimo_termino: .word 0		 ;ultimo termino de la progresion
temp_16:    .word 0    ; Para guardar el numero original de 16 bits
temp_final:    .word 0    ; Para ir construyendo el resultado final

; --- TABLA DE SALTOS ---
tabla_saltos:
    .word ir_opcion_1
    .word ir_opcion_2
    .word ir_opcion_3
    .word ir_opcion_4



    ; --- CADENAS DE TEXTO ---

menu_str:    .ascii "\n---PROGRESION GEOMETRICA---\n\n"
   	 .ascii "(1) INTRODUZCA PRIMER TERMINO Y RAZON.\n"
   	 .ascii "(2) INTRODUZCA EL NUMERO DE TERMINOS.\n"
   	 .ascii "(3) CALCULAR TERMINOS.\n"
   	 .ascii "(4) SUMAR TERMINOS.\n"
   	 .ascii "(S) SALIR.\n"
   	 .asciz "\nINTRODUCIR OPERACION: "

msj_op1:    .asciz "\nHas seleccionado la Opcion 1\n"    ;mensajes si seleccionas la opcion
msj_op2:    .asciz "\nHas seleccionado la Opcion 2\n"
msj_op3:    .asciz "\nHas seleccionado la Opcion 3\n"
msj_op4:    .asciz "\nHas seleccionado la Opcion 4\n"
msj_err:    .asciz "\n[ERROR] Primero debes completar las opciones 1 y 2!\n"
msj_calc:    .asciz "\n(3) Calculado con exito\n"
msj_suma:    .asciz "\n(4) Sumado con exito\n"

pide_op1:    .asciz "\nIntroduce el primer termino y la razon (XX XX): \n"
pide_op2:    .asciz "\nIntroduce el numero de terminos (XX): \n"

    .globl    programa
programa:
    lds    #0xFF00     	;Inicializamos la pila

bucle_menu:
    ldx 	#menu_str    ;Cargar texto en X (le damos la direccion del texto menu_str)
    jsr 	imprime_cadena    ;Salto a subrutina (imprime el menú)

lee_opcion:
    ;---MENU---
    lda teclado
    
    cmpa #'S
    lbeq acabar   	 ;tecla de salida
   	 
    cmpa #'1    ;
    blo lee_opcion
    cmpa #'4
    bhi lee_opcion     ;si la tecla pulsada es menor que 1 o mayor que 4, vuelve a leer
    ;TABLA DE SALTOS
    
    suba #'1        	; Convertimos ASCII ('1'-'4') a índice (0-3)
    lsla            	; Multiplicamos por 2 (Desplazamiento lógico a la izquierda)

    ldx #tabla_saltos   ; Cargamos la base de la tabla en X
    jmp [a,x]       	; SALTO INDIRECTO INDEXADO: Salta a la dirección guardada en (X + A)

    
mostrar_error:
    ldx #msj_err
    jsr imprime_cadena
    jmp bucle_menu

	 ;---OPCIONES DEL MENU---
ir_opcion_1:

    ldx #msj_op1   	 ;carga la direccion del mensaje
    jsr imprime_cadena    ;imprime el mensaje
    
    ;PEDIR DATOS
    ldx #pide_op1    ;mensaje de pedir primer termino
    jsr imprime_cadena
    
    jsr lee_decimal
    sta p_termino   	 ;guardamos en la variable primer termino
    
    lda teclado   	 ;para que lea el espacio
    
    jsr lee_decimal
    sta razon
    
    lda #1   	 ;valor que activa el flag
    sta flag_op1    ;encendemos el flag
    
    
    jmp bucle_menu   	 ;vuelve al menu principal


ir_opcion_2:

    ldx #msj_op2   	 ;carga la direccion del mensaje
    jsr imprime_cadena    ;imprime el mensaje

    
    ;PEDIR NUMERO DE TERMINOS
    ldx #pide_op2    ;mensaje de pedir numero de terminos
    jsr imprime_cadena    
    
    jsr lee_decimal
    sta num_terms   	 ;guardamos en la variable num_terms
    
    
    lda #1
    sta flag_op2    ;encendemos el flag
    
    
    jmp bucle_menu   	 ;vuelve al menu principal


ir_opcion_3:
    ;COMPROBAR SI SE HAN PULSADO ANTES 1 Y 2    
    lda flag_op1
    lbeq mostrar_error    ;si flag op1 = 0, va a error
    lda flag_op2
    lbeq mostrar_error    ;si flag op2 = 0, va a error

    ;SI PASA EL CHEQUEO, EMPIEZA LA OPCION 3
    ldx #msj_op3   	 ;carga la direccion del mensaje
    jsr imprime_cadena    ;imprime el mensaje
    
    ;PREPARAR BUCLE Y PUNTERO
    lda num_terms    
    cmpa #0
    beq fin_op3   	 ;si num_terms = 0 no hay que calcular
    
    sta contador   	 ;num_terms a la variable contador
    ldx #memoria_cons    ;apuntamos x a la zona de memoria donde guardaremos los terminos en posiciones de memora consecutivas
    
    clra   		 ;la parte alta (a) a 0
    ldb p_termino   	 ;cargamos el primer termino en b (parte baja)
    
    
    ;BUCLE QUE CALCULA Y GUARDA
bucle_calc:
    std ,x++    ;guardamos d (numero de 16 bits) y avanza x 16 bits en la memoria consecutiva
    
    std ultimo_termino    ;guardamos en d el ultimo termino para usarlo en la opcion4
    
    ; --- IMPRIMIR EL TERMINO ACTUAL ---
    pshs	d, x        	; ESCUDO: Guardamos D y X en la pila para no perderlos
       	 
    jsr 	imprime_decimal ;imprimimos D en la pantalla
       	 
    lda 	#0x20        	;imprimimos un espacio en blanco de separacion
    sta 	pantalla
       	 
    puls	d, x        	; RECUPERAMOS: D y X vuelven a estar intactos
    ; ----------------------------------
    
    
    
    dec contador    ;contador = contador - 1
    beq fin_op3    ;hasta que contador = 0, salida del bucle
    
    ;CALCULAR SIGUIENTE TERMINO
    
    jsr mul_16x8
    jmp bucle_calc    ;bucle    
    
fin_op3:    
    ldx #msj_calc
    jsr imprime_cadena    ;mensaje de calculo exitoso
    jmp bucle_menu   	 ;vuelve al menu principal
    
    
ir_opcion_4:
    
    ;COMPROBAR SI SE HAN PULSADO ANTES 1 Y 2    
    lda flag_op1
    lbeq mostrar_error    ;si flag op1 = 0, va a error
    lda flag_op2
    lbeq mostrar_error    ;si flag op2 = 0, va a error

    ;SI PASA EL CHEQUEO, EMPIEZA LA OPCION 4    
    
    ldx #msj_op4   	 ;carga la direccion del mensaje
    jsr imprime_cadena    ;imprime el mensaje
    
    ;CALCULAR DENOMINADOR (r-1)
    lda razon
    suba #1
    sta temp_den ;lo guardamos en la variable
    
    ;CALCULAR NUMERADOR (ult termino * r) - 1r term
    ldd ultimo_termino
    jsr mul_16x8    ;d vuelve con (An x r)
    
    ;a1 es de 8 bits. lo expandimos a 16 restando la parte baja B y llevandonos el acarreo a A (parte alta
    subb p_termino    ;a1 - parte baja (b)
    sbca #0    ;parte alta - acarreo
    
    ;HACER DIVISION
    jsr divide    ;d=d/temp_den
    
    ;GUARDAR RESILTADO
    std resultado_suma
    
    
    ldx #msj_suma
    jsr imprime_cadena
    
; --- IMPRIMIR EL NUMERO ---
    ldd resultado_suma 		 ;Metemos la suma final en D
    jsr imprime_decimal    	 ;La subrutina lo saca en pantalla
       	 
    lda #'\n
    sta pantalla   		 ;salto de linea por pantalla
    
    
    
    jmp bucle_menu    
    
acabar:
        	clra
        	sta 	fin    
    
    ; --- SUBRUTINAS ---

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime_cadena                                               	;
; 	saca por la pantalla la cadena acabada en '\0 apuntada por X ;
; 	Entrada: registro X (direccion donde empieza el texto)   	;
; 	Salida: ninguna, la pantalla muestra el texto            	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
imprime_cadena:
    pshs    a    ;guardamos en la pila el registro A
sgte:    
    lda    ,x+   		 ;lee la letra a la que apunta X y la guarda en A. luego X avanza una posición
    beq    ret_imprime_cadena    ;si lee un 0 de fin de cadena, salta.
    sta    pantalla   	 
    bra    sgte   		 ;bucle
ret_imprime_cadena:
    puls    a   		 ;sacamos de la pila en A el valor que guardamos antes
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; lee_decimal                                                  	;
;;   lee la el numero del teclado y lo pasa a decimal          	;
;;                                                             	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lee_decimal:
    ;LEER DECENAS
    lda teclado    ;lee la tecla
    suba #'0
    
    ldb #10    ;carga el 10 en b
    mul   	 ;a x b
    stb temp    ;guardamos las decenas en temp
    
    ;LEER UNIDADES
    lda teclado    ;lee la tecla
    suba #'0
    
    ;JUNTAR UNIDADES CON DECENAS
    adda temp    ;a = a + temp (unidades + decenas)
    
    rts
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mul_16x8                                                     	;
;	Multiplica un numero de 16 bits por uno de 8 bits.        	;
;	Entrada: D = Numero de 16 bits. Variable 'razon' (8 bits) 	;
;	Salida: D = Resultado final de 16 bits.                   	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mul_16x8:
std    temp_16   	 ; Guardamos el numero de 16 bits original

    ; --- PASO 1: Multiplicar PARTE BAJA x razon ---
    lda    temp_16+1    ; Cargamos el byte BAJO en A
    ldb    razon   	 ; Cargamos la razon en B
    mul   		 ; Multiplicamos (8x8). El resultado de 16 bits va a D.
    
    std    temp_final    ; Guardamos este primer resultado

    ; --- PASO 2: Multiplicar PARTE ALTA x razon ---
    lda    temp_16   	 ; Cargamos el byte ALTO en A
    ldb    razon   	 ; Cargamos la razon en B
    mul
    
    ; TRUCO: Como estabamos multiplicando la parte ALTA original,
    ; el byte 'B' de este nuevo resultado corresponde a la posicion
    ; del byte ALTO del resultado final. (Ignoramos 'A' para no desbordar).
    
    ; --- PASO 3: Sumar las piezas ---
    addb    temp_final    ; Le sumamos a B lo que habia en el byte ALTO de temp_final
    stb    temp_final    ; Guardamos el byte alto actualizado
    
    ; --- SALIDA ---
    ldd    temp_final    ; Recuperamos el numero final completo en D
    rts   		 ; Volvemos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; divide                                                      	;
;;   divide 16 bits entre 8                                    	;
;;   entrada: D=numerador (variable 'temp_den')                	;
;;   salida: D=cociente                                        	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
divide:
    std temp_num   	 ;guardamos numerador en d
    
    ;1) pasar numerador de 8 a 16 bits
    clra   		 ;parte alta 0
    ldb temp_den   	 ;denominador en parte baja
    std temp_den_16    ;denominador en 16 bits (d)
    
    ;2) prepsrar division
    ldx #0   		 ;x como contador de restas (sera el cociente)
    stx temp_cociente    ;cociente a 0
    
    ldd temp_num   	 ;cargamos numerador en d

bucle_resta:
    subd temp_den_16    ;restamos num-den
    lblo fin_divide    ;long branch if lower
    
    ;si no ha bajado de 0 la resta es valida
    ldx temp_cociente
    leax 1,x    ;suma 1 a x
    stx temp_cociente
    
    lbra bucle_resta    ;bucle

fin_divide:
    ldd temp_cociente    ;cargamos el resultado de la division en d para devolverlo
    
    rts    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime_decimal                                                          	;
;    imprime en decimal el numero contenido en D interpretado sin signo 	;
;                                                                          	;
;    Entrada: D -> Numero de 16 bit sin signo                           	;
;    Salida: ninguna                                                    	;
;    Registros afectados: D y CC                                        	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
imprime_decimal:
    pshs    x

    ldx    #0   	 ; para almacenar d
    
    
;PRIMERA CIFRA (-10000)
primera_cifra:
    cmpd    #10000
    blo    imprime_primera_cifra
    subd    #10000
    
    ;Incrementar contador de cifra
    exg    d,x
    incb    
    exg    d,x    
    bra    primera_cifra
imprime_primera_cifra:
    exg    d,x
    addb    #'0
    stb    pantalla
    exg     d,x
    
    
    ldx    #0    ;Volvemos a poner el contador a 0
    
    
;SEGUNDA CIFRA (-1000)
segunda_cifra:
    cmpd    #1000
    blo    imprime_segunda_cifra
    subd    #1000
    
    ;Incrementar contador de cifra
    exg    d,x
    incb    
    exg    d,x    
    bra    segunda_cifra
imprime_segunda_cifra:
    exg    d,x
    addb    #'0
    stb    pantalla
    exg     d,x
    
    
    ldx    #0    ;Volvemos a poner el contador a 0
    
    
    ;TERCERA CIFRA (-100)
tercera_cifra:
    cmpd    #100
    blo    imprime_tercera_cifra
    subd    #100
    
    ;Incrementar contador de cifra
    exg    d,x
    incb    
    exg    d,x    
    bra    tercera_cifra
imprime_tercera_cifra:
    exg    d,x
    addb    #'0
    stb    pantalla
    exg     d,x
    
    
    ldx    #0    ;Volvemos a poner el contador a 0
    
    
    ;CUARTA CIFRA (-10)
cuarta_cifra:
    cmpd    #10
    blo    imprime_cuarta_cifra
    subd    #10
    
    ;Incrementar contador de cifra
    exg    d,x
    incb    
    exg    d,x    
    bra    cuarta_cifra
imprime_cuarta_cifra:
    exg    d,x
    addb    #'0
    stb    pantalla
    exg     d,x
    
    
    ldx    #0    ;Volvemos a poner el contador a 0

    

quinta_cifra:
    addb    #'0
    stb    pantalla

; RETORNO
    puls    x
    rts








memoria_cons:   	 ;a partir de aqui se guardan los terminos consecutivos

    
    .org 0xFFFE    ;vector de reset
    .word programa



