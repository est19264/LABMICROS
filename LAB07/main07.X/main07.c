/*
 * File:   main07.c - LABORATORIO 7
 * Author: Diego Estrada 19264
 *
 * Created on 13 de abril de 2021, 10:32 AM
 */

//-------------------------- Bits de configuraciÓn -----------------------------
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT        // Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF                   // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF                  // Power-up Timer Enable bit (PWRT disabled)
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

#include <xc.h>
#include <stdint.h>

//------------------------------ Variables ------------------------------------- 
// Matriz para la traducción de displays
char    tabla7seg[10] = {0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110,
        0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111};

// Variable para el multiplexado de los displays
int     multiplex;      

// Variables para la división
char    centena;  
char    decena;
char    unidad;
char    residuo;

//----------------------------- Prototipos ------------------------------------- 
void setup(void);                           // Defino las funciones antes de crearlas
char division(void);

//--------------------------- Interrupciones -----------------------------------
void __interrupt() isr(void)
{
    if(T0IF == 1)                           // Se verifica la bandera del timer0
    {   
        PORTEbits.RE2 = 0;                  // Apago el transistor 2
        PORTEbits.RE0 = 1;                  // Prendo transistor 0
        PORTD = (tabla7seg[centena]);       // Ingreso del valor para las centenas
        multiplex = 0b00000001;             // Prendo una flag
        
        if (multiplex == 0b00000001)        // Se verifica que bandera esta encendida
        {
            PORTEbits.RE0 = 0;              
            PORTEbits.RE1 = 1;
            PORTD = (tabla7seg[decena]);    // Ingreso del valor para las decenas
            multiplex = 0b00000010;         // Se cambia el valor de la bandera
        }
        if (multiplex == 0b00000010)        
        {
            PORTEbits.RE1 = 0;              
            PORTEbits.RE2 = 1;
            PORTD = (tabla7seg[unidad]);    // Ingreso del valor para las unidades 
            multiplex = 0b00000000;         // Se apaga la bandera
        }
        INTCONbits.T0IF = 0;                // Se limpia la interrupcion del timer0
        TMR0 = 255;                         // Configuración del valor de reinicio del timer0
        
    }
    if (RBIF == 1)  // Verificar bandera de la interrupcion del puerto b
    {
        if (PORTBbits.RB0 == 0)             // Si oprimo el boton 1
        {
            PORTA = PORTA + 1;              
        }
        if  (PORTBbits.RB1 == 0)            // Se oprimo el boton 2
        {
            PORTA = PORTA - 1;              
        }
        INTCONbits.RBIF = 0;                // Se limpia la bandera de la interrupcion
    }
}
//-------------------------------- MAIN ----------------------------------------
void main(void) {
    
    setup();                                // Se llama a la sub-rutina de configuracion general
    
    
    while(1)                                
    {
        
        division();                         // Se llama a la sub-rutina de division
        
    }
}

//----------------------------- SUB-RUTINAS ------------------------------------
// Sub-rutina de configuraciones generales
void setup(void){
// Configuración oscilador interno
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;                   // Se configura a 250kHz
    OSCCONbits.SCS = 1;
    
// Configuración Timer0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;    
    
// Configuración de puertos digitales
    ANSEL = 0x00;
    ANSELH = 0x00;
    
// Configuración inputs y outputs
    TRISA = 0x00;
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0X00;
    
// Se limpian los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00; 
    
// Configuracion de pull-up interno
    OPTION_REGbits.nRBPU = 0;
    WPUB = 0b00000011;
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    
// Configuación interrupciones
    INTCONbits.GIE = 1;
    INTCONbits.RBIF = 1;
    INTCONbits.RBIE = 1;
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;   
}

// Sub-rutina para la división
char division(void) {
    centena = PORTA/100;                    // Divide el valor de PORTA
    residuo = PORTA%100;
    decena = residuo/10;                    // El residuo se devide entre 10
    unidad = residuo%10;                    // Se mueve ese residuo a unidades
}