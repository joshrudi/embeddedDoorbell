;
; button_buzzer_led_project.asm
;
; Created: 3/18/2018
; Author : Josh
;


; This software was made by me just to play around with the arduino on a low level, this is how it works (in a nutshell):
; 1) Someone press the external button
; 2) This triggers an interrupt
; 3) The interrupt handles turning on the led and enables the buzzer
; 4) If the button is released, the buzzer stops and the led turns off

.equ EIMSK_reg = 0x3D
.equ EICRA_reg = 0x69
.equ TCCR0A_reg = 0x44
.equ TCCR0B_reg = 0x45
.equ TIMSK0_reg = 0x6E
.equ TIMSK1_reg = 0x6F
.equ TCCR1A_reg = 0x80
.equ TCCR1B_reg = 0x81
.equ OCR1AL_reg = 0x88
.equ OCR1AH_reg = 0x89

.ORG 0x0000
	rjmp main

.ORG 0x0002	;external int 0
	rjmp buttonPress

.ORG 0x0016 ;tcc1 cca (turn on buzzer)
	rjmp tcc1_cca

.ORG 0x0020	;tcc0 overflow int
	rjmp tcc0_overflow

.ORG 0x001A ;tcc1 ovf int (turn off buzzer)
	rjmp tcc1_ovf

.ORG 0x0200 ;set main past interrupt vectors
main:

	; ****SETUP STACK****
    ldi R16, LOW(RAMEND)
    out SPL, R16
    ldi R16, HIGH(RAMEND)
    out SPH, R16

	; ****SETUP INT REGISTERS****
	; external int
	ldi R16, 0x00
	sts EICRA_reg, R16	;set external pin 0 interrupt on low
	ldi R16, 0x01
	sts EIMSK_reg, R16	;enable int0 for ext interrupt
	; TCC0
	ldi R16, 0x00
	sts TCCR0A_reg, R16	;set tcc0 to normal mode
	ldi R16, 0x01
	sts TCCR0B_reg, R16	; set prescaler
	; TCC1
	ldi R16, 0x00
	sts TCCR1A_reg, R16 ;normal mode
	ldi R16, 0x01
	sts TCCR1B_reg, R16 ;prescaler
	ldi R16, 0x00
	sts OCR1AH_reg, R16 ;high byte output compare (write high first, then low)
	ldi R16, 0xFE
	sts OCR1AL_reg, R16 ;low byte for output compare

	; ****SETUP I/O****
    ldi R16, 0b11110011	;set R16
	out DDRD, R16	;set pins D2/D3 as input and rest output
	out PORTD, R16
	cbi PORTD, 7

	sei	;enable global int flag

loop:
	rjmp loop	; interrupt driven

buttonPress:
	push R16

	ldi R16, 0x00
	sts EIMSK_reg, R16	;disable ext int0 so we don't cause overlapping interrupts

	sbi PORTD, 7	;turn on LED, port D pin 7

	ldi R16, 0x01
	sts TIMSK0_reg, R16	; enable timer counter 0
	ldi R16, 0x03
	sts TIMSK1_reg, R16	; enable buzzer timer cca/ovf int

	pop R16
	reti

tcc0_overflow:
	push R16

	ldi R16, 0x00
	sts TIMSK0_reg, R16	;take care of the tcc0 disable
	sts TIMSK1_reg, R16	;take care of the tcc1 disable

	cbi PORTD, 7	;turn off LED, port D pin 7
	cbi PORTD, 6	;turn off buzzer, port D pin 6

	ldi R16, 0x01
	sts EIMSK_reg, R16	;re-enable ext int0

	pop R16
	reti

tcc1_ovf:
	cbi PORTD, 6	;turn off buzzer, port D pin 6
	reti

tcc1_cca:
	sbi PORTD, 6	;turn on buzzer, port D pin 6
	reti