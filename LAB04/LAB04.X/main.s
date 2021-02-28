;Archivo:		main.s   -   Lab4
;Dispositivo:		PIC16F887
;Autor:			Diego Estrada
;Compilador:		pic-as (v2.30), MPLABX V5.40
;
;Programa:		
;Hardware:		 
;
;Creado:		23 feb, 2021
;Última modificación:	25 feb, 2021
    

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
  

UP    EQU 0
DOWN  EQU 1
  
reinicio_tmr0 MACRO		; Implementación de MACRO para reiniciar el tmr0
    banksel PORTA
    movlw  61			; Valor incial del timer0
    movwf  TMR0			; Se mueve al timer0
    bcf	T0IF			; Vuelve 0 al bit de overflow
    endm			; Se termina el MACRO
    
  
PSECT udata_bank0		;common memory
  cont:         DS 2		; dos bits
    
;-------------------------- Variables a utilizar -------------------------------
PSECT udata_shr
W_TEMP:		DS 1		;variable a utilizar en 7 segmentos y comparador
STATUS_TEMP:	DS 1
var1:		DS 1
var2:		DS 1

;----------------------- Instrucciones vector reset ----------------------------
PSECT resVect, class=CODE, abs, delta=2
ORG 00h				;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

;------------------------ Vectores de interrupción -----------------------------
PSECT intVect, class=CODE, abs, delta=2
ORG 04h				;posicion 0004h para las interrupciones
push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    btfsc   RBIF
    call    int_iocb
    btfsc   T0IF
    call    int_tmr0
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
;------------------------ Sub-rutinas de interrupción --------------------------
int_iocb:
    banksel PORTA
    btfss   PORTB, UP
    incf    PORTA
    btfss   PORTB, DOWN
    decf    PORTA
    bcf	    RBIF
    return
    
int_tmr0:
    reinicio_tmr0		; 50ms
    incf    cont
    movf    cont, W
    sublw   40
    btfss   ZERO		; STATUS, 2
    goto    return_tmr0
    clrf    cont		; 500 ms
    incf    var2
    movf    var2, W
    call    tabla
    movwf   PORTD
    return

return_tmr0:
    return
    
PSECT code, delta=2, abs
ORG 100h			; Posicion para el codigo
 tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0		; PCLATH = 01
    andlw   0x0f
    addwf   PCL			; PC = PCLATH + PCL
    ; se configura la tabla para el siete segmentos
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01100111B  ;9
    retlw   01110111B  ;A
    retlw   01111100B  ;B
    retlw   00111001B  ;C
    retlw   01011110B  ;D
    retlw   01111001B  ;E
    retlw   01110001B  ;F
    
;------------------------------ Configuración ----------------------------------
	
main:
    banksel ANSEL		; Se selecciona el banco 
    clrf    ANSEL		; Se limpian los puertos digitales
    clrf    ANSELH
    
    banksel TRISA		; Se selecciona banco 1
    bcf	    TRISA, 0		; Se configura los pines de salida del contador
    bcf	    TRISA, 1
    bcf	    TRISA, 2
    bcf	    TRISA, 3
    
    bsf	    TRISB, UP		; Se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, DOWN
    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    
    movlw   00000000B		;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    movlw   00000000B
    movwf   TRISD		;se configura el pin de salida del led de alarma
    
    call    reloj		;se llama al reloj 
    call    config_ioc		;se llama a nuestro timer 9
    call    timer0
    call    int_enable
    
    banksel PORTA		;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD

;-------------------------------- Loop ----------------------------------------

loop:
    call    display_c
    
    goto loop			; Loop infinito
  
;------------------------------ Sub-Rutinas ------------------------------------
config_ioc:
    banksel TRISA
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF
    return
    
reloj:
    banksel  OSCCON
    bsf      IRCF2		; IRCF = 110 4MHz
    bsf	     IRCF1
    bsf	     IRCF0
    bsf	     SCS		; reloj interno
    return
    
timer0:
    banksel TRISA
    bcf	    T0CS		;reloj interno
    bcf	    PSA			;Prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0			; PS = 111
    banksel PORTA
    reinicio_tmr0
    return

int_enable:
    bsf	    GIE			;INTCON
    bsf	    RBIE
    bsf	    T0IE
    bcf	    RBIF
    bcf	    T0IF
    return
    
display_c: 
    banksel PORTA 
    movf    PORTA, W		; Se mueve el valor del contador a w
    movwf   var1
    movf    var1, W
    call    tabla
    movwf   PORTC		; Se manda el resultado a PORTC
    return		


    
END