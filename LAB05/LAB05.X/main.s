;Archivo:		main.s   -   Lab5
;Dispositivo:		PIC16F887
;Autor:			Diego Estrada - 19264
;Compilador:		pic-as (v2.30), MPLABX V5.40
;
;Programa:		Contador en binario, hexadecimal y decimal
;Hardware:		Leds en puerto A y display 7 segmentos en puerto C
;
;Creado:		2 mar, 2021
;Última modificación:	2 mar, 2021

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
    movlw  253			; Valor incial del timer0
    movwf  TMR0			; Se mueve al timer0
    bcf	T0IF			; Vuelve 0 al bit de overflow
    endm			; Se termina el MACRO
    
  
PSECT udata_bank0		; common memory
    var:	    DS 2
    nibble:	    DS 2
    display_var:    DS 5
    flags:	    DS 1
    centena:	    DS 1
    decena:	    DS 1
    residuo:	    DS 1
    
;-------------------------- Variables a utilizar -------------------------------
PSECT udata_shr			; Variables guardadas en la memoria compartida
W_TEMP:		DS 1		; variable a utilizar en 7 segmentos y comparador
STATUS_TEMP:	DS 1

;----------------------- Instrucciones vector reset ----------------------------
PSECT resVect, class=CODE, abs, delta=2
ORG 00h				; posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

;------------------------ Vectores de interrupción -----------------------------
PSECT intVect, class=CODE, abs, delta=2
ORG 04h				; posicion 0004h para las interrupciones
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
    incf    var
    movf    var, W
    movwf   PORTA
    btfss   PORTB, DOWN
    decf    var
    movf    var, W
    movwf   PORTA
    bcf	    RBIF
    return

int_tmr0:
    reinicio_tmr0
    clrf    PORTB
    btfsc   flags, 0
    goto    disp1
    btfsc   flags, 1
    goto    disp2
    btfsc   flags, 2
    goto    disp3
    btfsc   flags, 3
    goto    disp4
    
disp0:
    movf    display_var, W
    movwf   PORTC
    bsf	    PORTB, 2
    goto    siguiente_disp
    
disp1:
    movf    display_var+1, W
    movwf   PORTC
    bsf	    PORTB, 3
    goto    siguiente_disp1
    
disp2:
    movf    display_var+2, W
    movwf   PORTC
    bsf	    PORTB, 4
    goto    siguiente_disp2

disp3:
    movf    display_var+3, W
    movwf   PORTC
    bsf	    PORTB, 5
    goto    siguiente_disp3
   
disp4:
    movf    display_var+4, W
    movwf   PORTC
    bsf	    PORTB, 6
    goto    siguiente_disp4

siguiente_disp:
    movlw   0x01
    xorwf   flags, 1
    return
    
siguiente_disp1:
    movlw   0x03
    xorwf   flags, 1
    return

siguiente_disp2:
    movlw   0x06
    xorwf   flags, 1
    return
   
siguiente_disp3:
    movlw   0x0c
    xorwf   flags, 1
    return
    
siguiente_disp4:
    clrf    flags
    return
    
;-------------------------------- Tabla ----------------------------------------
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
    movlw   00000000B		; Se configuran los pines de salida para los leds
    movwf   TRISA
    
    bsf	    TRISB, UP		; Se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, DOWN
    bcf	    TRISB, 2		; Se configuran los pines de salida para los displays
    bcf	    TRISB, 3
    bcf	    TRISB, 4
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    
    movlw   00000000B		; Se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    movlw   00000000B
    movwf   TRISD		
    
    call    reloj		; Se llama al reloj 
    call    config_ioc		; Se llama a nuestro timer 9
    call    timer0
    call    int_enable
    
    banksel PORTA		; Se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD

;--------------------------------- Loop ----------------------------------------

loop:
    BANKSEL PORTA
    call    sep_nibbles
    call    prep_displays
    call    decimal
    
    goto loop			; Loop infinito
  
;------------------------------ Sub-Rutinas ------------------------------------
sep_nibbles:
    movf    var, W
    andlw   0x0f
    movwf   nibble
    swapf   var, W
    andlw   0x0f
    movwf   nibble+1
    return
    
prep_displays:
    movf    nibble, W
    call    tabla
    movwf   display_var
    
    movf    nibble+1, W
    call    tabla
    movwf   display_var+1
    
    movf    centena, W
    call    tabla
    movwf   display_var+2	
    
    movf    decena, W
    call    tabla
    movwf   display_var+3	
    
    movf    residuo, W
    call    tabla
    movwf   display_var+4	
    return
    
decimal:
    ; PARA LAS CENTENAS
    clrf	centena	    
    movf	PORTA, 0	    ; Se mueve lo que hay en el contador a w
    movwf	residuo		    ; Se mueve w a la variable residuos para operar las centenas
    movlw	100		    ; Se mueve 100 a w
    subwf	residuo, 0	    
    btfsc	STATUS, 0	    ; Se verifica si la bandera de status es 0
    incf	centena		    ; Se incrementa si la bandera es 1
    btfsc	STATUS, 0	    
    movwf	residuo		    ; Se mueve lo sobrante a residuos para operar las decenas
    btfsc	STATUS, 0	    
    goto	$-7		    
    
    ; PARA LAS DECENAS
    clrf	decena		    
    movlw	10		    ; Se mueve 10 a w
    subwf	residuo, 0	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    
    incf	decena		    ; Se incrementa la variable decenas
    btfsc	STATUS, 0	    
    movwf	residuo		    ; En este caso el residuo son las unidades
    btfsc	STATUS, 0	    
    goto	$-7		    
    btfss	STATUS, 0	       
    return


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
    bcf      IRCF2		
    bsf	     IRCF1
    bcf	     IRCF0
    bsf	     SCS		; Reloj interno
    return
    
timer0:
    banksel TRISA
    bcf	    T0CS		; Reloj interno
    bcf	    PSA			; Prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0			; PS = 111
    banksel PORTA
    reinicio_tmr0
    return

int_enable:
    bsf	    GIE			; INTCON
    bsf	    RBIE
    bcf	    RBIF
    bsf	    T0IE
    bcf	    T0IF
    return

    
END
