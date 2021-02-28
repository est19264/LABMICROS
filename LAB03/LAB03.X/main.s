;Archivo:		main.s   -   Lab3
;Dispositivo:		PIC16F887
;Autor:			Diego Estrada
;Compilador:		pic-as (v2.30), MPLABX V5.40
;
;Programa:		Contador y display 7seg con alarma
;Hardware:		Push Buttons en puerto A, leds en B y D, y 7seg en C 
;
;Creado:		16 feb, 2021
;Última modificación:	19 feb, 2021
    

PROCESSOR 16F887
#include <xc.inc>

 ; Palabras de configuración 1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
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
  
  
;Variables a utilizar
    PSECT udata_shr		; Memoria compartida
    
    cont7seg:   
	DS 1			; 1 byte
	
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
    
;Tabla de conversion de binario a hexadecimal para el 7seg
    Tabla7seg:
	clrf	PCLATH
	bsf	PCLATH, 0	; PCLATH = 01 PCL = 02
	andlw	0x0F
	addwf	PCL		; PC = PCLATH + PCL + W
	
; Se configura el display con su equivalente en binario
	retlw	00111111B   ; 0
	retlw   00000110B   ; 1
	retlw   01011011B   ; 2
	retlw   01001111B   ; 3
	retlw   01100110B   ; 4
	retlw   01101101B   ; 5
	retlw   01111101B   ; 6
	retlw   00000111B   ; 7
        retlw   01111111B   ; 8
    	retlw   01101111B   ; 9
	retlw   01110111B   ; A
        retlw   01111100B   ; b
	retlw   00111001B   ; C
        retlw   01011110B   ; d
	retlw   01111001B   ; E
	retlw   01110001B   ; F
    ;--------------configuración-----------------
    main:
	BANKSEL	ANSEL		; Se selecciona el bank 3
	clrf    ANSEL		; Definir puertos digitales
	clrf    ANSELH
	
	
; Configurar inputs en PORTA
	BANKSEL TRISA		; Se selecciona Bank 1
	bsf	TRISA, 0	; Se ingresan los inputs en TRISA
	bsf	TRISA, 1
	
; Configurar outputs en PORTB, PORTC y PORTD
	bcf	TRISB, 0	; Se ingresan los outputs en TRISB
	bcf	TRISB, 1	
	bcf	TRISB, 2	
	bcf	TRISB, 3	
	
	movlw	00000000B	; Se ingresan los outputs en TRISC
	movwf	TRISC
	
	
	bcf	TRISD, 0	; Se ingresan los outputs en TRISD
	

; Configuración para el reloj 
	BANKSEL OSCCON
	bcf	    IRCF2	; IRCF = 010 = 250KHZ
	bsf	    IRCF1
	bcf	    IRCF0
	bsf	    SCS		; Reloj interno
	
; Configuració para timer0
	BANKSEL OPTION_REG
	movlw   11000110B	; Prescaler de 1:256
	movwf   OPTION_REG
	
; Se limpian los puertos
	BANKSEL PORTA
	clrf    PORTA
	clrf    PORTB
	clrf    PORTC
	clrf    PORTD
	
	;--------------loop principal----------------
    loop:
	btfss   PORTA, 0	
	call    inc7seg		
    
	btfss   PORTA, 1
	call    dec7seg
	
	
	btfss   T0IF
	goto    $-1
	call    reiniciar_timer0
	incf    PORTB
	
	
	bcf	PORTD, 0 
	call    seg_led
	
	goto    loop
	
	;--------------sub rutinas-------------------  
    
    reiniciar_timer0: ; Reinicio para tmr0
	movlw   11
	movwf   TMR0
	bcf	T0IF
	return
    
    inc7seg: ; Incremento para el 7seg
	btfss   PORTA, 0	; Posición para el botón de incremento en PORTA
	goto    $-1		; Antirebote del botón
	incf    cont7seg	; se incrementa al siguiente valor de w
	movf    cont7seg, W	; Se convierte el bin a su equivalente en hex
	call    Tabla7seg	; Se manda a llamar la tabla 
	movwf   PORTC		; Se pasa el valor de la tabla al 7seg
	return
    
    dec7seg: ; Decremento 7 seg
	btfss   PORTA, 1	; Posición para el botón de decremento en PORTA 
        goto    $-1		; Antirebote del botón
        decfsz  cont7seg	; se decrementa el valor de w
	movf    cont7seg, W	; Se convierte el bin a hex
        call    Tabla7seg	; Se manda a llamar la tabla
	movwf   PORTC		; Se pasa el valor de la tabla al 7seg
	return		
	
    seg_led:
	movf    PORTB, W	; Se mueve el valor del contador binario a W
	subwf   cont7seg, W	; Se resta W a la variable Cont7seg
	btfsc   STATUS, 2	; Si son valores iguales la bandera de z se levanta
	call	alarma
	return
	
    alarma:
	; Si se levanta la bandera, se activa el led de alarma
	bsf	PORTD, 0	; Activar la led de alarma
	clrf    PORTB		; Se reinicia el counter binario
	return
   
END