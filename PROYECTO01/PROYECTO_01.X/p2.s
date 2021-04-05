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

delay_small macro
    movlw 248		 ; Valor inicial del contador
    movwf cont_small	
    decfsz cont_small, 1 ; Decrmentar el contador
    goto $-1		 ; Ejecutar linea anterior
    endm

;------------------------------- Variables -------------------------------------
; Variables guardadas en la common memory
PSECT udata_bank0
    disp:	    DS  7
    tiempo:	    DS  1
    counter:	    DS	1
    contador1:	    DS  1
    contador2:	    DS  1
    contador3:	    DS  1
    decena:	    DS  1
    banderas:	    DS  1
    residuo:	    DS  1
    fsem:	    DS	1
    semtemp1:	    DS	1
    semtemp2:	    DS	1
    semtemp3:	    DS	1
    fcolor:	    DS	1
    restante:	    DS	1
    sem_vf:	    DS	1
    sem_vt:	    DS	1
    sem_a:	    DS	1
    flagreset:	    DS	1
    cont_small:	    DS	1
    equivalente:    DS	1
; Variables guardadas en la memoria compartida   
PSECT udata_shr	
    W_TEMP:	    DS  1	; Variable para que se guarde w
    STATUS_TEMP:    DS	1	; Variable para que guarde status
;    disp_var:	    DS  8
    
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
    BANKSEL PORTB
;    btfsc   RBIF	; Revisar si hay interrupciones en el puerto b
;    call    active
	
    btfsc   T0IF	; Revisar si hay overflow del timer0
    call    int_tmr0
    
    btfsc   TMR1IF	; Revisar si hay overflow del timer1
    call    int_tmr1
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie

    
;------------------------ Sub-rutinas de interrupción --------------------------
int_tmr1:		; Interruocion timer1
    BANKSEL TMR1H   
    movlw   0xE1       ; Modifico los registros del timer1
    movwf   TMR1H
    
    BANKSEL TMR1L
    movlw   0x7C
    movwf   TMR1L
    
    incf    counter	; Se decrementa la variable para el timer
    bcf	    TMR1IF
    return

int_tmr0:
    call reset0  ;se hace la interrupcion del timer	    ;se limpia el PORTB
    clrf PORTD
    btfsc banderas, 0	; se hace el bit test para´pasar a un display
    goto display_0	;se va al display 1
    btfsc banderas, 1	; se hace el bit test para´pasar a un display
    goto display_1	; se va al display 2
    btfsc banderas, 2	; se hace el bit test para´pasar a un display
    goto display_2	; se va al display3
    btfsc banderas, 3	
    goto display_3
    btfsc banderas, 4	
    goto display_4
    btfsc banderas, 5	
    goto display_5
    btfsc banderas, 6	
    goto display_6
    btfsc banderas, 7
    goto display_7
    
    
display_0:
    movf disp+0,W	;funcion del display
    movwf PORTC		; mueve la variale display al PORTC
    bsf	PORTD,0		;se activa el bit en la bandera definida
    bcf banderas, 0
    bsf banderas, 1
    return

display_1:
    movf disp+1,W
    movwf PORTC
    bsf PORTD, 1
    bcf banderas, 1
    bsf banderas, 2
    return
    
 display_2:
    movf disp+2,W
    movwf PORTC
    bsf PORTD,2
    bcf banderas,2
    bsf banderas,3
    return

 display_3:
    movf disp+3,W
    movwf PORTC
    bsf PORTD, 3
    bcf banderas,3
    bsf banderas,4
    return

 display_4:
    movf disp+4,W
    movwf PORTC
    bsf PORTD, 4
    bcf banderas,4
    bsf banderas,5
    return

 display_5:
    movf disp+5,W
    movwf PORTC
    bsf PORTD, 5
    bcf banderas,5
    bsf banderas,6
    return

 display_6:
    movf disp+6,W
    movwf PORTC
    bsf PORTD, 6
    bcf banderas,6
    bsf banderas,7
    return
    
display_7:
    movf disp+7,W
    movwf PORTC
    bsf PORTD, 7
    bcf banderas,7
    bsf banderas,0
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
;ORG 100h			; Posición para el código
main:
; Configuración a puertos digitales --------------------------------------------
    BANKSEL ANSEL		; Se selecciona el banco
    clrf    ANSEL		; Se definen los puertos digitales
    clrf    ANSELH
    
; Configuración para inputs y outputs de los puertos ---------------------------
    BANKSEL TRISA
    ; Configuración para inputs/outputs de PORTA
;    bcf	    TRISA, 0
;    bcf	    TRISA, 1
;    bcf	    TRISA, 2
;    bcf	    TRISA, 3
;    bcf	    TRISA, 4
;    bcf	    TRISA, 5
;    bcf	    TRISA, 6
;    bcf	    TRISA, 7
    movlw   00000000B
    movwf   TRISA
    
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
    bcf	    TRISD, 6
    bcf	    TRISD, 7
    
    ; Configuración para inputs/outputs de PORTE
    bcf	    TRISE, 0
    bcf	    TRISE, 1
    bcf	    TRISE, 2
    
; Configuración para el reloj (oscilador interno)-------------------------------
;reloj:				; Se configura el oscilador interno
    BANKSEL OSCCON
    bcf	    IRCF2		; IRCF = 010 = 250KHZ
    bsf	    IRCF1   
    bcf	    IRCF0		
    bsf	    SCS			; Activar oscilador interno
    
    
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
    
; Configuración para timer0 ----------------------------------------------------
    BANKSEL OPTION_REG
    bcf	    T0CS		; Se utilza el prescaler del timer0
    bcf	    PSA			
    bsf	    PS0			; Prescaler 111 = 1:256
    bsf	    PS1
    bsf	    PS2
    reinicio_tmr0
    
; Configuración para timer1 ----------------------------------------------------
    BANKSEL T1CON
    bsf	    T1CKPS1		; Prescaler 11 = 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS		; Internal clock
    bsf	    TMR1ON		; Habilitar Timer1   
   
    
; Configuración para timer2 ----------------------------------------------------
    BANKSEL T2CON			
;    bsf	    TOUTPS3		
;    bcf	    TOUTPS2
;    bcf	    TOUTPS1
;    bsf	    TOUTPS0		; Postcaler = 1001
;    bsf	    TMR2ON		; Habilitar Timer2
;    bsf	    T2CKPS1		; Prescaler 10 = 16
;    bcf	    T2CKPS0
    BANKSEL T2CON
    movlw   1001110B     ;1001 para el postcaler, 1 timer 2 on, 10 precaler 16
    movwf   T2CON
    
    
; Se limpian todos los puertos -------------------------------------------------
    BANKSEL PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    
; Variables para los tiempos ---------------------------------------------------
    movlw   10
;    movwf   tiempo
    movwf   contador1
    movwf   contador2
    movwf   contador3
    
;--------------------------------- Loop ----------------------------------------
loop:
    call    config_semaforos
    call    timers
    call    tiemposem1
    call    tiemposem2
    call    tiemposem3
    
    
goto    loop    
    
    
;------------------------------ Sub-Rutinas ------------------------------------
; Configuración para pines ioc en PORTB
;config_ioc:
;    banksel TRISA
;    bsf	    IOCB, UP
;    bsf	    IOCB, DOWN
;    bsf	    IOCB, MODE
;    
;    banksel PORTA
;    movf    PORTB, W
;    bcf	    RBIF
;    return    
    
; Rutina para configuración del reset timer0
reset0:
    BANKSEL PORTA
    movlw   255			; Tiempo de la instrucción
    movwf   TMR0
    bcf	    T0IF		; Se vuelve 0 el bit de overflow
    return
    
tiemposem1:
    ; Para el primer semáforo
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	semtemp1, w	    ; Se mueve lo que hay en el contador a w
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
    movwf	disp
    movf	residuo, w
    call	tabla7seg
    movwf	disp+1
    return
    
tiemposem2:    
    ; Para el segundo semáforo
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	semtemp2, w	    ; Se mueve lo que hay en el contador a w
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
    movwf	disp+2
    movf	residuo, w
    call	tabla7seg
    movwf	disp+3
    return
    
tiemposem3:
    ; Para el tercer semáforo
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	semtemp3, w	    ; Se mueve lo que hay en el contador a w
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
    movwf	disp+4
    movf	residuo, w
    call	tabla7seg
    movwf	disp+5
    return    
    
; Subrutina de decremento para los semaforos -----------------------------------
timers:
    
    btfsc   fsem, 0	; flagsem es una variable 
    goto    tsem2
    
    btfsc   fsem, 1
    goto    tsem3
    
    btfsc   fsem, 2
    goto    resettemp
    
tsem1:	    ; Timer1
    bcf	    STATUS, 2	    ; Se limpia el status
    movf    contador1, w	    ; Se mueve el tiempo a w
    movwf   semtemp1	    ; W se mueve a la variable que se muestra
    movf    counter, w	    ; Se mueve el contador a w
    subwf   semtemp1, 1	    ; Se le va restando a la variable del tiempo
    btfss   STATUS, 2	    ; Se espera hasta que sea 0
    goto    $+4		    ; Suce una vez status no se prenda
    bsf	    fsem, 0	    ; Prende bandera de sem02
    movlw   0
    movwf   counter	    ; Se reinicia el contador del timer1
    return
    
tsem2:	    ; Timer2
    bcf	    STATUS, 2
    movf    contador2, w
    movwf   semtemp2
    movf    counter, w
    subwf   semtemp2, 1
    btfss   STATUS, 2
    goto    $+5
    bcf	    fsem, 0
    bsf	    fsem, 1
    movlw   0
    movwf   counter
    return
    
tsem3:	    ; Timer3
    bcf	    STATUS, 2
    movf    contador3, w
    movwf   semtemp3
    movf    counter, w
    subwf   semtemp3, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    fsem, 1
    bsf	    fsem, 2
    return

resettemp:	    ; Reinicio de timers
    clrf    counter	; Se limpia el contador del timer1
    clrf    fsem	; Se limpian las banderas
    bcf	    TMR1IF	; Se limpia el overflow del timer1
    return
    
; Configuración para los colores de los semáforos
; Para esto se creo una subrutina diferente para cada combinación
config_semaforos:
    btfsc   fcolor, 0
    goto    combinacion2
    
    btfsc   fcolor, 1  
    goto    combinacion3
    
    btfsc   fcolor, 2
    goto    combinacion4
    
    btfsc   fcolor, 3
    goto    combinacion5
    
    btfsc   fcolor, 4 
    goto    combinacion6
    
    btfsc   fcolor, 5 
    goto    combinacion7
    
    btfsc   fcolor, 6 
    goto    combinacion8
    
    btfsc   fcolor, 7
    goto    combinacion9
    
combinacion1:
    bcf	    STATUS, 2
    bcf	    PORTA, 0	
    bcf	    PORTA, 1	
    bsf	    PORTA, 2	
    bsf	    PORTA, 3	
    bcf	    PORTA, 4	
    bcf	    PORTA, 5	
    bsf	    PORTE, 0	
    bcf	    PORTE, 1	
    bcf	    PORTE, 2	
    
    movf    contador1, w	    ; Muevo tiempo a w
    movwf   sem_vf	    ; muevo w a la variable del verde full
    movlw   6		    
    subwf   sem_vf, 1	    ; Le resto al verde full los 6 fijos
    movf    sem_vf, w	    ; muevo lo restante de la resta a otra variable
    movwf   restante	    
    movf    counter, w	    ; Con el timer uno voy decrementndo verdec
    subwf   sem_vf, 1
    btfss   STATUS, 2	    ; Cuando da 0, se activa la bandera status
    goto    $+3		    ; Con ese salto logro pasarme al siguiente color
    bcf	    PORTA, 2
    bsf	    fcolor, 0
    return
    
combinacion2:	    ; Verde titilante  
    bcf	    STATUS, 2
    bsf	    PORTA, 2
    delay_small
    bcf	    PORTA, 2
    movlw   3
    addwf   restante, w
    movwf   sem_vt
    movf    counter, w
    subwf   sem_vt, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    fcolor, 0
    bsf	    fcolor, 1
    return
 
combinacion3:	    ; Amarillo
    bcf	    STATUS, 2
    bsf	    PORTA, 1
    call    equi
    movf    equivalente, w
    movwf   sem_a
    movf    counter, w
    subwf   sem_a, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    fcolor, 1
    bsf	    fcolor, 2
    bcf	    PORTA, 1
    return
combinacion4:	    ; Verde 
    bcf	    STATUS, 2
    bcf	    PORTA, 3
    bsf	    PORTA, 0
    bsf	    PORTA, 5
    movf    contador2, w
    movwf   sem_vf 
    movlw   6
    subwf   sem_vf, 1
    movf    sem_vf, w
    movwf   restante
    movf    counter, w
    subwf   sem_vf, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    PORTA, 5
    bcf	    fcolor, 2
    bsf	    fcolor, 3    
    return
combinacion5:	    ; Verde titilantes
    bcf	    STATUS, 2
    bsf	    PORTA, 5
    delay_small
    bcf	    PORTA, 5
    movlw   3
    addwf   restante, w
    movwf   sem_vt
    movf    counter, w
    subwf   sem_vt, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    fcolor, 3
    bsf	    fcolor, 4
    return
combinacion6:	    ; Amarillo
    bcf	    STATUS, 2
    bsf	    PORTA, 4
    movlw   6
    addwf   restante, w
    movwf   sem_a
    movf    counter, w
    subwf   sem_a, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    fcolor, 4
    bsf	    fcolor, 5
    bcf	    PORTA, 4
    return  
combinacion7:	    ; Verde full
    bcf	    STATUS, 2
    bcf	    PORTE, 0
    bsf	    PORTA, 3
    bsf	    PORTE, 2
    movf    contador2, w
    movwf   sem_vf 
    movlw   6 
    subwf   sem_vf, 1
    movf    sem_vf, w
    movwf   restante
    movf    counter, w
    subwf   sem_vf, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    PORTE, 2
    bcf	    fcolor, 5
    bsf	    fcolor, 6    
    return    
combinacion8:	    ; verde titilante
    bcf	    STATUS, 2
    bsf	    PORTE, 2
    delay_small
    bcf	    PORTE, 2
    movlw   3
    addwf   restante, w
    movwf   sem_vt
    movf    counter, w
    subwf   sem_vt, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    fcolor, 6
    bsf	    fcolor, 7
    return   
combinacion9:	    ; Amarillo
    bcf	    STATUS, 2
    bsf	    PORTE, 1
    movlw   6
    addwf   restante, w
    movwf   sem_a
    movf    counter, w
    subwf   sem_a, 1
    btfss   STATUS, 2
    goto    $+5
    bcf	    fcolor, 7
    bsf	    flagreset, 0
    bcf	    PORTE, 1
    bsf	    PORTE, 0 
    return
    
    
equi:
    movlw   6
    addwf   restante, w
    movwf   equivalente
    return
    
END