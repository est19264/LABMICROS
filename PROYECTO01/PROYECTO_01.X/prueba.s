;******************************************************************************
; Proyecto_01
;*****************************************************************************
; Archivo:	Proyecto.s
; Dispositivo:	PIC16F887
; Autor:	Marco Duarte
; Compilador:	pic-as (v2.30), MPLABX V5.45
;******************************************************************************

PROCESSOR 16F887
#include <xc.inc>

;******************************************************************************
; Palabras de configuracion 
;******************************************************************************

; CONFIG1
  CONFIG  FOSC =    INTRC_NOCLKOUT   ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE =    OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE =   OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE =   OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP =	    OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD =	    OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN =   OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO =    OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN =   OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP =	    ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V =   BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT =	    OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;******************************************************************************
; Macros
;******************************************************************************
  titileo01 macro
    bsf	    PORTA, 2
    call    delay_small
    bcf	    PORTA, 2
    call    delay_small
    bsf	    PORTA, 2
    endm
    
    delay_small macro
    movlw 248		 ; Valor inicial del contador
    movwf cont_small	
    decfsz cont_small, 1 ; Decrmentar el contador
    goto $-1		 ; Ejecutar linea anterior
    endm
;******************************************************************************
; Variables
;******************************************************************************
      ; Se definen variables 
//<editor-fold defaultstate="collapsed" desc="Variables Share Memory">
PSECT udata_shr ;Common memory
    
W_TEMP:	    ; Variable para que se guarde w
	DS 1
STATUS_TEMP:    ; Variable para que guarde status
	DS 1
disp_var:
	DS  8//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Variables Bank0">
PSECT udata_bank0 
residuo:
	DS  1
stage:
	DS  1
selector:
	DS  1
flags:
	DS  1
sem:
	DS 1
control01:
	DS 1
control02:
	DS 1
count01:
	DS 1
timer1:
	DS 1
timer2:
	DS 1
timer3:
	DS 1
control03:
	DS 1
control04:
        DS 1
flagsem:
	DS 1
control05:
	DS 1
control06:
        DS 1
control07:
	DS 1
control08:
        DS 1
flagst:
        DS 1
countsel:
        DS 1
preptim01:
        DS 1
preptim02:
        DS 1
preptim03:
        DS 1
tiempo01:
        DS 1
tiempo02:
        DS 1
tiempo03:
        DS 1
dispsele:
	DS 1
verdec:
	DS 1
verdet:
	DS 1
amarillo:
	DS 1
colorflag:
	DS 1
resta:
	DS 1
flagreset:
	DS 1
cont_small:
	DS 1
reinicio:
	DS 1
fix:
	DS 1
accept:
	DS 1
	//</editor-fold>
	
GLOBAL sem
GLOBAL count01
GLOBAL timer1
GLOBAL timer2
GLOBAL timer3
	
;******************************************************************************
; Vector Reset
;******************************************************************************
PSECT resVect, class=code, abs, delta=2
;--------------------------vector reset-----------------------------------------
ORG 00h        ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
;******************************************************************************
; Interrupciones
;******************************************************************************
PSECT code, delta=2, abs
ORG 04h 
    
push:			; Mover las variables temporales a w
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:	
    BANKSEL PORTB
    btfsc   RBIF	; Revisar si hay interrupciones en el puerto b
    call    active
	
    btfsc   T0IF	; Revisar si hay overflow del timer0
    call    int_tmr
    
    btfsc   TMR1IF	; Revisar si hay overflow del timer1
    call    int_tmr1
 
pop:			; Regresar w al status
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
 ;------------------------Sub rutinas de interrupcion--------------------------
 
//<editor-fold defaultstate="collapsed" desc="Interrupcion Timer1">
int_tmr1:	; Interruocion timer1
    BANKSEL TMR1H   
    movlw   0xE1       ; Modifico los registros del timer1
    movwf   TMR1H
    
    BANKSEL TMR1L
    movlw   0x7C
    movwf   TMR1L
    
    incf    count01	; Se incrementa la variable para el timer
    bcf	    TMR1IF
    return //</editor-fold>
   
//<editor-fold defaultstate="collapsed" desc="Multiplexado">
int_tmr:
    call    reset0	; Se limpia el TMR0
    clrf    PORTD	; Se impia el puerto del 7 segmentos
    
; Lo que se busca hacer aca es revisar que display esta activado he ir al sig.
    btfsc   flags, 0	; Flags es una variable 
    goto    disp_02
    
    btfsc   flags, 1
    goto    disp_03
    
    btfsc   flags, 2
    goto    disp_04
    
    btfsc   flags, 3
    goto    disp_05
    
    btfsc   flags, 4
    goto    disp_06
    
    btfsc   flags, 5
    goto    disp_07
    
    btfsc   flags, 6
    goto    disp_08
     
    ; Se crean varias rutinas internas para activar los displays
disp_01:
    movf    control03, w
    movwf   PORTC
    bsf	    PORTD, 0
    goto    next_disp
disp_02:
    movf    control04, W
    movwf   PORTC
    bsf	    PORTD, 1
    goto    next_disp01
disp_03:
    movf    control05, W
    movwf   PORTC
    bsf	    PORTD, 2
    goto    next_disp02
disp_04:
    movf    control06, W
    movwf   PORTC
    bsf	    PORTD, 3
    goto    next_disp03
disp_05:
    movf    control07, W
    movwf   PORTC
    bsf	    PORTD, 4
    goto    next_disp04
disp_06:
    movf    control08, W
    movwf   PORTC
    bsf	    PORTD, 5
    goto    next_disp05 
disp_07:
    movf    control01, W
    movwf   PORTC
    bsf	    PORTD, 6
    goto    next_disp06
disp_08:
    movf    control02, W
    movwf   PORTC
    bsf	    PORTD, 7
    goto    next_disp07
    
next_disp:  ; Se crean XOR para cada display en modo de hacer rotaciones
    MOVLW   00000001B   ; Se empieza con un bit
    XORWF   flags, 1
    RETURN
next_disp01:
    MOVLW   00000011B
    xorwf   flags, 1
    return
next_disp02:
    movlw   00000110B
    xorwf   flags, 1
    return
next_disp03:
    movlw   00001100B
    xorwf   flags, 1
    return
next_disp04:
    movlw   00011000B
    xorwf   flags, 1
    return
next_disp05:
    movlw   00110000B
    xorwf   flags, 1
    return
next_disp06:
    movlw   01100000B
    xorwf   flags, 1
    return
next_disp07:
    clrf    flags
    return//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Rutina para botones">
active:   ; La subrutina para los pushbuttons
    btfss   PORTB, 0	; Se revisa si se apacha el boton 1
    call    up
    btfss   PORTB, 1	; Se revisa si se apacha el boton 2
    call    down	; Se decrementa1
    btfss   PORTB, 2
    call    selstage	; Se va a la rutina de la seleccion de estado
    bcf	    RBIF
    return //</editor-fold>

;******************************************************************************
; Configuracion de tabla
;******************************************************************************
PSECT code, delta=2, abs
ORG 100h    ;posicion para el codigo
 
; Tabla de la traduccion de binario a decimal
//<editor-fold defaultstate="collapsed" desc="Tabla para traducir">
table:
    clrf	PCLATH
    bsf		PCLATH, 0
    andlw	0x0F	    ; Se pone como limite F , en hex 15
    addwf	PCL
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F//</editor-fold>
 
;******************************************************************************
; Configuracion 
;******************************************************************************
    ; Esta es la configuracion de los pines
ORG 118h
main:
    ; Configurar puertos digitales
    BANKSEL ANSEL	; Se selecciona bank 3
    clrf    ANSEL	; Definir puertos digitales
    clrf    ANSELH
    
    ; Configurar puertos de salida A
    BANKSEL TRISA	; Se selecciona bank 1
    bcf	    TRISA,  0	; R0 lo defino como output
    bcf	    TRISA,  1	; R1 lo defino como output
    bcf	    TRISA,  2	; R2 lo defino como output
    bcf	    TRISA,  3	; R3 lo defino como output
    bcf	    TRISA,  4	; R4 lo defino como output
    bcf	    TRISA,  5	; R5 lo defino como output
    bcf	    TRISA,  6	; R5 lo defino como output
    bcf	    TRISA,  7	; R5 lo defino como output

    ; Configurar puertos de salida B
    BANKSEL TRISB	; Se selecciona bank 1
    bsf	    TRISB,  0	; R0 lo defino como input
    bsf	    TRISB,  1	; R1 lo defino como input
    bsf	    TRISB,  2	; R2 lo defino como input
    bcf	    TRISB,  4	; R2 lo defino como input
    bcf	    TRISB,  5	; R5 lo defino como onput
    bcf	    TRISB,  6	; R6 lo defino como onput
    bcf	    TRISB,  7	; R7 lo defino como onput
        
    ; Configurar puertos de salida C
    BANKSEL TRISC	; Se selecciona bank 1
    bcf	    TRISC,  0	; R0 lo defino como output
    bcf	    TRISC,  1	; R1 lo defino como output
    bcf	    TRISC,  2	; R2 lo defino como output
    bcf	    TRISC,  3	; R3 lo defino como output
    bcf	    TRISC,  4	; R4 lo defino como output
    bcf	    TRISC,  5	; R5 lo defino como output
    bcf	    TRISC,  6	; R6 lo defino como output
    bcf	    TRISC,  7	; R7 lo defino como output
    
    ; Configurar puertos de salida D
    BANKSEL TRISD	; Se selecciona el bank 1
    bcf	    TRISD,  0	; R0 lo defino como output
    bcf	    TRISD,  1	; R1 lo defino como output
    bcf	    TRISD,  2	; R2 lo defino como output
    bcf	    TRISD,  3	; R3 lo defino como output
    bcf	    TRISD,  4	; R4 lo defino como output
    bcf	    TRISD,  5	; R5 lo defino como output
    bcf	    TRISD,  6	; R6 lo defino como output
    bcf	    TRISD,  7	; R7 lo defino como output
    
    ;***************Configuracion de Pull-up interno***************************    
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
    ;************************************************************************** 
    
    ; Se llama las configuraciones del clock
    call    clock		; Llamo a la configurcion del oscilador interno
    
    ;***************Configuracion de interrupciones****************************
    BANKSEl IOCB	; Activar interrupciones
    movlw   00000111B	; Activar las interrupciones en RB0 y RB1
    movwf   IOCB
    
    BANKSEL INTCON
    bcf	    RBIF
    
        ; Bits de interrupcion
    bsf	    GIE		; Interrupcion global
    bsf	    RBIE	; Interrupcion puerto b
    bsf	    T0IE	; Interrupcion timer0
    bcf	    T0IF
    ;**************************************************************************
    
    ;***************Configuracion de Timer0************************************
    BANKSEL OPTION_REG
    BCF	    T0CS
    BCF	    PSA		;prescaler asignado al timer0
    BSF	    PS0		;prescaler tenga un valor 1:256
    BSF	    PS1
    BSF	    PS2
    ;**************************************************************************
    
    ;****************Configuracion de Timer1***********************************
    BANKSEL T1CON
    bsf	    T1CKPS1	;prescaler 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS	;internal clock
    bsf	    TMR1ON	;habilitar timer1
    ;**************************************************************************

    ;****************Configuracion de Timer2***********************************
    BANKSEL T2CON
    movlw   1001110B     ;1001 para el postcaler, 1 timer 2 on, 10 precaler 16
    movwf   T2CON
    ;**************************************************************************
    
    ;****************Confiuracion default**************************************
    ; Se define la variable inicial del contador de seleccion
    movlw   10
    movwf   sem		; La variable que utiliza el display de estado
    movwf   tiempo01	; Tiempo inicial timer 1
    movwf   tiempo02	; Tiempo inicial timer 2
    movwf   tiempo03	; Tiempo inicial timer 3
    movlw   6
    movwf   fix		; Se usa para corrgir desfase de tiempos
    
    clrf    reinicio
    
    ;**************************************************************************
    
    ; Limpiar los puertos
    BANKSEL PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
  
;******************************************************************************
; Loop Principal
;******************************************************************************
    loop:
    
    btfsc   dispsele, 0	; Se revisa la bandra, y rependiendo de cual
    call    division1	; esta activada se pone una rutina de division
    btfsc   dispsele, 1 ; Asi se logra poder guardar el valor en una variable
    call    division2 
    btfsc   dispsele, 2
    call    division3 
    btfsc   dispsele, 3
    call    aceptar	; Rutina de aceptar
    
    call    semaforos	; Se llama a las leds de los semaforos
    
    btfsc   reinicio, 0	; Se utiliza para apagar un instante los displays
    goto    $+5
    call    timers	; Configuracion de tiempos
    call    division01	; Respectivas divisiones
    call    division02
    call    division03
    
    goto    loop
;******************************************************************************
; Sub-Rutinas 
;******************************************************************************
    
//<editor-fold defaultstate="collapsed" desc="Reset Timer0">
reset0:
    ;BANKSEL PORTA
    movlw   255	    ; Tiempo de intruccion
    movwf   TMR0
    bcf	    T0IF    ; Volver 0 al bit del overflow
    return//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Configuracion Clock">
clock:		    ; Se configura el oscilador interno
    BANKSEL OSCCON
    bcf	    IRCF2   ; Se selecciona 010
    bsf	    IRCF1   
    bcf	    IRCF0   ; Frecuencia de 250 KHz
    bsf	    SCS	    ; Activar oscilador interno
    return//</editor-fold>
  
//<editor-fold defaultstate="collapsed" desc="Division01 Selector">
division1:   ; Se crea la subrutina de la separacion de valores
    clrf	selector
    clrf	residuo
    bcf		STATUS, 0
    movf	sem, 0	    ; Se mueve lo que hay en el contador a w
    movwf	preptim01
    movwf	selector	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	selector, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	selector
    movf	residuo, w
    call	table
    movwf	control01
    movf	selector, w
    call	table
    movwf	control02    
    return//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Division02 Selector">
division2:   ; Se crea la subrutina de la separacion de valores
    clrf	selector
    clrf	residuo
    bcf		STATUS, 0
    movf	sem, 0	    ; Se mueve lo que hay en el contador a w
    movwf	preptim02
    movwf	selector	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	selector, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	selector
    movf	residuo, w
    call	table
    movwf	control01
    movf	selector, w
    call	table
    movwf	control02    
    return//</editor-fold>
 
//<editor-fold defaultstate="collapsed" desc="Division03 Selector">
division3:   ; Se crea la subrutina de la separacion de valores
    clrf	selector
    clrf	residuo
    bcf		STATUS, 0
    movf	sem, 0	    ; Se mueve lo que hay en el contador a w
    movwf	preptim03
    movwf	selector	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	selector, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	selector
    movf	residuo, w
    call	table
    movwf	control01
    movf	selector, w
    call	table
    movwf	control02    
    return//</editor-fold>    
      
//<editor-fold defaultstate="collapsed" desc="Division Display timer 1">
division01:   ; Se crea la subrutina de la separacion de valores
    clrf	selector
    clrf	residuo
    bcf		STATUS, 0
    movf	timer1, w	    ; Se mueve lo que hay en el contador a w
    movwf	selector	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	selector, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	selector
    movf	residuo, w
    call	table
    movwf	control03
    movf	selector, w
    call	table
    movwf	control04    
    return//</editor-fold>
   
//<editor-fold defaultstate="collapsed" desc="Division Display timer 2">
division02:   ; Se crea la subrutina de la separacion de valores
    clrf	selector
    clrf	residuo
    bcf		STATUS, 0
    movf	timer2, w	    ; Se mueve lo que hay en el contador a w
    movwf	selector	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	selector, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	selector
    movf	residuo, w
    call	table
    movwf	control05
    movf	selector, w
    call	table
    movwf	control06    
    return//</editor-fold>
 
//<editor-fold defaultstate="collapsed" desc="Division Display timer 3">
division03:   ; Se crea la subrutina de la separacion de valores
    clrf	selector
    clrf	residuo
    bcf		STATUS, 0
    movf	timer3, w	    ; Se mueve lo que hay en el contador a w
    movwf	selector	    ; Se mueve w a la variable residuos		    ; Empieza la parte de las decenas
    movlw	10		    ; Se mueve 10 a w
    incf	residuo
    subwf	selector, f	    ; Se le resta a residuos 10
    btfsc	STATUS, 0	    ; Se verifica la bandera
    goto	$-3
    decf	residuo		    ; Se incrementa la variable decenas
    addwf	selector
    movf	residuo, w
    call	table
    movwf	control07
    movf	selector, w
    call	table
    movwf	control08    
    return//</editor-fold>
 
//<editor-fold defaultstate="collapsed" desc="Aceptar en el display">
aceptar:
    
    movlw	10
    call	table	    ; Se muestra AC en el display para saber 
    movwf	control01   ; en que modo se encuentran
    movlw	12
    call	table
    movwf	control02
    
    btfss	PORTB, 0    ; Se revisa si se apacha el boton de aceptar
    call	confirmar0  ; Se llama a la rutina de confirmar
    btfss	PORTB, 1    ; Se revisa si se apacha el boton de cancelar
    call	back	    ; Se limpia la rutina de estados
    return//</editor-fold>
 
//<editor-fold defaultstate="collapsed" desc="Seleccion de estado">
selstage:
    incf    stage	; Se incrementa una variable para verificar el estado
		
    btfsc   flagst, 0	; flagst es una variable 
    goto    option01
    
    btfsc   flagst, 1
    goto    option02
    
    btfsc   flagst, 2
    goto    option03
    
    btfsc   flagst, 3
    goto    back
  
    ; Como flagst esta en 0, entra en option0 hasta que se apacha el boton
option0:    ; Modo0
    bcf	    PORTB, 5	    ; Se apagan todas las leds
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    bcf	    STATUS, 2	    ; Se limpia la bandera del status
    movlw   1	    
    movwf   countsel	    ; Se revisa si la variable es 1
    movf    stage, w	    
    subwf   countsel, w
    btfss   STATUS, 2	    ; Cuando sea uno, se activa el status
    goto    $+4
    bsf	    PORTB, 5	    ; Se activa la led para el siguiente estado
    bsf	    flagst, 0	    ; Se activa la bandera de estado
    bsf	    dispsele, 0	    ; Se activa la bandera de seleccion de division
    return
option01:   ; Modo1
    bcf	    STATUS, 2
    movlw   2
    movwf   countsel	    ; Se verifica que la variable sea 2
    movf    stage, w
    subwf   countsel, w
    btfss   STATUS, 2	    ; Cuando es 2 se activa el status
    goto    $+7
    bcf	    PORTB, 5
    bsf	    PORTB, 6	    ; Se apaga la led anterior y se prende la siguiente
    bcf	    flagst, 0
    bsf	    flagst, 1	    ; Cambio de bnderas
    bcf	    dispsele, 0
    bsf	    dispsele, 1
    return
option02:   ; Modo2
    bcf	    STATUS, 2
    movlw   3
    movwf   countsel
    movf    stage, w
    subwf   countsel, w
    btfss   STATUS, 2
    goto    $+7
    bsf	    PORTB, 5
    bsf	    PORTB, 6
    bcf	    flagst, 1
    bsf	    flagst, 2
    bcf	    dispsele, 1
    bsf	    dispsele, 2
    return
option03:   ; Modo3
    bcf	    STATUS, 2
    movlw   4
    movwf   countsel
    movf    stage, w
    subwf   countsel, w
    btfss   STATUS, 2
    goto    $+6
    bcf	    PORTB, 5
    bcf	    PORTB, 6
    bsf	    PORTB, 7
    bcf	    flagst, 2
    bsf	    flagst, 3
    bcf	    dispsele, 2
    bsf	    dispsele, 3
    return
back:	    ; Modo de reincio
    clrf    control01	    ; Se limpian las variables del display para 
    clrf    control02	    ; que estos esten apgados en el modo0
    bcf	    PORTB, 7	    ; Se apaga la ultima led
    clrf    flagst	    ; Se limpian las banderas
    clrf    stage	    ; Se limpia la variable de estado
    clrf    dispsele
    return//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Incremento Seleccion">
up:
    incf    sem		; Se incrementa una variable
    bcf     STATUS, 2	; Se limpia status
    movlw   21		
    subwf   sem, w	; Se verifica que no sea mayor a 21
    btfss   STATUS, 2
    goto    $+3
    movlw   10		; Si es mayor a 20, se le pone automaticamente 10
    movwf   sem 
    return//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Decremento Seleccion">
down:
    decf    sem		; Variable a decrementar
    bcf	    STATUS, 2
    movlw   9
    subwf   sem, w	; Se verifica que no sea menor a 10
    btfss   STATUS, 2
    goto    $+3
    movlw   20		; Si llega a ser menor de 10, se le pone 20
    movwf   sem
    return  //</editor-fold>
      
//<editor-fold defaultstate="collapsed" desc="Configuracion de los tiempos">
timers:
    
    btfsc   flagsem, 0	; flagsem es una variable 
    goto    sem02
    
    btfsc   flagsem, 1
    goto    sem03
    
    btfsc   flagsem, 2
    goto    clear
    
sem01:	    ; Timer1
    bcf	    STATUS, 2	    ; Se limpia el status
    movf    tiempo01, w	    ; Se mueve el tiempo a w
    movwf   timer1	    ; W se mueve a la variable que se muestra
    movf    count01, w	    ; Se mueve el contador a w
    subwf   timer1, 1	    ; Se le va restando a la variable del tiempo
    btfss   STATUS, 2	    ; Se espera hasta que sea 0
    goto    $+4		    ; Suce una vez status no se prenda
    bsf	    flagsem, 0	    ; Prende bandera de sem02
    movlw   0
    movwf   count01	    ; Se reinicia el contador del timer1
    return
sem02:	    ; Timer2
    bcf	    STATUS, 2
    movf    tiempo02, w
    movwf   timer2
    movf    count01, w
    subwf   timer2, 1
    btfss   STATUS, 2
    goto    $+5
    bcf	    flagsem, 0
    bsf	    flagsem, 1
    movlw   0
    movwf   count01
    return
sem03:	    ; Timer3
    bcf	    STATUS, 2
    movf    tiempo03, w
    movwf   timer3
    movf    count01, w
    subwf   timer3, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    flagsem, 1
    bsf	    flagsem, 2
    return
clear:	    ; Reinicio de timers
    clrf    count01	; Se limpia el contador del timer1
    clrf    flagsem	; Se limpian las banderas
    bcf	    TMR1IF	; Se limpia el overflow del timer1
    return//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Configuracion Semaforos">
semaforos:
	; Se crea un modo para cada luz del semaforo
    btfsc   colorflag, 0
    goto    sema02
    
    btfsc   colorflag, 1
    goto    sema03
    
    btfsc   colorflag, 2
    goto    sema04 

    btfsc   colorflag, 3
    goto    sema05
    
    btfsc   colorflag, 4
    goto    sema06
    
    btfsc   colorflag, 5
    goto    sema07 
    
    btfsc   colorflag, 6
    goto    sema08 
    
    btfsc   colorflag, 7
    goto    sema09 
    
    btfsc   flagreset, 0
    goto    reseteo
    
sema01:	    ; Verde full
    bcf	    STATUS, 2
    bcf	    PORTA, 0	; Rojo s1
    bcf	    PORTA, 1	; Amarillo s1
    bsf	    PORTA, 2	; Verde s1
    bsf	    PORTA, 3	; Rojo s2
    bcf	    PORTA, 4	; Amarillo s2
    bcf	    PORTA, 5	; Verde s2
    bsf	    PORTA, 6	; Rojo s3
    bcf	    PORTA, 7	; Amarillo s3
    bcf	    PORTB, 4	; Verde s3
    
    movf    contador1, w	    ; Muevo tiempo a w
    movwf   verdec	    ; muevo w a la variable del verde full
    movlw   6		    
    subwf   verdec, 1	    ; Le resto al verde full los 6 fijos
    movf    verdec, w	    ; muevo lo restante de la resta a otra variable
    movwf   resta	    
    movf    count01, w	    ; Con el timer uno voy decrementndo verdec
    subwf   verdec, 1
    btfss   STATUS, 2	    ; Cuando da 0, se activa la bandera status
    goto    $+3		    ; Con ese salto logro pasarme al siguiente color
    bcf	    PORTA, 2
    bsf	    colorflag, 0
    return
sema02:	    ; Verde titilante  
    bcf	    STATUS, 2
    bsf	    PORTA, 2
    delay_small
    bcf	    PORTA, 2
    movlw   3
    addwf   resta, w
    movwf   verdet
    movf    count01, w
    subwf   verdet, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    colorflag, 0
    bsf	    colorflag, 1
    return
sema03:	    ; Amarillo
    bcf	    STATUS, 2
    bsf	    PORTA, 1
    movlw   6
    addwf   resta, w
    movwf   amarillo
    movf    count01, w
    subwf   amarillo, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    colorflag, 1
    bsf	    colorflag, 2
    bcf	    PORTA, 1
    return
sema04:	    ; Verde 
    bcf	    STATUS, 2
    bcf	    PORTA, 3
    bsf	    PORTA, 0
    bsf	    PORTA, 5
    movf    tiempo02, w
    movwf   verdec 
    movlw   6
    subwf   verdec, 1
    movf    verdec, w
    movwf   resta
    movf    count01, w
    subwf   verdec, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    PORTA, 5
    bcf	    colorflag, 2
    bsf	    colorflag, 3    
    return
sema05:	    ; Verde titilantes
    bcf	    STATUS, 2
    bsf	    PORTA, 5
    delay_small
    bcf	    PORTA, 5
    movlw   3
    addwf   resta, w
    movwf   verdet
    movf    count01, w
    subwf   verdet, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    colorflag, 3
    bsf	    colorflag, 4
    return
sema06:	    ; Amarillo
    bcf	    STATUS, 2
    bsf	    PORTA, 4
    movlw   6
    addwf   resta, w
    movwf   amarillo
    movf    count01, w
    subwf   amarillo, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    colorflag, 4
    bsf	    colorflag, 5
    bcf	    PORTA, 4
    return  
sema07:	    ; Verde full
    bcf	    STATUS, 2
    bcf	    PORTA, 6
    bsf	    PORTA, 3
    bsf	    PORTB, 4
    movf    tiempo02, w
    movwf   verdec 
    movf    fix, w
    subwf   verdec, 1
    movf    verdec, w
    movwf   resta
    movf    count01, w
    subwf   verdec, 1
    btfss   STATUS, 2
    goto    $+4
    bcf	    PORTB, 4
    bcf	    colorflag, 5
    bsf	    colorflag, 6    
    return    
sema08:	    ; verde titilante
    bcf	    STATUS, 2
    bsf	    PORTB, 4
    delay_small
    bcf	    PORTB, 4
    movlw   3
    addwf   resta, w
    movwf   verdet
    movf    count01, w
    subwf   verdet, 1
    btfss   STATUS, 2
    goto    $+3
    bcf	    colorflag, 6
    bsf	    colorflag, 7
    return   
sema09:	    ; Amarillo
    bcf	    STATUS, 2
    bsf	    PORTA, 7
    movlw   6
    addwf   resta, w
    movwf   amarillo
    movf    count01, w
    subwf   amarillo, 1
    btfss   STATUS, 2
    goto    $+5
    bcf	    colorflag, 7
    bsf	    flagreset, 0
    bcf	    PORTA, 7
    bsf	    PORTA, 6
    return
reseteo:    ; Reseteo de los semaforos
    clrf    verdec
    clrf    verdet
    clrf    amarillo
    clrf    resta
    clrf    colorflag
    bcf     flagreset, 0
    clrf    STATUS
    return//</editor-fold>
    
//<editor-fold defaultstate="collapsed" desc="Delay para titileo">
delay_small:
    movlw 248		 ; Valor inicial del contador
    movwf cont_small	
    decfsz cont_small, 1 ; Decrmentar el contador
    goto $-1		 ; Ejecutar linea anterior
    return//</editor-fold>

//<editor-fold defaultstate="collapsed" desc="Reseteo completo">
supeR:	    ; Limpio las banderas para que se reinicie todo
    call    back
    clrf    flagsem
    clrf    colorflag
    clrf    flagst
    clrf    count01
    clrf    dispsele
    clrf    timer1
    clrf    timer2
    clrf    timer3
    return //</editor-fold>
  
//<editor-fold defaultstate="collapsed" desc="Cargar valores en los displays">
confirmar0:
    movlw   5
    movwf   fix		; Arreglo para el semaforo
    bsf	    reinicio, 0	; Se utiliza esto para que los displas se detengan
    call    supeR	; Se llama al reseteo completo
    movf    preptim01, w    ; Se mueven las variables a los timers
    movwf   tiempo01
    movf    preptim02, w
    movwf   tiempo02
    movf    preptim03, w
    movwf   tiempo03
    delay_small
    bcf	    reinicio, 0
    return//</editor-fold>

END