/*
 * File:   main09.c
 * Author: diego
 *
 * Created on 27 de abril de 2021, 10:39 AM
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

//----------------------------- Prototipos ------------------------------------- 
void setup(void);                           // Defino las funciones antes de crearlas


//--------------------------- Interrupciones -----------------------------------
void __interrupt() isr(void){ //interrupciones
    
    if(PIR1bits.ADIF == 1)
       {
        if(ADCON0bits.CHS == 0){
            CCPR1L = (ADRESH >> 1) + 124;
        }    
        else if(ADCON0bits.CHS == 1){ 
            CCPR2L = (ADRESH >> 1) + 124;
        }
        PIR1bits.ADIF = 0;         
       }
}
void main(void) 
{

    setup();                                // Llamo a mi configuracion principal
    ADCON0bits.GO = 1;                      // Bit para que comience la conversion
    
    while(1)  
    {
        if (ADCON0bits.GO == 0)
        {
            if(ADCON0bits.CHS == 1){
                ADCON0bits.CHS = 0;
            }
            else{
                ADCON0bits.CHS = 1;}
            __delay_us(50);
            ADCON0bits.GO = 1;
        }
    }
}

//----------------------------- SUB-RUTINAS ------------------------------------
// Sub-rutina de configuraciones generales
void setup(void){
    // Se configura el oscilador
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;                   // Se configura a 8MHz
    OSCCONbits.SCS = 1;
    
    // Configuraciones de puertos digitales
    ANSEL = 0b00000011;
    ANSELH = 0;
    
    // Configurar bits de salida o entradaas
    TRISAbits.TRISA0 = 1;
    TRISAbits.TRISA1 = 1;
    TRISC = 0x00;
    
    // Se limpian los puertos
    PORTA = 0x00;
    PORTC = 0x00;
    
    // Configuracion del ADC    
    ADCON1bits.ADFM = 0;                    // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;                   // Vref en VSS y VDD 
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS = 0b10;                 // Se configura el oscilador interno FOSC/32
    ADCON0bits.ADON = 1;                    // Activar el ADC
    ADCON0bits.CHS = 0;                     // Canal 0
    __delay_us(50);
    
    // Configuración PWM
    TRISCbits.TRISC2 = 1;                   // RC2/CCP1 como input
    TRISCbits.TRISC1 = 1; 
    PR2 = 250;                              // Periodo
    CCP1CONbits.P1M = 0;                    // Modo PWM
    CCP1CONbits.CCP1M = 0b1100;
    CCPR1L = 0x0f;                          // Ciclo trabajo inicial
    CCP2CONbits.CCP2M = 0b1100;
    CCPR2L = 0x0f;
    
    CCP1CONbits.DC1B = 0;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    // Configuración timer 2
    PIR1bits.TMR2IF = 0;                    // Apagamos la bandera
    T2CONbits.T2CKPS = 0b11;                // Prescaler 1:16
    T2CONbits.TMR2ON = 1;
    
    while(PIR1bits.TMR2IF == 0);            // Esperamos 1 ciclo del TMR2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;                   // Salida del PWM para el servo 1
    TRISCbits.TRISC1 = 0;                   // Salida para el servo 2
    
    // Configuacion de las interrupciones
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;                    // Periferical interrupt
    PIE1bits.ADIE = 1;                      // Activar la interrupcion del ADC
    PIR1bits.ADIF = 0;                      // Bandera del ADC
    
    return;
}