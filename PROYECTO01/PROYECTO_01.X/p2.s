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
; Rutina para el delay de parpadeo
delay_small macro
    movlw 248			; Valor inicial del contador
    movwf small	
    decfsz small, 1		; Se decrmenta el contador
    goto $-1			
    endm

;------------------------------- Variables -------------------------------------
; Variables guardadas en la common memory
PSECT udata_bank0
    small:	    DS	1
    flags:	    DS	1
    fsem:	    DS	1
    fcolor:	    DS	1
    flagreset:	    DS	1
    festm:	    DS	1
    display:	    DS  7 
    dispm1:	    DS	1
    dispm2:	    DS	1
    counter:	    DS	1
    contador1:	    DS  1
    contador2:	    DS  1
    contador3:	    DS  1
    counterm:	    DS	1
    decena:	    DS  1
    residuo:	    DS  1
    restante:	    DS	1
    equivalente:    DS	1
    semtemp1:	    DS	1
    semtemp2:	    DS	1
    semtemp3:	    DS	1
    tempm:	    DS  1
    sem_vf:	    DS	1
    sem_vt:	    DS	1
    sem_a:	    DS	1    
    estado:	    DS	1
    modsel:	    DS	1
    modo:	    DS	1    
    modtemp1:	    DS	1
    modtemp2:	    DS	1
    modtemp3:	    DS	1
    modesel:	    DS	1
    reinicio:	    DS	1
    
; Variables guardadas en la memoria compartida   
PSECT udata_shr	
    W_TEMP:	    DS  1	; Variable para que se guarde w
    STATUS_TEMP:    DS	1	; Variable para que guarde status
    
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
    btfsc   RBIF		; Se revisa si hay interrupciones en PORTB
    call    mode_select
	
    btfsc   T0IF		; Se revisa si hay overflow del timer0
    call    int_tmr0
    
    btfsc   TMR1IF		; Se revisa si hay overflow del timer1
    call    int_tmr1
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie

    
;------------------------ Sub-rutinas de interrupción --------------------------
; Configuración de interrupción para el timer1 ---------------------------------
int_tmr1:		
    BANKSEL TMR1H   
    movlw   0xE1		; Se modifican los registros del timer1
    movwf   TMR1H
    
    BANKSEL TMR1L
    movlw   0x7C
    movwf   TMR1L
    
    incf    counter		; Se decrementa la variable para el timer1
    bcf	    TMR1IF		; Se limpia la bandera
    return

; Configuración de la interrupción del timer0 ----------------------------------
int_tmr0:
    call    reset_tmr0		; Se resetea el timer0
    clrf    PORTD		; Se limpian los pinesdel puerto para el 7 segmentos
    
; Lo que se busca hacer aca es revisar que display esta activado he ir al sig.
    btfsc   flags, 0		; Se verifica la bandera 
    goto    disp2
    btfsc   flags, 1
    goto    disp3
    btfsc   flags, 2
    goto    disp4
    btfsc   flags, 3
    goto    disp5
    btfsc   flags, 4
    goto    disp6
    btfsc   flags, 5
    goto    disp7
    btfsc   flags, 6
    goto    disp8
     
; Rutinas internas para activar los displays -----------------------------------
disp1:
    movf    display, w
    movwf   PORTC
    bsf	    PORTD, 0
    goto    siguiente_disp
disp2:
    movf    display+1, W
    movwf   PORTC
    bsf	    PORTD, 1
    goto    siguiente_disp01
disp3:
    movf    display+2, W
    movwf   PORTC
    bsf	    PORTD, 2
    goto    siguiente_disp02
disp4:
    movf    display+3, W
    movwf   PORTC
    bsf	    PORTD, 3
    goto    siguiente_disp03
disp5:
    movf    display+4, W
    movwf   PORTC
    bsf	    PORTD, 4
    goto    siguiente_disp04
disp6:
    movf    display+5, W
    movwf   PORTC
    bsf	    PORTD, 5
    goto    siguiente_disp05 
disp7:
    movf    dispm1, W
    movwf   PORTC
    bsf	    PORTD, 6
    goto    siguiente_disp06
disp8:
    movf    dispm2, W
    movwf   PORTC
    bsf	    PORTD, 7
    goto    siguiente_disp07
    
; Rutinas para las rotaciones de los displays ----------------------------------
siguiente_disp:  
    MOVLW   00000001B   
    XORWF   flags, 1
    RETURN
siguiente_disp01:
    MOVLW   00000011B
    xorwf   flags, 1
    return
siguiente_disp02:
    movlw   00000110B
    xorwf   flags, 1
    return
siguiente_disp03:
    movlw   00001100B
    xorwf   flags, 1
    return
siguiente_disp04:
    movlw   00011000B
    xorwf   flags, 1
    return
siguiente_disp05:
    movlw   00110000B
    xorwf   flags, 1
    return
siguiente_disp06:
    movlw   01100000B
    xorwf   flags, 1
    return
siguiente_disp07:
    clrf    flags
    return
    
; Rutina para los pushbuttons --------------------------------------------------
mode_select:   
    btfss   PORTB, UP		; Se revisa si se presiona el push 1
    call    inctemp		; Llama a la rutina de incremento de tiempo
    btfss   PORTB, DOWN		; Se revisa si se presiona el push 2
    call    dectemp		; Llama a la rutina de decremento de tiempo
    btfss   PORTB, MODE
    call    estadom		; Llama a la rutina de seleccion de modo
    bcf	    RBIF
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
    movlw   00000000B
    movwf   TRISC
    
    ; Configuración para inputs/outputs de PORTD
    movlw   00000000B
    movwf   TRISD
    
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
    ; Se ponen los pines de PORTB en pull-up
    BANKSEL OPTION_REG
    bcf	    OPTION_REG, 7
    
    BANKSEL WPUB
    bsf	    WPUB, 0		; Se activa el pull-up interno del pin RB0
    bsf	    WPUB, 1		; Se activa el pull-up interno del pin RB1
    bsf	    WPUB, 2		; Se activa el pull-up interno del pin RB2
    ; Se desactivan los pull-ups internos del resto de pines
    bcf	    WPUB, 5
    bcf	    WPUB, 6
    bcf	    WPUB, 7
    
; Interrupciones ---------------------------------------------------------------
    BANKSEl IOCB		; Se activan las interrupciones
    movlw   00000111B		; Se activan las interrupciones en RB0 y RB1
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
    call    reset_tmr0		; Se reinicia el timer0
    
; Configuración para timer1 ----------------------------------------------------
    BANKSEL T1CON
    bsf	    T1CKPS1		; Prescaler 11 = 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS		; Internal clock
    bsf	    TMR1ON		; Habilitar Timer1   
        
; Se limpian todos los puertos -------------------------------------------------
    BANKSEL PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    
; Variables para los tiempos ---------------------------------------------------
    movlw   10
    movwf   tempm
    movwf   contador1
    movwf   contador2
    movwf   contador3
    
;--------------------------------- Loop ----------------------------------------
loop:
    
    ; Se mandan a llamar las rutinas para el funcionamiento de los semáforos
    call    config_semaforos	; Se llama a la configuración de leds para los semaforos
    call    timers		; Se llama a la configuración de tiempos ára los semáforos
    call    tiemposem1		; Se llaman las configuraciones de los displays de los semáforos
    call    tiemposem2
    call    tiemposem3
    
    ; Se mandan a llamar las rutinas para el funcionamiento de los modos
    btfsc   modsel, 0		; Se revisan las banderas
    call    modo1		; Se llama a una rutina de configuración de displays de modo
    btfsc   modsel, 1		
    call    modo2 
    btfsc   modsel, 2
    call    modo3 
    btfsc   modsel, 3
    call    accept		; Se llama la rutina de aceptar cambios
    
goto    loop    
    
;------------------------------ Sub-Rutinas ------------------------------------
; Rutina para configuración del reset timer0 -----------------------------------
reset_tmr0:
    BANKSEL PORTA
    movlw   255			; Tiempo de la instrucción
    movwf   TMR0
    bcf	    T0IF		; Se vuelve 0 el bit de overflow
    return
    
; Subrutina para limpiar todas las banderas ------------------------------------
reseteoc:	    
    call    reseteom
    clrf    fsem
    clrf    fcolor
    clrf    festm
    clrf    counter
    clrf    modsel
    clrf    semtemp1
    clrf    semtemp2
    clrf    semtemp3
    return 
           
; Configuración para los displays de los semáforos -----------------------------   
; Para el primer semáforo
tiemposem1:
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	semtemp1, w	; Se mueve lo que hay en el contador a w
    movwf	residuo		; Se mueve w a la variable residuos para operar las decenas
    movlw	10		; Se mueve 10 a w
    incf	decena
    subwf	residuo, f	; Se le resta 10 a residuos 
    btfsc	STATUS, 0	; Se verifica la bandera de status carry
    goto	$-3
    decf	decena		; Se incrementa la variable decenas si carry = 1
    addwf	residuo
    movf	decena, w	; Se guardan los resultados
    call	tabla7seg	; Se traducen los resultados con la tabla
    movwf	display		; Se mandan los resultados a los displays
    movf	residuo, w
    call	tabla7seg
    movwf	display+1
    return
    
; Para el segundo semáforo
tiemposem2:    
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	semtemp2, w	    
    movwf	residuo		    
    movlw	10		    
    incf	decena
    subwf	residuo, f	     
    btfsc	STATUS, 0	    
    goto	$-3
    decf	decena		    
    addwf	residuo
    movf	decena, w
    call	tabla7seg
    movwf	display+2
    movf	residuo, w
    call	tabla7seg
    movwf	display+3
    return
    
; Para el tercer semáforo
tiemposem3:
    clrf	decena
    clrf	residuo
    bcf		STATUS, 0
    movf	semtemp3, w	    
    movwf	residuo		    
    movlw	10		    
    incf	decena
    subwf	residuo, f	     
    btfsc	STATUS, 0	    
    goto	$-3
    decf	decena		    
    addwf	residuo
    movf	decena, w
    call	tabla7seg
    movwf	display+4
    movf	residuo, w
    call	tabla7seg
    movwf	display+5
    return    

; NOTA: El unico cambio entre las tres subrutinas es el valor del contador utilizado(semtemp)
    
    
    
    
    
    
    
    
; Subrutina de decremento para los semaforos -----------------------------------
timers:
    btfsc   fsem, 0		; Se revisa que bandera está encendida
    goto    tsem2
    btfsc   fsem, 1
    goto    tsem3
    btfsc   fsem, 2
    goto    resettemp
    
tsem1:	    ; Timer1
    bcf	    STATUS, 2		; Se limpia el status
    movf    contador1, w	; Se mueve el tiempo a w
    movwf   semtemp1		; W se mueve a la variable que se muestra
    movf    counter, w		; Se mueve el contador a w
    subwf   semtemp1, 1		; Se le va restando a la variable del tiempo
    btfss   STATUS, 2		; Se espera hasta que sea 0
    goto    $+4			; Suce una vez status no se prenda
    bsf	    fsem, 0		; Prende bandera de sem02
    movlw   0
    movwf   counter		; Se reinicia el contador del timer1
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
    
; Configuración para los colores de los semáforos ------------------------------
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
    
; Configuración para la selección de modo --------------------------------------
    estadom:
    incf    estado	; Se incrementa una variable para verificar el estado		
    btfsc   festm, 0	; flagst es una variable 
    goto    estm1    
    btfsc   festm, 1
    goto    estm2    
    btfsc   festm, 2
    goto    estm3    
    btfsc   festm, 3
    goto    reseteom
  
estm:    ; Modo0
    bcf	    PORTB, 5	    ; Se apagan todas las leds
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    bcf	    STATUS, 2	    ; Se limpia la bandera del status
    movlw   1	    
    movwf   counterm	    ; Se revisa si la variable es 1
    movf    estado, w	    
    subwf   counterm, w
    btfss   STATUS, 2	    ; Cuando sea uno, se activa el status
    goto    $+4
    bsf	    PORTB, 5	    ; Se activa la led para el siguiente estado
    bsf	    festm, 0	    ; Se activa la bandera de estado
    bsf	    modsel, 0	    ; Se activa la bandera de seleccion de division
    return
estm1:   ; Modo1
    bcf	    STATUS, 2
    movlw   2
    movwf   counterm	    ; Se verifica que la variable sea 2
    movf    estado, w
    subwf   counterm, w
    btfss   STATUS, 2	    ; Cuando es 2 se activa el status
    goto    $+7
    bcf	    PORTB, 5
    bsf	    PORTB, 6	    ; Se apaga la led anterior y se prende la siguiente
    bcf	    festm, 0
    bsf	    festm, 1	    ; Cambio de bnderas
    bcf	    modsel, 0
    bsf	    modsel, 1
    return
estm2:   ; Modo2
    bcf	    STATUS, 2
    movlw   3
    movwf   counterm
    movf    estado, w
    subwf   counterm, w
    btfss   STATUS, 2
    goto    $+7
    bcf	    PORTB, 6
    bsf	    PORTB, 7
    bcf	    festm, 1
    bsf	    festm, 2
    bcf	    modsel, 1
    bsf	    modsel, 2
    return
estm3:   ; Modo3
    bcf	    STATUS, 2
    movlw   4
    movwf   counterm
    movf    estado, w
    subwf   counterm, w
    btfss   STATUS, 2
    goto    $+6
    bsf	    PORTB, 5
    bsf	    PORTB, 6
    bsf	    PORTB, 7
    bcf	    festm, 2
    bsf	    festm, 3
    bcf	    modsel, 2
    bsf	    modsel, 3
    return
reseteom:	    ; Modo de reincio
    clrf    dispm1	    ; Se limpian las variables del display para 
    clrf    dispm2	    ; que estos esten apgados en el modo0
    bcf	    PORTB, 5	    ; Se apaga la ultima led
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    clrf    festm	    ; Se limpian las banderas
    clrf    estado	    ; Se limpia la variable de estado
    clrf    modsel
    return
    
; configuración para los displays de los modos ---------------------------------
modo1:   ; Se crea la subrutina de la separacion de valores
    clrf	modo
    clrf	residuo
    bcf		STATUS, 0
    movf	tempm, 0	    ; Se mueve lo que hay en el contador a w
    movwf	modtemp1
    movwf	modo	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	modo, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	modo
    movf	residuo, w
    call	tabla7seg
    movwf	dispm1
    movf	modo, w
    call	tabla7seg
    movwf	dispm2    
    return
    
modo2:   ; Se crea la subrutina de la separacion de valores
    clrf	modo
    clrf	residuo
    bcf		STATUS, 0
    movf	tempm, 0	    ; Se mueve lo que hay en el contador a w
    movwf	modtemp2
    movwf	modo	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	modo, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	modo
    movf	residuo, w
    call	tabla7seg
    movwf	dispm1
    movf	modo, w
    call	tabla7seg
    movwf	dispm2    
    return
    
modo3:   ; Se crea la subrutina de la separacion de valores
    clrf	modo
    clrf	residuo
    bcf		STATUS, 0
    movf	tempm, 0	    ; Se mueve lo que hay en el contador a w
    movwf	modtemp3
    movwf	modo	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	modo, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	modo
    movf	residuo, w
    call	tabla7seg
    movwf	dispm1
    movf	modo, w
    call	tabla7seg
    movwf	dispm2    
    return
    
; Rutina para incrementar los tiempos ------------------------------------------
inctemp:
    incf    tempm		; Se incrementa una variable
    bcf     STATUS, 2	; Se limpia status
    movlw   21		
    subwf   tempm, w	; Se verifica que no sea mayor a 21
    btfss   STATUS, 2
    goto    $+3
    movlw   10		; Si es mayor a 20, se le pone automaticamente 10
    movwf   tempm 
    return
    
; Rutina para decrementar los tiempos ------------------------------------------
dectemp:
    decf    tempm		; Variable a decrementar
    bcf	    STATUS, 2
    movlw   9
    subwf   tempm, w	; Se verifica que no sea menor a 10
    btfss   STATUS, 2
    goto    $+3
    movlw   20		; Si llega a ser menor de 10, se le pone 20
    movwf   tempm
    return 
    
; Rutina para aceptar o rechazar los cambios -----------------------------------
accept:
    movlw	0
    call	tabla7seg	    ; Se muestra AC en el display para saber 
    movwf	dispm1   ; en que modo se encuentran
    movlw	0
    call	tabla7seg
    movwf	dispm2
    
    btfss	PORTB, UP    ; Se revisa si se apacha el boton de aceptar
    call	send  ; Se llama a la rutina de confirmar
    btfss	PORTB, DOWN    ; Se revisa si se apacha el boton de cancelar
    call	reseteom	    ; Se limpia la rutina de estados
    return
    
; Rutina para mandar los tiempos a los semáforos -------------------------------
send:
    bsf	    reinicio, 0	; Se utiliza esto para que los displas se detengan
    call    reseteoc	; Se llama al reseteo completo
    movf    modtemp1, w    ; Se mueven las variables a los timers
    movwf   contador1
    movf    modtemp2, w
    movwf   contador2
    movf    modtemp3, w
    movwf   contador3
    delay_small
    bcf	    reinicio, 0
    return
    
END