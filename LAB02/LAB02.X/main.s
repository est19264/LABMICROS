;Archivo:		LABORATORIOS.s
;Dispositivo:		PIC16F887
;Autor:			Diego Estrada
;Compilador:		pic-as (v2.30), MPLABX V5.40
;
;Programa:		contador en el puerto A
;Hardware:		LEDs en el puerto A
;
;Creado:		9 feb, 2021
;Última modificación:	9 feb, 2021
    

PROCESSOR 16F887
 #include <xc.inc>

 ; Palabras de configuración 1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; Palabras de configuración 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  

    
;Instrucciones vector reset
    PSECT resVect, class=CODE, abs, delta=2
    ;---------------vector reset-----------------
    ORG 00h			; Posición 0000h para el reset
    resetVec:
	PAGESEL	    main
	goto	    main
	
;Configuración del microcontrolador
    PSECT code, delta=2, abs
    ORG 100h			; Posición para el código
    ;--------------configuración-----------------
    main:
	BANKSEL ANSEL
	clrf    ANSEL		; Definir puertos digitales
	clrf    ANSELH
	
; Configurar puertos de salida A
	BANKSEL TRISA		; Se selecciona Bank 1
	movlw 11011111B		; Se ingresan los inputs en TRISA
	movwf TRISA
	
	movlw 00000000B		; Se ingresan los outputs en TRISB
	movwf TRISB
	
	movlw 00000000B		; Se ingresan los outputs en TRISC
	movwf TRISC
	
	movlw 00000000B		; Se ingresan los outputs en TRISD
	movwf TRISD
	
	; Se limpian los puertos
	BANKSEL PORTA
	clrf    PORTA
	clrf    PORTB
	clrf    PORTC
	clrf    PORTD

	;--------------loop principal----------------
    loop:
	btfss   PORTA, 0	; Botón en el pin 2 para incrementar
	call    incB		; Llama a la subrutina de incrementar
    
	btfss   PORTA, 1	; Botón en el pin 3 para decrementar
	call    decB		; Llama a la subrutina de decrementar
    
	btfss   PORTA, 2	; Botón en el pin 4 para incrementar
	call    incC		; Llama a la subrutina de incrementar
    
	btfss   PORTA, 3	; Botón en el pin 5 para decrementar
	call    decC		; Llama a la subrutina de decrementar

	btfss	PORTA, 4
	call	sumaBC
	
	goto	loop		; Loop forever
	
    ;---------------sub rutinas------------------
	
    incB:			; Rutina de incremento 1
    btfss   PORTA, 0		; Ubicación del botón
    goto    $-1			; Ejecuta 1 línea atrás
    incf    PORTB, 1		; El puerto donde esta la led
    return			; Regresa el main loop

    decB:			; Rutina de decremento 1
    btfss   PORTA, 1		; Ubicación del botón
    goto    $-1			; Ejecuta 1 línea atrás
    decfsz  PORTB, 1		; El puerto donde esta la led
    return			; Regresa el main loop
    
    incC:			; Rutina de incremento 2
    btfss   PORTA, 2		; Ubicación del botón
    goto    $-1			; Ejecuta 1 línea atrás
    incf    PORTC, 1		; El puerto donde esta la led
    return			; Regresa el main loop
    
    decC:			; Rutina de incremento 2
    btfss   PORTA, 3		; Ubicación del botón
    goto    $-1			; Ejecuta 1 línea atrás
    decfsz  PORTC, 1		; El puerto donde esta la led
    return			; Regresa el main loop
    
    sumaBC:			; Rutina para sumar B y C
    btfss   PORTA, 4		; Ubicación del botón
    goto    $-1			; Ejecuta 1 línea atrás
    movf    PORTB, 0		; Mueve el valor de B a f
    addwf   PORTC, 0		; Suma el valor de C a B
    movwf   PORTD		; El puerto donde esta la led
    return			; Regresa el main loop
    
END				; Fin del código


