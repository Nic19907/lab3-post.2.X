; Archivo: lab3-datch.2
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: Contador que inc c 100ms, contador que inc cada 1s limitado por
; el display de 7 segmentos y un display de 7 segmentos con tablas
    
; Hardware: led de 7 segmentos conectado al puerto C, LEDS en los puertos A Y B
; para los contadores y push buttons al D,0 y 1
;    
; Creado 11/08/2021
; Modificado: xx/08/2021   
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>

;-------------------------------------------------------------------------------
; Palabras de configuracion
;-------------------------------------------------------------------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

PSECT resVect, class=CODE, abs, delta=2
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
time_1:	;para el delay
    DS 2
    
contador:;contador del 7 segmentos
    DS 1

lim_reloj:
    DS 1
    
cont_cycle: ;contador del reloj de 100ms
    DS 1
    
repetir EQU 0x000A
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0000
resVect:
    goto main

;-------------------------------------------------------------------------------
; TABLAS
;-------------------------------------------------------------------------------
ORG 0x0100
tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0 ;PCLATH = 101, PCL=02
    ;andlw   0x0f    ; solo contara los primeros 4 bits
    addwf   PCL	    ; PC = PCLATH + PCL + W
    retlw   00111111B	;0
    retlw   00000110B	;1
    retlw   01011011B	;2
    retlw   01001111B	;3
    retlw   01100110B	;4
    retlw   01101101B	;5
    retlw   01111101B	;6
    retlw   00000111B	;7
    retlw   01111111B	;8
    retlw   01100111B	;9
    retlw   01110111B	;A
    retlw   01111100B	;b
    retlw   00111001B	;C
    retlw   01011110B	;d
    retlw   01111001B	;E
    retlw   01110001B	;F
;-------------------------------------------------------------------------------
; Configuracion
;-------------------------------------------------------------------------------
PSECT loopPrincipal, class=code, delta=2, abs
ORG 0x000A
 
main:
    call config_io
    call config_clock
    call config_tmr0
    banksel PORTA
;*******************************************************************************    
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA   ;banco 1
    clrf    TRISA   ;contador 100ms
    clrf    TRISB   ;contador 1s
    clrf    TRISC   ;7 segmentos
    ;clrf    PORTE   ;LED indicadora de ciclo
    
    bsf	    TRISD,0
    bsf	    TRISD,1 ;entradas de los botones
    
    banksel PORTA   ;banco 0
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTE
return
    
config_clock:
    banksel OSCCON
    bsf	    OSCCON, 6   ;1
    bcf	    OSCCON, 5	;0
    bcf	    OSCCON, 4   ;0	    oscilador a 1MHz
    bsf	    OSCCON, 0	    ;se utiliza el oscilador como el reloj interno
return
    
config_tmr0: //configurar el timer0 a 100ms
    banksel OPTION_REG
    bcf	    OPTION_REG, 5    ;reloj interno
    bcf	    OPTION_REG, 3    ;prescaler asignado al TMR0
    bsf	    OPTION_REG, 2    ;1
    bsf	    OPTION_REG, 1    ;1
    bcf	    OPTION_REG, 0    ;0  110, escala de 1:128
    
    banksel PORTA
    call    restart_tmr0

;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    call    clock_1s
    call    config_contador
    goto    loop
        
;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------
;************************** Reloj de 100ms y 1s ********************************
clock_100ms:
    btfss   T0IF	    ;salta si la bandera del overflow esta activa
    goto    $-1
    call    restart_tmr0    ;reinica el tmr0
    incf    PORTA	    ;incrementar a
    
    btfsc   PORTA, 4	    ;si el bit 4 es 1 reiniciar el contador
    clrf    PORTA	    ;reinicia el contador
    return
    
restart_tmr0:
    movlw   60	    ;preset de 60 
    movwf   TMR0
    bcf	    INTCON, 2 ;limpiar el overflow
    return

clock_1s:
    movlw   repetir;10	;cantidad de veces que se repetira el tmr0
    movwf   cont_cycle	;asignar las repeticiones a la variable
    call    clock_100ms
    decfsz  cont_cycle, 1 ;restarle uno al repetidor
    goto    $-2		   ;volver a hacer el tmr0
    incf    PORTB
    btfsc   PORTB, 4	    ;si el bit 4 es 1 reiniciar el contador
    clrf    PORTB
    ;call    prenderB
return

;prenderB:
;    decfsz  lim_reloj, 1	;decre
 ;   clrf    PORTB
  ;  incf    PORTB
   ; return
  
/*   
copiar_B:
    movf    contador, w	;mover contador a w
    movwf   contador	;mover w a contador
    movwf   lim_reloj	;mover w a lim_reloj, basicamente copiar contador a lim
    return
*/    
;************************** 7 segmentos ****************************************
config_contador:
    btfsc   RD0	    ;Push button en Pull DOWN
    call    inc_contador   
    btfsc   RD1	    ;lo mismo que RD0
    call    dec_contador
    
    movf    contador, W
    call    tabla
    movwf   PORTC
return
    
delay_500us:
    movlw   250	;valor inicial contador 
    movwf   time_1
    decfsz  time_1, 1	;decrementar por 1 el contador 
    goto    $-1		;ejecutar linea anterior
return
    
inc_contador:
    call    delay_500us	    ;esta para evitar un rebote
    btfsc   RD0		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    incf    contador	    ;incrementar el conteo de PORTC
    btfsc   contador, 4	    ;si el bit 4 es 1 reiniciar el contador
    clrf    contador	    ;borrar todo como si fuese un loop al contador
return

dec_contador:
    call    delay_500us
    btfsc   RD1
    goto    $-1
    decf    contador
    btfsc   contador,7 ;si se resta 1 cuando es 0 que se llenen los primeros 4bits
    call    lim_contador   ;asegurarme que solo se utilicen los primeros 4 bits
return
    
lim_contador:
    bcf	    contador, 4
    bcf	    contador, 5
    bcf	    contador, 6
    bcf	    contador, 7 ;hacer que el contador este un su max. de 4bits,, F
    return
/*
           ,::////;::-.
      /:'///// ``::>/|/
    .',  ||||    `/( e\
-==~-'`-Xm````-mm-' `-_\ 
    */
END