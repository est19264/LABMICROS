/*
 * File:   Parte2.c
 * Author: diego
 *
 * Created on 6 de mayo de 2021, 05:56 PM
 */


//-------------------------- Bits de configuraciÓn -----------------------------
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#define _XTAL_FREQ 8000000
#include <xc.h>
#include <stdint.h>
#include <stdio.h>              

//----------------------------- Prototipos ------------------------------------- 
void setup(void);               
void putch(char data);          
void texto(void);             

//-------------------------------- Main ----------------------------------------
void main(void) {
    
    setup();                    // Llamo a mi configuracion principal

    
    while(1)                    // Equivale al loop
    {
    texto();                     // Se llama a la subrutina para las cadenas
       
    }
}

//----------------------------- SUB-RUTINAS ------------------------------------
// Función para transmitir el dato
void putch(char data){        
    while(TXIF == 0);
    TXREG = data;               // Valor de la cadena
    return;
}
// Función para definir las cadenas de texto
void texto(void){
    __delay_ms(250);            //Tiempos de despliegue para los caracteres
    printf("\r Elija una opcion: \r");
    __delay_ms(250);
    printf(" 1 - Desplegar cadena de caracteres \r");
    __delay_ms(250);
    printf(" 2 - Desplegar PORTA \r");
    __delay_ms(250);
    printf(" 3 - Desplegar PORTB \r");
    while (RCIF == 0);
    // Configuración para las opciones 
    if (RCREG == '1'){          // Primera opción
        __delay_ms(500);
        printf("\r Cadena de caracteres cargando... \r");
    }
    if (RCREG == '2'){          // Segunda opción
        printf("\r Insertar caracter para desplegar en PORTA: \r");
        while (RCIF == 0);
        PORTA = RCREG;          // Se recibe un caracter
    }
    if (RCREG == '3'){          // Tercera opción 
        printf("\r Insertar caracter para desplegar en PORTB: \r");
        while (RCIF == 0);
        PORTB = RCREG;
    }
    else{                       // Ignorar por si se ingresa una opción que no esté en el menú
        NULL;                 
    }
    return;
}

void setup(void){
    // Configuración del oscilador
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;       // Se configura a 8MHz
    OSCCONbits.SCS = 1;
    
    // Configuraciones de puertos digitales
    ANSEL = 0;
    ANSELH = 0;
    
    // Configuración de inputs y outputs
    TRISA = 0x0;
    TRISB = 0x0;
    
    // Se limpian los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    
    // Configuacion de las interrupciones
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;        // Interrupciones periféricas
    PIE1bits.RCIE = 1;          // Interrupcion rx
    PIE1bits.TXIE = 1;          // Interrupcion TX

    // Configuraciones TX y RX
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 208;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
    
    PIR1bits.RCIF = 0;          // Bandera rx
    PIR1bits.TXIF = 0;          // bandera tx
}