/*
 * File:   main08.c
 * Author: Diego Estrada
 *
 * Created on 20 de abril de 2021, 10:58 AM
 */

//-------------------------- Bits de configuraciÓn -----------------------------
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT        // Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF                   // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = ON                   // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = OFF                  // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF                     // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF                    // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF                  // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF                   // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF                  // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF                    // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V               // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF                    // Flash Program Memory Self Write Enable bits (Write protection off)

#define _XTAL_FREQ 4000000
#include <stdint.h>
#include <xc.h>

//------------------------------ Variables ------------------------------------- 
// Matriz para la traducción de displays
char    tabla7seg[10] = {0b00111111, 0b00000110, 0b01011011, 0b01001111, 
        0b01100110,0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111};

// Variable para el multiplexado de los displays
int     multiplex;   

// Variables para la división
char    centena;  
char    decena;
char    unidad;
char    residuo;
char    num;

//----------------------------- Prototipos ------------------------------------- 
void setup(void);                           // Defino las funciones antes de crearlas
char division(void);

//--------------------------- Interrupciones -----------------------------------
void __interrupt() isr(void){ //interrupciones
    if(T0IF == 1){                           // Se verifica la bandera del timer0
        PORTEbits.RE2 = 0;                  // Apago el transistor 2
        PORTEbits.RE0 = 1;                  // Prendo transistor 0
        PORTD = (tabla7seg[centena]);       // Ingreso del valor para las centenas
        multiplex = 0b00000001;             // Prendo una flag
        
        if (multiplex == 0b00000001){        // Se verifica que bandera esta encendida
            PORTEbits.RE0 = 0;              
            PORTEbits.RE1 = 1;
            PORTD = (tabla7seg[decena]);    // Ingreso del valor para las decenas
            multiplex = 0b00000010;         // Se cambia el valor de la bandera
        }
        if (multiplex == 0b00000010){        
            PORTEbits.RE1 = 0;              
            PORTEbits.RE2 = 1;
            PORTD = (tabla7seg[unidad]);    // Ingreso del valor para las unidades 
            multiplex = 0b00000000;         // Se apaga la bandera
        }
        INTCONbits.T0IF = 0;                // Se limpia la interrupcion del timer0
        TMR0 = 255;                         // Configuración del valor de reinicio del timer0
    }
    if(PIR1bits.ADIF == 1)
       {
           if(ADCON0bits.CHS == 0)
               PORTC = ADRESH;
           
           else
               num = ADRESH;
           
           PIR1bits.ADIF = 0;           
       }
}
void main(void) 
{

    setup();    // Llamo a mi configuracion
    ADCON0bits.GO = 1;     // Bita para que comience la conversion
    
    while(1)    // Equivale al loop
    {
        if(ADCON0bits.GO == 0){
            if(ADCON0bits.CHS == 1)
                ADCON0bits.CHS = 0;
            else
                ADCON0bits.CHS = 1;
            
            __delay_us(100);
            ADCON0bits.GO = 1;
        }
       division(); 
    }
}

//----------------------------- SUB-RUTINAS ------------------------------------
// Sub-rutina de configuraciones generales
void setup(void){
    // Configuraciones de puertos digitales
    ANSEL = 0b00000011;
    ANSELH = 0b11111111;
    
    // Configurar bits de salida o entradaas
    TRISAbits.TRISA0 = 1;
    TRISAbits.TRISA1 = 1;
    TRISBbits.TRISB0 = 0;
    TRISBbits.TRISB1 = 0;
    TRISBbits.TRISB2 = 0;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x00;
    
    // Se limpian los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0X00;
    
    // Se configura el oscilador
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;   // Se configura a 250kHz
    OSCCONbits.SCS = 1;
    
    // Timer0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    
    // Configuacion de las interrupciones
    INTCONbits.GIE = 1;
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    INTCONbits.PEIE = 1;    // Periferical interrupt
    PIE1bits.ADIE = 1;      // Activar la interrupcion del ADC
    PIR1bits.ADIF = 0;      // Bandera del ADC
    
    // Configuracion del ADC
    ADCON0bits.ADCS0 = 1;
    ADCON0bits.ADCS1 = 1; // Se configura el oscilador interno
    ADCON0bits.ADON = 1;        // Activar el ADC
    
    ADCON0bits.CHS = 0;         // Canal 0
    
    ADCON1bits.ADFM = 0;        // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.VCFG1 = 0;
}

// Sub-rutina para la división
char division(void) {
    centena = num/100;                    // Divide el valor de PORTA
    residuo = num%100;
    decena = residuo/10;                    // El residuo se devide entre 10
    unidad = residuo%10;                    // Se mueve ese residuo a unidades
}
