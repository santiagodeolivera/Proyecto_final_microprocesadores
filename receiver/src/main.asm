.ORG 0x0000
	JMP start
.ORG 0x001C
	JMP tmr0_start
.ORG 0x0024
	JMP usartR_start

.INCLUDE "lib.asm"

#define BUFFER_SIZE 4

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

	SETZ usartR_hamming_buffer
	STZ -1
	STZ -1
	
	SETZ usartR_counter
	STZ 0
	STZ 0


	TIMER0SETUP 50
	SHIELDSETUP

	LDI r16, 0b01000000
	STS UCSR0A, r16

	LDI r16, 0b00000000
	STS UCSR0B, r16
	LDI r16, 0b10010000
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

// USART read complete interruption
.DSEG
	usartR_counter: .BYTE 2
	usartR_hamming_buffer: .BYTE 1
.CSEG
usartR_start:
	PUSH r0
	IN r0, SREG
	PUSH r0
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19
	PUSH r20
	PUSH r21

	LDS r17, usartR_counter + 0
	CPI r17, 0xFF
	BRNE usartR_continue
		JMP usartR_end

	usartR_continue:
	LDS r17, UDR0
	ANDI r17, 0b11111110

	LDS r18, usartR_hamming_buffer
	ORI r18, 0b11111110
	CPI r18, 0xFF
	BRNE usartR_store_byte
		STS usartR_hamming_buffer, r17
		RJMP usartR_end

	usartR_store_byte:
		LDS r18, usartR_hamming_buffer
		HAMMINGTOBYTE r18, r17, r19, r20, r21

		SETZ usartR_hamming_buffer
		STZ -1

		LDS r20, usartR_counter + 0
		LDS r21, usartR_counter + 1
		SETZ data_buffer
		SUMZW r20, r21
		ST Z, r19

		INCW r20, r21
		STS usartR_counter + 0, r20
		STS usartR_counter + 1, r21

		CPWI r20, r21, BUFFER_SIZE
		BRLO usartR_end

			CALL display_checksum
			LDI r20, -1
			LDI r21, -1
			STS usartR_counter + 0, r20
			STS usartR_counter + 1, r21
	
usartR_end:
	POP r21
	POP r20
	POP r19
	POP r18
	POP r17
	POP r16
	POP r0
	OUT SREG, r0
	POP r0
	RETI

// void display_checksum();
display_checksum:
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19
	PUSH r20
	PUSH r21

	CLR r17
	CLR r18
	CLR r19
	CLR r20

	displaychecksum_start:
	SETZ data_buffer
	SUMZW r17, r18
	LD r21, Z

	ADDW1 r19, r20, r21
	INCW r17, r18

	CPWI r17, r18, BUFFER_SIZE
	BRLO displaychecksum_start

	MOV r16, r19
	MOV r17, r20
	CALL store_on_shield

	POP r21
	POP r20
	POP r19
	POP r18
	POP r17
	POP r16
	RET

// void store_on_shield(short n);
store_on_shield:
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19

	MOV r18, r16
	LSR r18
	LSR r18
	LSR r18
	LSR r18
	LOADBYTEFROMSLICE r19, shield_digits, r18
	STS shield_buffer + 0, r19

	MOV r18, r16
	ANDI r18, 0b00001111
	LOADBYTEFROMSLICE r19, shield_digits, r18
	STS shield_buffer + 1, r19

	MOV r18, r17
	LSR r18
	LSR r18
	LSR r18
	LSR r18
	LOADBYTEFROMSLICE r19, shield_digits, r18
	STS shield_buffer + 2, r19

	MOV r18, r17
	ANDI r18, 0b00001111
	LOADBYTEFROMSLICE r19, shield_digits, r18
	STS shield_buffer + 3, r19

	POP r19
	POP r18
	POP r17
	POP r16
	RET

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
