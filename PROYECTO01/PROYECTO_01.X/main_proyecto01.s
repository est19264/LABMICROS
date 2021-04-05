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

    UP     EQU	0
    DOWN   EQU	1
    MODE   EQU	2 
;--------------------------------- Macros --------------------------------------
reset02 macro			; Macro para el reinicio del timer 2
    BANKSEL PR2
    movlw   100			; Tiempo de intruccion
    movwf   PR2
    endm

; Rutina para configuración del reset timer0
reinicio_tmr0	macro
    BANKSEL PORTA
    movlw   255			; Tiempo de la instrucción
    movwf   TMR0
    bcf	    T0IF		; Se vuelve 0 el bit de overflow
    endm
;------------------------------- Variables -------------------------------------
; Variables guardadas en la common memory
PSECT udata_bank0
    display_var:    DS  8
    tiempo:	    DS  1
    contador1:	    DS  1
    contador2:	    DS  1
    contador3:	    DS  1
    decena:	    DS  1
    flags:	    DS  1
    residuo:	    DS  1
;    resta:	DS  1
;    stage:	DS  1
;    selector:	DS  1
;    dispsele:	DS  1
;    flags:	DS  1
;    flagsem:	DS  1
;    flagst:	DS  1
;    colorflag:	DS  1
;    flagreset:	DS  1
;    sem:	DS  1
;    control01:	DS  1
;    control02:	DS  1
;    control03:	DS  1
;    control04:	DS  1
;    control05:	DS  1
;    control06:	DS  1
;    control07:	DS  1
;    control08:	DS  1
;    count01:	DS  1
;    countsel:	DS  1
;    cont_small:	DS  1
;    timer1:	DS  1
;    timer2:	DS  1
;    timer3:	DS  1
;    tiempo01:	DS  1
;    tiempo02:	DS  1
;    tiempo03:	DS  1
;    preptim01:	DS  1
;    preptim02:	DS  1
;    preptim03:	DS  1  
;    verdec:	DS  1
;    verdet:	DS  1
;    amarillo:	DS  1
    
GLOBAL sem
GLOBAL count01
GLOBAL timer1
GLOBAL timer2
GLOBAL timer3
   
; Variables guardadas en la memoria compartida   
PSECT udata_shr	
    W_TEMP:	    DS  1	; Variable para que se guarde w
    STATUS_TEMP:    DS	1	; Variable para que guarde status
    disp_var:	    DS  5
	
;----------------------- Instrucciones vector reset ----------------------------
PSECT resVect, class=code, abs, delta=2
ORG 00h				;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
;------------------------ Vectores de interrupción -----------------------------
PSECT code, delta=2, abs
ORG 04h 
push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie


;------------------------ Sub-rutinas de interrupción --------------------------
;int_iocb:
;    banksel PORTA
;    btfss   PORTB, UP
;    incf    var
;    movf    var, W
;    movwf   PORTA
;    btfss   PORTB, DOWN
;    decf    var
;    movf    var, W
;    movwf   PORTA
;    bcf	    RBIF
;    return

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
    btfsc   flags, 4
    goto    disp5
    btfsc   flags, 5
    goto    disp6
    btfsc   flags, 6
    goto    disp7
    
int_tmr1:	; Interruocion timer1
    BANKSEL TMR1H   
    movlw   0xE1       ; Modifico los registros del timer1
    movwf   TMR1H
    
    BANKSEL TMR1L
    movlw   0x7C
    movwf   TMR1L
    
    incf    count01	; Se incrementa la variable para el timer
    bcf	    TMR1IF
    
disp0:
    movf    display_var, W
    movwf   PORTC
    bsf	    PORTA, 0
    goto    siguiente_disp
    
disp1:
    movf    display_var+1, W
    movwf   PORTC
    bsf	    PORTA, 1
    goto    siguiente_disp1
    
disp2:
    movf    display_var+2, W
    movwf   PORTC
    bsf	    PORTA, 2
    goto    siguiente_disp2

disp3:
    movf    display_var+3, W
    movwf   PORTC
    bsf	    PORTA, 3
    goto    siguiente_disp3
   
disp4:
    movf    display_var+4, W
    movwf   PORTC
    bsf	    PORTA, 4
    goto    siguiente_disp4
    
disp5:
    movf    display_var+5, W
    movwf   PORTC
    bsf	    PORTA, 5
    goto    siguiente_disp2

disp6:
    movf    display_var+6, W
    movwf   PORTC
    bsf	    PORTA, 6
    goto    siguiente_disp3
   
disp7:
    movf    display_var+7, W
    movwf   PORTC
    bsf	    PORTA, 7
    goto    siguiente_disp4

siguiente_disp:
    movlw   00000001B
    xorwf   flags, 1
    return
    
siguiente_disp1:
    movlw   00000011B
    xorwf   flags, 1
    return

siguiente_disp2:
    movlw   00000110B	
    xorwf   flags, 1
    return
   
siguiente_disp3:
    movlw   00001100B
    xorwf   flags, 1
    return
    
siguiente_disp4:
    movlw   00011000B
    xorwf   flags, 1
    return

siguiente_disp5:
    movlw   00110000B
    xorwf   flags, 1
    return
   
siguiente_disp6:
    movlw   01100000B
    xorwf   flags, 1
    return
    
siguiente_disp7:
    clrf    flags
    return
    
 
;-------------------------------- Tabla ----------------------------------------
    PSECT code, delta=2, abs
    ORG 100h			; Posición para el código de la tabla
;Tabla de conversion de binario a hexadecimal para el 7seg
    tabla7seg:
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
; Configuración a puertos digitales --------------------------------------------
    BANKSEL ANSEL		; Se selecciona el banco
    clrf    ANSEL		; Se definen los puertos digitales
    clrf    ANSELH
    
; Configuración para inputs y outputs de los puertos ---------------------------
    BANKSEL TRISA
    ; Configuración para inputs/outputs de PORTA
    bcf	    TRISA, 0
    bcf	    TRISA, 1
    bcf	    TRISA, 2
    bcf	    TRISA, 3
    bcf	    TRISA, 4
    bcf	    TRISA, 5
    bcf	    TRISA, 6
    bcf	    TRISA, 7
    
    ; Configuración para inputs/outputs de PORTB
    bsf	    TRISB, 0
    bsf	    TRISB, 1
    bsf	    TRISB, 2
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    bcf	    TRISB, 7
    
    ; Configuración para inputs/outputs de PORTC
    bcf	    TRISC, 0
    bcf	    TRISC, 1
    bcf	    TRISC, 2
    bcf	    TRISC, 3
    bcf	    TRISC, 4
    bcf	    TRISC, 5
    bcf	    TRISC, 6
    bcf	    TRISC, 7
    
    ; Configuración para inputs/outputs de PORTD
    bcf	    TRISD, 0
    bcf	    TRISD, 1
    bcf	    TRISD, 2
    bcf	    TRISD, 3
    bcf	    TRISD, 4
    bcf	    TRISD, 5
    
    ; Configuración para inputs/outputs de PORTE
    bcf	    TRISE, 0
    bcf	    TRISE, 1
    bcf	    TRISE, 2
    
; Configuración para el reloj (oscilador interno)-------------------------------
reloj:				; Se configura el oscilador interno
    BANKSEL OSCCON
    bcf	    IRCF2		; IRCF = 010 = 250KHZ
    bsf	    IRCF1   
    bcf	    IRCF0		
    bsf	    SCS			; Activar oscilador interno
    return
    
; Configuracion de Pull-up interno ---------------------------------------------    
    ; Poner puerto b en pull-up
    BANKSEL OPTION_REG
    bcf	    OPTION_REG, 7
    
    BANKSEL WPUB
    bsf	    WPUB, 0	; Se activa el pull-up interno
    bsf	    WPUB, 1	; Se activa el pull-up interno
    bsf	    WPUB, 2	; Los demas pull-up se desactivan
    bcf	    WPUB, 3
    bcf	    WPUB, 4
    bcf	    WPUB, 5
    bcf	    WPUB, 6
    bcf	    WPUB, 7
    
; Interrupciones ---------------------------------------------------------------
    BANKSEl IOCB	; Activar interrupciones
    movlw   00000111B	; Activar las interrupciones en RB0 y RB1
    movwf   IOCB
    
    BANKSEL INTCON
    bsf	    GIE			
    bsf	    RBIE
    bcf	    RBIF
    bsf	    T0IE
    bcf	    T0IF
    
;    BANKSEL PIE1
;    bsf	    TMR2IE		; Se habilita timer2 para pr2
;    bsf	    TMR1IE		; Se habilita la interrupcion por overflow para timer1 -------------
    
;    BANKSEL PIR1
;    bcf	    TMR2IF		; Se limpia la bandera para timer2
;    bcf	    TMR1IF		; Se limpia la bandera de interrupcion para timer1 -----------------
    
    
; Variables para los tiempos
    movlw   10
    movwf   tiempo
    movwf   contador1
    movwf   contador2
    movwf   contador3
; Configuración para timer0 ----------------------------------------------------
    BANKSEL OPTION_REG
    bcf	    T0CS		; Se utilza el prescaler del timer0
    bcf	    PSA			
    bsf	    PS0			; Prescaler 111 = 1:256
    bsf	    PS1
    bsf	    PS2
    
; Configuración para timer1 ----------------------------------------------------
    BANKSEL T1CON
    bsf	    T1CKPS1		; Prescaler 11 = 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS		; Internal clock
    bsf	    TMR1ON		; Habilitar Timer1   
    
; Configuración para timer2 ----------------------------------------------------
    BANKSEL T2CON			
    bsf	    TOUTPS3		
    bcf	    TOUTPS2
    bcf	    TOUTPS1
    bsf	    TOUTPS0		; Postcaler = 1001
    bsf	    TMR2ON		; Habilitar Timer2
    bsf	    T2CKPS1		; Prescaler 10 = 16
    bcf	    T2CKPS0
    
; Se limpian todos los puertos -------------------------------------------------
    BANKSEL PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
;--------------------------------- Loop ----------------------------------------
loop:
    
    
goto    loop
    
;------------------------------ Sub-Rutinas ------------------------------------



    
; Configuración para pines ioc en PORTB
config_ioc:
    banksel TRISA
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN
    bsf	    IOCB, MODE
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF
    return

; Rutina de separación de nibbles
;div_nib:    
;    movf    counter, w
;    andlw   00001111B
;    movwf   nibble
;    swapf   counter, w		; Se cambian los ultimos 4 bits por los primeros
;    andlw   00001111B
;    movwf   nibble+1 
;    return
    
; Rutina para desplegar los valores en el display 7 segmentos
;prep_nib:   
;    movf    nibble, w
;    call    Tabla7seg
;    movwf   disp_var, F		
;    movf    nibble+1, w
;    call    Tabla7seg
;    movwf   disp_var+1, F	
;    bsf	    PORTD, 0
;    return

configl:
    
    ; Para el primer semáforo
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	contador1, w	    ; Se mueve lo que hay en el contador a w
    movwf	residuo		    ; Se mueve w a la variable residuos para operar las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	decena
    subwf	residuo, f	    ; Se le resta 10 a residuos 
    btfsc	STATUS, 0	    ; Se verifica la bandera de status carry
    goto	$-3
    decf	decena		    ; Se incrementa la variable decenas si la bandera es 1
    addwf	residuo
    movf	decena, w
    call	tabla7seg
    movwf	disp_var
    movf	residuo, w
    call	tabla7seg
    movwf	disp_var+1
    
    ; Para el segundo semáforo
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	contador1, w	    ; Se mueve lo que hay en el contador a w
    movwf	residuo		    ; Se mueve w a la variable residuos para operar las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	decena
    subwf	residuo, f	    ; Se le resta 10 a residuos 
    btfsc	STATUS, 0	    ; Se verifica la bandera de status carry
    goto	$-3
    decf	decena		    ; Se incrementa la variable decenas si la bandera es 1
    addwf	residuo
    movf	decena, w
    call	tabla7seg
    movwf	disp_var+2
    movf	residuo, w
    call	tabla7seg
    movwf	disp_var+3
    
    ; Para el tercer semáforo
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	contador1, w	    ; Se mueve lo que hay en el contador a w
    movwf	residuo		    ; Se mueve w a la variable residuos para operar las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	decena
    subwf	residuo, f	    ; Se le resta 10 a residuos 
    btfsc	STATUS, 0	    ; Se verifica la bandera de status carry
    goto	$-3
    decf	decena		    ; Se incrementa la variable decenas si la bandera es 1
    addwf	residuo
    movf	decena, w
    call	tabla7seg
    movwf	disp_var+4
    movf	residuo, w
    call	tabla7seg
    movwf	disp_var+5
    
    return
    
    
         
    
configuracion1:
    bsf		PORTC, 0
    bcf		PORTC, 1
    bcf		PORTC, 2
    bsf		PORTC, 3
    bcf		PORTC, 4
    bcf		PORTC, 5
    bsf		PORTE, 0
    bcf		PORTE, 1
    bcf		PORTE, 2
   
    
    
END				; Se finaliza el codigo