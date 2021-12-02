; NIBBLETOHAMMING <input> <output> <reg2> <reg3>
.MACRO NIBBLETOHAMMING
	PUSH @0
	PUSH @2
	PUSH @3

	CLR @2
	CLR @1

	MOV @2, @0
	ORI @2, 0b11111110
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d3_end
		LDI @3, 0b00001110
		EOR @1, @3
	nibble_to_hamming_d3_end:

	MOV @2, @0
	ORI @2, 0b11111101
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d5_end
		LDI @3, 0b00110010
		EOR @1, @3
	nibble_to_hamming_d5_end:

	MOV @2, @0
	ORI @2, 0b11111011
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d6_end
		LDI @3, 0b01010100
		EOR @1, @3
	nibble_to_hamming_d6_end:

	MOV @2, @0
	ORI @2, 0b11110111
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d7_end
		LDI @3, 0b10010110
		EOR @1, @3
	nibble_to_hamming_d7_end:

	POP @3
	POP @2
	POP @0
.ENDMACRO

; @0: input
; @1: output
; HAMMINGTONIBBLE <input> <output> <reg1> <reg2> <reg3>
.MACRO HAMMINGTONIBBLE
	PUSH @0
	PUSH @2
	PUSH @3
	PUSH @4

	CLR @4
	INC @4
	CLR @1

	MOV @2, @0
	; Make XOR of bytes 1, 3, 5 and 7
	CLR @3
	LSR @2
	EOR @3, @2
	LSR @2
	LSR @2
	EOR @3, @2
	LSR @2
	LSR @2
	EOR @3, @2
	LSR @2
	LSR @2
	EOR @3, @2
	ORI @3, 0b11111110
	CPI @3, 0xFF
	BRNE xor_p1_end
		LSL @4
	xor_p1_end:
	
	MOV @2, @0
	; Make XOR of bytes 2, 3, 6 and 7
	CLR @3
	LSR @2
	LSR @2
	EOR @3, @2
	LSR @2
	EOR @3, @2
	LSR @2
	LSR @2
	LSR @2
	EOR @3, @2
	LSR @2
	EOR @3, @2
	ORI @3, 0b11111110
	CPI @3, 0xFF
	BRNE xor_p2_end
		LSL @4
		LSL @4
	xor_p2_end:

	MOV @2, @0
	; Make XOR of bytes 4, 5, 6 and 7
	CLR @3
	LSR @2
	LSR @2
	LSR @2
	LSR @2
	EOR @3, @2
	LSR @2
	EOR @3, @2
	LSR @2
	EOR @3, @2
	LSR @2
	EOR @3, @2
	ORI @3, 0b11111110
	CPI @3, 0xFF
	BRNE xor_p4_end
		LSL @4
		LSL @4
		LSL @4
		LSL @4
	xor_p4_end:

	MOV @2, @0
	EOR @2, @4

	MOV @4, @2
	ORI @4, 0b11110111
	CPI @4, 0xFF
	BRNE PC+2
		ORI @1, 1

	MOV @4, @2
	ORI @4, 0b11011111
	CPI @4, 0xFF
	BRNE PC+2
		ORI @1, 2

	MOV @4, @2
	ORI @4, 0b10111111
	CPI @4, 0xFF
	BRNE PC+2
		ORI @1, 4

	MOV @4, @2
	ORI @4, 0b01111111
	CPI @4, 0xFF
	BRNE PC+2
		ORI @1, 8

	POP @4
	POP @3
	POP @2
	POP @0
.ENDMACRO


; BYTETONIBBLE <input> <output_high> <output_low>
.MACRO BYTETONIBBLE
	MOV @1, @0
	LSR @1
	LSR @1
	LSR @1
	LSR @1

	MOV @2, @0
	ANDI @2, 0b00001111
.ENDMACRO

; NIBBLETOBYTE <input_high> <input_low> <output>
.MACRO NIBBLETOBYTE
	MOV @2, @0
	LSL @2
	LSL @2
	LSL @2
	LSL @2
	OR @2, @1
.ENDMACRO

; BYTETOHAMMING <input> <output_high> <output_low> <reg1>
.MACRO BYTETOHAMMING
	BYTETONIBBLE @0, @2, @3
	NIBBLETOHAMMING @2, @1, @0, @3
	NIBBLETOHAMMING @3, @2, @1, @0
.ENDMACRO

; HAMMINGTOBYTE <input_high> <input_low> <output> <reg1> <reg2>
.MACRO HAMMINGTOBYTE
	PUSH @0
	PUSH @1
	PUSH @3
	PUSH @4

	HAMMINGTONIBBLE @0, @3, @2, @1, @4
	HAMMINGTONIBBLE @1, @4, @2, @0, @3
	NIBBLETOBYTE @3, @4, @2

	POP @4
	POP @3
	POP @1
	POP @0
.ENDMACRO