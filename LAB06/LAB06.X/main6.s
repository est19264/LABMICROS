;Archivo:		main6.s   -   Lab6
;Dispositivo:		PIC16F887
;Autor:			Diego Estrada - 19264
;Compilador:		pic-as (v2.30), MPLABX V5.40
;
;Programa:		Temporizador e implementación con tmr0, tmr1 y tmr2
;Hardware:		2 Display 7seg en PortB y LED en PortD
;
;Creado:		23 mar, 2021
;Última modificación:	27 mar, 2021

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

;--------------------------------- Macros --------------------------------------
reset02 macro			; Macro para el reinicio del timer 2
    BANKSEL PR2
    movlw   100			; Tiempo de intruccion
    movwf   PR2

    endm
    
;------------------------------- Variables -------------------------------------
PSECT udata_shr			; Variables guardadas en la common memory
    
    W_TEMP:			; Variable para guardar w
	DS 1
    STATUS_TEMP:		; Variable para guardar status
	DS 1
    nibble:
	DS  2
    disp_var:	   
	DS  2
    flags:
	DS  1

PSECT udata_bank0 
    var:
	DS  1
    counter:
	DS  1
    parpadeo:
	DS  1

	
;----------------------- Instrucciones vector reset ----------------------------
PSECT resVect, class=code, abs, delta=2
ORG 00h				;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
;------------------------ Vectores de interrupción -----------------------------
PSECT code, delta=2, abs
ORG 04h 
    
push:				; Se mueven las variables temporales a w
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:

    BANKSEL PORTB	
    btfsc   TMR1IF		; Se revisa si hay overflow en el timer1
    call    interrupcion1		; Se llama a su subrutina
    btfsc   T0IF		; Se revisa si hay overflow del timer0
    call    interrupcion0		; Se llama la subrutina del timer0
    
    BANKSEL PIR1
    btfsc   TMR2IF		; Se revisa si hay overflow en el timer2
    call    interrupcion2	; Se llama a su interrupcion 
    BANKSEL TMR2
    bcf	    TMR2IF		; Se limpia la bandera del timer2
 
pop:				; Se regresa w al status
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie

;------------------------ Sub-rutinas de interrupción --------------------------
; Interrupción para el timer2
interrupcion2:	
    
    btfsc   parpadeo, 0		; Se verifica la bandera
    goto    off

on:
    bsf	    parpadeo, 0		; Se activa bandera
    return    
    
off:
    bcf	    parpadeo, 0		; Se descativar bandera
    return

; Interrupción para el timer1
interrupcion1:			
    BANKSEL TMR1H   
    movlw   0xE1		; Se modifican los registros del timer1
    movwf   TMR1H
    
    BANKSEL TMR1L
    movlw   0x7C
    movwf   TMR1L
    
    incf    counter		; Se incrementa el timer
    bcf	    TMR1IF
    return    
    
; Interrupción para el timer0
interrupcion0:
    call    reset0		; Se hace reset el timer0
    bcf	    PORTB, 0		; Se limpian los puertos conectados a los transistores
    bcf	    PORTB, 1
    btfsc   flags, 0
    goto    disp_02   
 
; Rutinas para activar los displays
disp_01:
    movf    disp_var, w
    movwf   PORTC
    bsf	    PORTB, 1
    goto    next_disp01
disp_02:
    movf    disp_var+1, W
    movwf   PORTC
    bsf	    PORTB, 0
next_disp01:
    movlw   1
    xorwf   flags, f
    return
 
;-------------------------------- Tabla ----------------------------------------
    PSECT code, delta=2, abs
    ORG 100h			; Posición para el código de la tabla
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
    
;------------------------------ Configuración ----------------------------------
ORG 118h			; Posición para el código
main:
; Configuración de inputs y outputs
; Configuración a puertos digitales
    BANKSEL ANSEL		; Se selecciona el banco
    clrf    ANSEL		; Se definen los puertos digitales
    clrf    ANSELH
    
; Configuración PORTB
    BANKSEL TRISA		; Se selecciona bank 1
    bcf	    TRISB,  0		
    bcf	    TRISB,  1		
        
; Configuración PORTC
    bcf	    TRISC,  0		
    bcf	    TRISC,  1		
    bcf	    TRISC,  2		
    bcf	    TRISC,  3		
    bcf	    TRISC,  4		
    bcf	    TRISC,  5		
    bcf	    TRISC,  6		
    bcf	    TRISC,  7		
    
; Configuración PORTD
    bcf	    TRISD,  0	
    
; Nota: todos los pines anteriores están configurados como outputs.
   
; Se manda a llamar la configuración para el reloj
    call    reloj
    
; Configuración para timer0
    BANKSEL OPTION_REG
    bcf	    T0CS
    bcf	    PSA			; Se utilza el prescaler del timer0
    bsf	    PS0			; Prescaler 11 = 1:256
    bsf	    PS1
    bsf	    PS2
    
; Configuración para timer1
    BANKSEL T1CON
    bsf	    T1CKPS1		; Prescaler 11 = 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS		; Se utiliza el reloj interno
    bsf	    TMR1ON		; Se habilita el timer1

; Configuración para timer2
    BANKSEL T2CON		; Postcaler = 1001
    movlw   1001110B		; 1 timer 2 on
    movwf   T2CON		; 10 precaler 16

; Interrupciones
    BANKSEL INTCON
    bsf	    GIE			; Interrupcion global
    bsf	    T0IE		; Interrupcion para timer0
    bcf	    T0IF
    
    BANKSEL PIE1
    bsf	    TMR2IE		; Se habilita timer2 para pr2
    bsf	    TMR1IE		; Se habilita la interrupcion por overflow para timer1 
    
    BANKSEL PIR1
    bcf	    TMR2IF		; Se limpia la bandera para timer2
    bcf	    TMR1IF		; Se limpia la bandera de interrupcion para timer1
    
; Se limpian todos los puertos
    BANKSEL PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    
;--------------------------------- Loop ----------------------------------------
loop:
    reset02
    BANKSEL PORTA
    call    div_nib		; Se llama a la division de nibbles
    
    btfss   parpadeo, 0
    call    prep_nib		; Se mandan los nibbles a los display
    
    btfsc   parpadeo, 0
    call    blink		; Se llama a la rutina de parpadeo
    
    
goto    loop
    
;------------------------------ Sub-Rutinas ------------------------------------
; Configuración para el reloj (oscilador interno)
reloj:				; Se configura el oscilador interno
    BANKSEL OSCCON
    bcf	    IRCF2		; IRCF = 010 = 250KHZ
    bsf	    IRCF1   
    bcf	    IRCF0		
    bsf	    SCS			; Activar oscilador interno
    return

; Rutina para configuración del reset timer0
reset0:
    BANKSEL PORTA
    movlw   255			; Tiempo de la instrucción
    movwf   TMR0
    bcf	    T0IF		; Se vuelve 0 el bit de overflow
    return

; Rutina de separación de nibbles
div_nib:    
    movf    counter, w
    andlw   00001111B
    movwf   nibble
    swapf   counter, w		; Se cambian los ultimos 4 bits por los primeros
    andlw   00001111B
    movwf   nibble+1 
    return
    
; Rutina para desplegar los valores en el display 7 segmentos
prep_nib:   
    movf    nibble, w
    call    Tabla7seg
    movwf   disp_var, F		
    movf    nibble+1, w
    call    Tabla7seg
    movwf   disp_var+1, F	
    bsf	    PORTD, 0
    return

; Rutina para el parpadeo de la led
blink:	   
    movlw   0
    movwf   disp_var
    movwf   disp_var+1
    bcf	    PORTD, 0
    return
         
END				; Se finaliza el codigo