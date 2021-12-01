.ORG 0x0000
	JMP start
.ORG 0x0016
	JMP tmr1_start
.ORG 0x001C
	JMP tmr0_start

.INCLUDE "lib.asm"

#define tmr1_size 4

.DSEG
	data_buffer: .BYTE 512
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

	SETZ receiver_shield_digits
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
	
	SETZ tmr1_hamming_buffer
	STZ 0b11111111

	SETZ tmr1_counter
	STZ 0
	STZ 0

	SETZ tmr1_checksum
	STZ 0
	STZ 0

	SETZ pseudorand_mem
	STZ -1

	TIMER0SETUP 50
	TIMER1SETUP 32767
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
	BYTETONIBBLE @0, @1, @2

	NIBBLETOHAMMING @1, @3, @0, @2

	STS UDR0, @3

	NIBBLETOHAMMING @2, @3, @0, @1
	LSR @3

	STS tmr1_hamming_buffer, @3
.ENDMACRO

// timer 1 interruption
.DSEG
	tmr1_state: .BYTE 1
	tmr1_counter: .BYTE 2
	tmr1_hamming_buffer: .BYTE 1
	tmr1_checksum: .BYTE 2
.CSEG
tmr1_start:
	PUSH r0
	IN r0, SREG
	PUSH r0
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19
	PUSH r20
	PUSH r21

	LDS r19, UCSR0A
	ORI r19, 0b11011111
	CPI r19, 0xFF
	BRNE tmr1_end

	LDS r17, tmr1_counter + 0
	LDS r18, tmr1_counter + 1

	LDS r20, tmr1_hamming_buffer
	SBRS r20, 7
		JMP tmr1_send_store_hamming

	CPWI r17, r18, tmr1_size
	BREQ tmr1_send_high_checksum
	CPWI r17, r18, tmr1_size + 1
	BREQ tmr1_send_low_checksum0
	CPWI r17, r18, tmr1_size + 2
	BREQ tmr1_end

	JMP tmr1_generate_number

tmr1_send_low_checksum0:
	JMP tmr1_send_low_checksum

tmr1_end:
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

tmr1_send_high_checksum:
	PUSH r16
	PUSH r17

	LDS r17, tmr1_checksum + 0
	WRITEBYTE r17, r18, r19, r20

	POP r17
	POP r16
	RJMP tmr1_end

tmr1_send_low_checksum:
	PUSH r16
	PUSH r17

	LDS r17, tmr1_checksum + 1
	WRITEBYTE r17, r18, r19, r20

	POP r17
	POP r16
	RJMP tmr1_end

tmr1_generate_number:
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19

	CALL generate_pseudorandom_number
	MOV r17, r16

	LDS r18, tmr1_checksum + 0
	LDS r19, tmr1_checksum + 1
	ADDW1 r18, r19, r17
	STS tmr1_checksum + 0, r18
	STS tmr1_checksum + 1, r19

	WRITEBYTE r17, r18, r19, r20

	POP r19
	POP r18
	POP r17
	POP r16
	RJMP tmr1_end

tmr1_send_store_hamming:
	PUSH r16
	PUSH r17
	PUSH r18

	LDS r17, tmr1_counter + 0
	LDS r18, tmr1_counter + 1
	INCW r17, r18
	STS tmr1_counter + 0, r17
	STS tmr1_counter + 1, r18

	LDS r17, tmr1_hamming_buffer
	LSL r17
	STS UDR0, r17

	LDI r17, 0b11111111
	STS tmr1_hamming_buffer, r17

	POP r18
	POP r17
	POP r16
	RJMP tmr1_end


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

	SETZ receiver_shield_buffer
	SUMZ r22
	LD r1, Z

	SETZ receiver_digit_buffer
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

/// generate_pseudorandom_number(): byte
.DSEG
	pseudorand_mem: .BYTE 1
.CSEG
generate_pseudorandom_number:
	PUSH r17
	LDS r16, pseudorand_mem

	MOV r17, r16
	LSL r17
	LSL r17
	LSL r17
	EOR r16, r17
	MOV r17, r16
	LSR r17
	LSR r17
	LSR r17
	LSR r17
	LSR r17
	EOR r16, r17

	STS pseudorand_mem, r16
	POP r17
	RET
