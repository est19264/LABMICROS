/*
 * File:   main.c Proyecto 2
 * Author: Diego Estrada
 *
 * Created on 18 de mayo de 2021, 02:41 PM
 */


//-------------------------- Bits de configuraciÓn -----------------------------
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT            // Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF                       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF                      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF                      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF                         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF                        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF                      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF                       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = ON                       // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
#pragma config LVP = ON                         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V                   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF                        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#define _XTAL_FREQ 8000000
#include <stdint.h>
#include <xc.h>
#include <stdio.h> 

//------------------------------ Variables ------------------------------------- 
// Variable para las rutinas de bit-banging
char    val;

//----------------------------- Prototipos ------------------------------------- 
//Se definen todas las funciones antes de utilizarlas
void setup(void);                       // Funcion de configuración principal.                     
void bitb1(void);                       // Funciones para el funcionamiento -
void bitb2(void);                       // del bit-banging para la señal del
void bitb3(void);                       // tercer servo.
void putch(char data);                  // Función especial para printf
//void comandos(void);

//--------------------------- Interrupciones -----------------------------------
void __interrupt() isr(void){ 
    
    // Interrupción para el funcionamiento de los servos
    if(PIR1bits.ADIF == 1)
       {
        if(ADCON0bits.CHS == 9){
            CCPR1L = (ADRESH >> 1) + 124;
        }    
        else if(ADCON0bits.CHS == 11){ 
            CCPR2L = (ADRESH >> 1) + 124;
        }
        else if (ADCON0bits.CHS == 13)
        {
               val = ADRESH;
            if (val <= 85){
                bitb1();
                 }
            if ((val <= 170)&&(val >= 86)){
                bitb2();
                 }
            if (val >= 171){
                bitb3();
                 }
        }   
           PIR1bits.ADIF = 0; 
    }
// Interrupción para los pull-ups del puerto B
if (RBIF == 1)  // Verificar bandera de la interrupcion del puerto b
    {
        if (PORTBbits.RB0 == 0)             // Si oprimo el boton 1
        {
            PORTDbits.RD0 = 1;    
        }
        else if (PORTBbits.RB0 == 1)
        {
            PORTDbits.RD0 = 0;
        }
        if  (PORTBbits.RB1 == 0)            // Se oprimo el boton 2
        {
            PORTEbits.RE0 = 1;     
            PORTEbits.RE1 = 1;
        }
        else if (PORTBbits.RB1 == 1)
        {
            PORTEbits.RE0 = 0;
            PORTEbits.RE1 = 0;
        }
        INTCONbits.RBIF = 0;                // Se limpia la bandera de la interrupcion
    }
    
    // Interrupción para la implementción de UART
    if (RCIF == 1){
    // Configuración para las opciones 
    if (RCREG == '8'){                      // Primera opción, avanzar el carro
        __delay_ms(500);
        printf("\r El carro esta avanzando... \r");
        PORTDbits.RD0 = 1;                  // El motor dc va en empieza a avanzar
        __delay_ms(2000);
        PORTDbits.RD0 = 0;                  // El motor dc se detiene
        printf(" El carro se ha detenido. \r");
    }
    if (RCREG == '5'){                      // Segunda opción, encender las luces
        printf("\r Luces encendidas... \r");
        PORTEbits.RE0 = 1;
        PORTEbits.RE1 = 1;
        __delay_ms(2000);
        PORTEbits.RE0 = 0;
        PORTEbits.RE1 = 0;
        printf(" Luces apagadas. \r");
    }
    if (RCREG == '4'){                      // Tercera opción, giro a la izquierda
        bitb1();
        printf("\r El carro esta girando a la izquierda... \r");
        __delay_ms(1000);
        printf(" El carro ha dejado de girar. \r");
    }
    
    if (RCREG == '6'){                      // Tercera opción, giro a la izquierda
        bitb3();            
        printf("\r El carro esta girando a la derecha... \r");
        __delay_ms(1000);
        printf(" El carro ha dejado de girar. \r");
    }
        
    else{                                   // Ignorar por si se ingresa una opción no válida
        NULL;                 
    }
    return;
}
}

// ---------------------------------- MAIN -------------------------------------
void main(void) 
{
    setup();                                    // Llamo a mi configuracion principal
    ADCON0bits.GO = 1;                          // Bit para que comience la conversion
    __delay_ms(250);                            //Tiempos para el despliegue de los caracteres
    printf("\r INSTRUCCIONES PARA LOS COMANDOS DEL CARRO: \r");
    __delay_ms(250);
    printf("\r 8 - Para avanzar el carro. \r"); // Opción 1
    __delay_ms(250);
    printf(" 2 - Para encender las luces. \r"); // Opción 2
    __delay_ms(250);
    printf(" 4 - Para girar hacia la izquierda el carro. \r");  // Opción 3
    __delay_ms(250);
    printf(" 6 - Para girar hacia la derecha el carro. \r");    // Opción 4
    
    // Loop principal
    while(1)  
    {
        if (ADCON0bits.GO == 0)
        {
            if(ADCON0bits.CHS == 9){            // Rutina para el camio de canales analógicos
                ADCON0bits.CHS =11;
            }
            else if (ADCON0bits.CHS == 11)      // Cambio del 9 al 11 y luego al 13
            {
                ADCON0bits.CHS = 13;
            }
            else
                ADCON0bits.CHS = 9;
            __delay_us(50);
            ADCON0bits.GO = 1;
        }   
    }
}

//----------------------------- SUB-RUTINAS ------------------------------------
void putch(char data){        
    while(TXIF == 0);
    TXREG = data;                           // Valor de la cadena de printf
    return;
}

void setup(void){
    // Se configura el oscilador
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;                   // Se configura a 8MHz
    OSCCONbits.SCS = 1;
    
    // Configuraciones de puertos digitales
    ANSEL = 0;
    ANSELH = 0b00101010;                    // Pines analógicos de PORTB
    
    // Configurar bits de salida o entradaas
    // Inputs para los push buttons en el puerto B con PULL-UP
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
    // Inputs para los poteniómetros en el puerto B
    TRISBbits.TRISB3 = 1;
    TRISBbits.TRISB4 = 1;
    TRISBbits.TRISB5 = 1;

    
    // Outputs para los servos en el puerto C
    TRISCbits.TRISC0 = 0;
    TRISCbits.TRISC1 = 0;
    TRISCbits.TRISC2 = 0;
    
    // Outputs para el DC en el puerto D
    TRISDbits.TRISD0 = 0;
    TRISDbits.TRISD1 = 0;
    
    // Outputs para las leds en puerto E
    TRISEbits.TRISE0 = 0;
    TRISEbits.TRISE1 = 0;
    
    // Se limpian los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    
    // Configuracion de pull-up interno en PORTB
    OPTION_REGbits.nRBPU = 0;
    WPUB = 0b00000011;
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    
    // Configuracion del ADC    
    ADCON1bits.ADFM = 0;                    // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;                   // Vref en VSS y VDD 
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS = 0b10;                 // Se configura el oscilador interno FOSC/32
    ADCON0bits.ADON = 1;                    // Activar el ADC
    ADCON0bits.CHS = 9;                     // Canal 9
    __delay_us(50);
    
    // Configuración PWM
    TRISCbits.TRISC2 = 1;                   // RC2/CCP1 como input
    TRISCbits.TRISC1 = 1; 
    PR2 = 249;                              // Periodo
    CCP1CONbits.P1M = 0;                    // Modo PWM
    CCP1CONbits.CCP1M = 0b1100;
    CCPR1L = 0x0f;                          // Ciclo trabajo inicial
    CCP2CONbits.CCP2M = 0b1100;
    CCPR2L = 0x0f;
    
    CCP1CONbits.DC1B = 0;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    // Configuración timer 2
    PIR1bits.TMR2IF = 0;                    // Apaga la bandera
    T2CONbits.T2CKPS = 0b11;                // Prescaler 1:16
    T2CONbits.TMR2ON = 1;
    
    while(PIR1bits.TMR2IF == 0);            // Espera 1 ciclo del TMR2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;                   // Salida del PWM para el servo 1
    TRISCbits.TRISC1 = 0;                   // Salida para el servo 2
    
    // Configuacion de las interrupciones
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;                    // Periferical interrupt
    PIE1bits.ADIE = 1;                      // Activar la interrupcion del ADC
    PIR1bits.ADIF = 0;                      // Bandera del ADC
    INTCONbits.RBIF = 1;                    // Bandera de interrupción de PORTB
    INTCONbits.RBIE = 1;                    // Activa la interrupción de PORTB
    
    // Configuraciones TX y RX
    TXSTAbits.SYNC = 0;                     // Apaga SYNC
    TXSTAbits.BRGH = 1;                     // Prende BRGH
    BAUDCTLbits.BRG16 = 1;                  // Prende BRG16
    
    SPBRG = 208;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;                     // Prende SPEN
    RCSTAbits.RX9 = 0;                      // Apaga RX9
    RCSTAbits.CREN = 1;                     // Prende CREN
    
    TXSTAbits.TXEN = 1;                     // Prende TXTEN
    
    PIR1bits.RCIF = 0;                      // Bandera rx
    PIR1bits.TXIF = 0;                      // bandera tx

}
    
    void bitb1 (void)
    {
        PORTCbits.RC0 = 1;                  // Prende el bit
        __delay_ms(1);                      // Espera un tiempo
        PORTCbits.RC0 = 0;                  // Apaga el bit
        __delay_ms(19);                     // Espera un tiempo
    }
    
    void bitb2 (void)
    {
        PORTCbits.RC0 = 1;                  // Prende el bit
        __delay_ms(1.5);                    // Espera un tiempo
        PORTCbits.RC0 = 0;                  // Apaga el bit
        __delay_ms(18.5);                   // Espera un tiempo
    }

    void bitb3 (void)
    {
        PORTCbits.RC0 = 1;                  // Prende el bit
        __delay_ms(2);                      // Espera un tiempo
        PORTCbits.RC0 = 0;                  // Apaga el bit
        __delay_ms(18);                     // Espera un tiempo
    }
