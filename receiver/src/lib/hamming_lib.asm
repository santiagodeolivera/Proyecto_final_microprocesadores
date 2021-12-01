; NIBBLETOHAMMING <input> <output> <reg2> <reg3>
.MACRO NIBBLETOHAMMING
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

; BYTETONIBBLE <input_high> <input_low> <output>
.MACRO NIBBLETOBYTE
	MOV @2, @0
	LSL @2
	LSL @2
	LSL @2
	LSL @2
	OR @2, @1
.ENDMACRO
