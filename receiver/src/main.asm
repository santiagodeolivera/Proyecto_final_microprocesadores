.ORG 0x0000
	JMP start
.ORG 0x0016
	JMP tmr1_start
.ORG 0x0024
	JMP usartR_start

.INCLUDE "lib.asm"

#define BUFFER_SIZE 2

.DSEG
	data_buffer: .BYTE BUFFER_SIZE

	shield_buffer: .BYTE 4
	shield_digits: .BYTE 16
	digits_buffer: .BYTE 4
.CSEG
start:
	LDI r16, 0b00000010
	OUT DDRD, r16
	OUT PORTD, r16
	LDI r16, 0b00000000
	OUT DDRC, r16
	LDI r16, 0b11111111
	OUT PORTC, r16
	LDI r16, 0b11111111
	OUT DDRB, r16
	OUT PORTB, r16

	SETZ shield_digits
	STZ 0b00000011 ; 0
	STZ 0b10011111 ; 1
	STZ 0b00100101 ; 2
	STZ 0b00001101 ; 3
	STZ 0b10011001 ; 4
	STZ 0b01001001 ; 5
	STZ 0b01000001 ; 6
	STZ 0b00011111 ; 7
	STZ 0b00000001 ; 8
	STZ 0b00001001 ; 9
	STZ 0b00010001 ; A
	STZ 0b11000001 ; B
	STZ 0b01100011 ; C
	STZ 0b10000101 ; D
	STZ 0b01100001 ; E
	STZ 0b01110001 ; F

	SETZ shield_buffer
	STZ -1
	STZ -1
	STZ -1
	STZ -1

	SETZ digits_buffer
	STZ 0b10001000
	STZ 0b01000100
	STZ 0b00100010
	STZ 0b00010001
	
	SETZ usartR_counter
	STZ 0
	STZ 0


	TIMER0SETUP 50
	TIMER1SETUP 100
	SHIELDSETUP

	LDI r16, 0b01000000
	STS UCSR0A, r16
	LDI r16, 0b00001000
	STS UCSR0B, r16
	LDI r16, 0b00001110
	STS UCSR0C, r16
	LDI r16, 0b00001111
	STS UBRR0H, r16
	LDI r16, 0b11111111
	STS UBRR0L, r16

sei
program:
	rJMP program

; WRITEBYTE <input> <reg2> <reg3> <reg4>
.MACRO WRITEBYTE
	PUSH @0
	PUSH @1
	PUSH @2
	PUSH @3

	BYTETONIBBLE @0, @1, @2
	NIBBLETOHAMMING @1, @3, @0, @2
	STS UDR0, @3
	NIBBLETOHAMMING @2, @3, @0, @1
	LSR @3
	STS tmr1_hamming_buffer, @3

	POP @3
	POP @2
	POP @1
	POP @0
.ENDMACRO

// timer 1 interruption
.DSEG
	usartR_counter: .BYTE 2
.CSEG
usartR_start:
	PUSH r0
	IN r0, SREG
	PUSH r0
	PUSH r16
	PUSH r17

	
usartR_end:
	POP r17
	POP r16
	POP r0
	OUT SREG, r0
	POP r0
	RETI

// timer 0 interruption
tmr0_start:
	PUSH r0
	IN r0, SREG
	PUSH r0
	PUSH r16

	CALL display_shield

tmr0_end:
	POP r16
	POP r0
	OUT SREG, r0
	POP r0
	RETI

// display_shield(): void
; The first thing to call in receiver timer
.DSEG
	display_shield_digit: .BYTE 1
.CSEG
display_shield:
	PUSH r0
	IN r0, SREG
	PUSH r0
	PUSH r16
	PUSH r22
	PUSH r1
	PUSH r2
	LDS r22, display_shield_digit

	SETZ shield_buffer
	SUMZ r22
	LD r1, Z

	SETZ digits_buffer
	SUMZ r22
	LD r2, Z

	CALL write_shield

	INC r22
	CPI r22, 4
	BREQ display_shield_reset

display_shield_end:
	STS display_shield_digit, r22
	POP r2
	POP r1
	POP r22
	POP r16
	POP r0
	OUT SREG, r0
	POP r0
	RET

display_shield_reset:
	LDI r22, 0
	RJMP display_shield_end
