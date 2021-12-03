.ORG 0x0000
	JMP start
.ORG 0x0008
	JMP pcint1_start
.ORG 0x0016
	JMP tmr1_start
.ORG 0x001C
	JMP tmr0_start

.INCLUDE "lib.asm"

#define BUFFER_SIZE 512

.DSEG
	; Stores the pseudorandom bytes
	data_buffer: .BYTE BUFFER_SIZE

	; This memory space acts as an intermediate between the shield and other parts of the program which modify what the shield displays
	shield_buffer: .BYTE 4

	; A L.U.T. to translate a nibble into its correspondent digit to display on shield
	shield_digits: .BYTE 16

	; A L.U.T. used only by the shield interruption
	digits_buffer: .BYTE 4
.CSEG
start:
	; Disable the transmitter, just in case
	LDI r16, 0b00000000
	STS UCSR0B, r16

	; Prepare PD1 (USART output pin) for sending data
	LDI r16, 0b00000010
	OUT DDRD, r16
	OUT PORTD, r16
	
	; Prepare PC1 for input interruption
	LDI r16, 0b00000000
	OUT DDRC, r16
	LDI r16, 0b11111111
	OUT PORTC, r16
	
	; Set shield digits
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

	; Initialize shield with all leds turned off
	SETZ shield_buffer
	STZ -1
	STZ -1
	STZ -1
	STZ -1

	; Set digits buffer
	SETZ digits_buffer
	STZ 0b10001000
	STZ 0b01000100
	STZ 0b00100010
	STZ 0b00010001
	
	SETZ tmr1_hamming_buffer
	STZ 0b11111111

	SETZ tmr1_state
	STZ -1

	SETZ tmr1_counter
	STZ 0
	STZ 0

	SETZ tmr1_checksum
	STZ 0
	STZ 0

	SETZ pseudorand_mem
	STZ -1

	; Timer 0 handles the operation of reading the shield buffer and displaying the contents on the shield
	TIMER0SETUP 50
	SHIELDSETUP

	; Timer 1 handles the main program
	TIMER1SETUP 50

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

	; The button interrupt determines when to start the program
	LDI r16, 0b00000010
	STS PCMSK1, r16
	STS PCICR, r16

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

// pcint1 interruption
pcint1_start:
	PUSH r0
	IN r0, SREG
	PUSH r0
	PUSH r16

	LDS r16, tmr1_state
	CPI r16, 0xFF
	BRNE pcint1_end

	LDI r16, 0
	STS tmr1_state, r16

pcint1_end:
	POP r16
	POP r0
	OUT SREG, r0
	POP r0
	RETI

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

	LDS r17, tmr1_state
	CPI r17, -1
		BREQ tmr1_end
	CPI r17, 0
		BREQ tmr1_call_write_data

	CALL send_data
	RJMP tmr1_end

	tmr1_call_write_data:
		CALL write_data
	
tmr1_end:
	POP r17
	POP r16
	POP r0
	OUT SREG, r0
	POP r0
	RETI

// void write_data();
write_data:
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19
	PUSH r20
	PUSH r21

	CALL generate_pseudorandom_number
	MOV r17, r16

	LDS r18, tmr1_counter + 0
	LDS r19, tmr1_counter + 1

	SETZ data_buffer
	SUMZW r18, r19
	ST Z, r17

	LDS r20, tmr1_checksum + 0
	LDS r21, tmr1_checksum + 1
	ADDW1 r20, r21, r17
	STS tmr1_checksum + 0, r20
	STS tmr1_checksum + 1, r21

	INCW r18, r19
	STS tmr1_counter + 0, r18
	STS tmr1_counter + 1, r19

	CPWI r18, r19, BUFFER_SIZE
	BRNE writedata_end
	
		PUSH r22
		PUSH r23
		PUSH r24

		BYTETONIBBLE r20, r22, r23
		LOADBYTEFROMSLICE r24, shield_digits, r22
		STS shield_buffer + 0, r24
		LOADBYTEFROMSLICE r24, shield_digits, r23
		STS shield_buffer + 1, r24

		BYTETONIBBLE r21, r22, r23
		LOADBYTEFROMSLICE r24, shield_digits, r22
		STS shield_buffer + 2, r24
		LOADBYTEFROMSLICE r24, shield_digits, r23
		STS shield_buffer + 3, r24

		POP r24
		POP r23
		POP r22

	LDI r21, 1
	STS tmr1_state, r21

	LDI r21, 0
	STS tmr1_counter + 0, r21
	STS tmr1_counter + 1, r21

writedata_end:
	POP r21
	POP r20
	POP r19
	POP r18
	POP r17
	POP r16
	RET

// void send_data();
send_data:
	PUSH r16
	PUSH r17
	PUSH r18
	PUSH r19
	PUSH r20

	LDS r17, tmr1_counter + 0
	LDS r18, tmr1_counter + 1

	CPWI r17, r18, BUFFER_SIZE
	BRSH senddata_end0
	RJMP senddata_continue0

	senddata_end0:
		JMP senddata_end
	senddata_continue0:

	CALL can_write
	CPI r16, 0
	BREQ senddata_end0

	LDS r19, tmr1_hamming_buffer
	MOV r20, r19
	ORI r19, 0b01111111
	CPI r19, 0xFF
	BREQ senddata_write_normal
		LSL r20
		STS UDR0, r20
		LDI r20, 0b11111111
		STS tmr1_hamming_buffer, r20

		INCW r17, r18
		STS tmr1_counter + 0, r17
		STS tmr1_counter + 1, r18

		CPWI r17, r18, BUFFER_SIZE
		BRLO senddata_end0

			LDS r16, PCMSK1
			ANDI r16, 0b11111101
			STS PCMSK1, r16
			LDI r16, 0b00000000
			STS UCSR0B, r16

		RJMP senddata_end

	senddata_write_normal:
		SETZ data_buffer
		SUMZW r17, r18
		LD r19, Z
		WRITEBYTE r19, r18, r17, r16

senddata_end:
	POP r20
	POP r19
	POP r18
	POP r17
	POP r16
	RET

// byte can_write();
can_write:
	LDS r16, UCSR0A
	ORI r16, 0b11011111
	CPI r16, 0xFF
	IN r16, SREG
	LSR r16
	ANDI r16, 0b00000001
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

// void display_shield();
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

// byte generate_pseudorandom_number();
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
