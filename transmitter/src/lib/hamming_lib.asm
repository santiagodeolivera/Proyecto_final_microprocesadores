; Converts a nibble into a hamming byte
; NIBBLETOHAMMING <input> <output> <reg2> <reg3>
.MACRO NIBBLETOHAMMING
	PUSH @0
	PUSH @2
	PUSH @3

	CLR @2
	CLR @1

	; If byte 0 of input (I0) is set, output = output ^ 0b00001110
	MOV @2, @0
	ORI @2, 0b11111110
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d3_end
		LDI @3, 0b00001110
		EOR @1, @3
	nibble_to_hamming_d3_end:

	; If byte 1 of input (I1) is set, output = output ^ 0b00001110
	MOV @2, @0
	ORI @2, 0b11111101
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d5_end
		LDI @3, 0b00110010
		EOR @1, @3
	nibble_to_hamming_d5_end:

	; If byte 2 of input (I2) is set, output = output ^ 0b01010100
	MOV @2, @0
	ORI @2, 0b11111011
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d6_end
		LDI @3, 0b01010100
		EOR @1, @3
	nibble_to_hamming_d6_end:

	; If byte 3 of input (I3) is set, output = output ^ 0b10010110
	MOV @2, @0
	ORI @2, 0b11110111
	CPI @2, 0xFF
	BRNE nibble_to_hamming_d7_end
		LDI @3, 0b10010110
		EOR @1, @3
	nibble_to_hamming_d7_end:

	; Result:
	;    D7 = I3
	;    D6 = I2
	;    D5 = I1
	;    P4 = I1 ^ I2 ^ I3 = D5 ^ D6 ^ D7
	;    D3 = I0
	;    P2 = I0 ^ I2 ^ I3 = D3 ^ D6 ^ D7
	;    P1 = I0 ^ I1 ^ I3 = D5 ^ D5 ^ D7

	POP @3
	POP @2
	POP @0
.ENDMACRO

; Converts a hamming byte into a nibble, correcting it in the process
; HAMMINGTONIBBLE <input> <output> <reg1> <reg2> <reg3>
.MACRO HAMMINGTONIBBLE
	PUSH @0
	PUSH @2
	PUSH @3
	PUSH @4

	CLR @4
	INC @4
	CLR @1

	; @4 represents a local byte variable with one bit set, whose position determines which byte to correct

	; Make XOR of bytes 1, 3, 5 and 7
	; Example: @0 = 0b01101001
	MOV @2, @0
	CLR @3
	;                 76543210
	;          @2 = 0b01101001
	;          @3 = 0b00000000 <- @3[0] = 0
	LSR @2
	;                  7654321
	;          @2 = 0b00110100
	;          @3 = 0b00000000 <- @3[0] = 0
	EOR @3, @2
	;                  7654321
	;          @2 = 0b00110100
	;          @3 = 0b00110100 <- @3[0] = 0 ^ @0[1] = @0[1]
	LSR @2
	LSR @2
	;                    76543
	;          @2 = 0b00001101
	;          @3 = 0b00110100 <- @3[0] = @0[1]
	EOR @3, @2
	;                    76543
	;          @2 = 0b00001101
	;          @3 = 0b00111001 <- @3[0] = @0[1] ^ @0[3]
	LSR @2
	LSR @2
	;                      765
	;          @2 = 0b00000011
	;          @3 = 0b00111001 <- @3[0] = @0[1] ^ @0[3]
	EOR @3, @2
	;                      765
	;          @2 = 0b00000011
	;          @3 = 0b00111010 <- @3[0] = @0[1] ^ @0[3] ^ @0[5]
	LSR @2
	LSR @2
	;                        7
	;          @2 = 0b00000000
	;          @3 = 0b00111010 <- @3[0] = @0[1] ^ @0[3] ^ @0[5]
	EOR @3, @2
	;          @2 = 0b00000000
	;          @3 = 0b00111010 <- @3[0] = @0[1] ^ @0[3] ^ @0[5] ^ @0[7]
	ORI @3, 0b11111110
	; If XOR of bytes 1, 3, 5 and 7 is 1, move @4 one place to the left
	CPI @3, 0xFF
	BRNE xor_p1_end
		LSL @4
	xor_p1_end:
	
	; Make XOR of bytes 2, 3, 6 and 7
	MOV @2, @0
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
	; If XOR of bytes 2, 3, 6 and 7 is 1, move @4 two places to the left
	CPI @3, 0xFF
	BRNE xor_p2_end
		LSL @4
		LSL @4
	xor_p2_end:

	; Make XOR of bytes 4, 5, 6 and 7
	MOV @2, @0
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
	; If XOR of bytes 4, 5, 6 and 7 is 1, move @4 four places to the left
	CPI @3, 0xFF
	BRNE xor_p4_end
		LSL @4
		LSL @4
		LSL @4
		LSL @4
	xor_p4_end:

	; Apply correction (if there were no errors, it's applied on bit 0, which doesn't count in hamming bytes)
	MOV @2, @0
	EOR @2, @4

	; Translate bits D7, D6, D5 and D3 into resulting nibble

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

; Converts a byte into a pair of nibbles
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

; Converts a pair of nibbles into a byte
; NIBBLETOBYTE <input_high> <input_low> <output>
.MACRO NIBBLETOBYTE
	MOV @2, @0
	LSL @2
	LSL @2
	LSL @2
	LSL @2
	OR @2, @1
.ENDMACRO

; Converts a byte into a pair of hamming bytes
; BYTETOHAMMING <input> <output_high> <output_low> <reg1>
.MACRO BYTETOHAMMING
	PUSH @0
	PUSH @3

	BYTETONIBBLE @0, @2, @3
	NIBBLETOHAMMING @2, @1, @0, @3
	NIBBLETOHAMMING @3, @2, @1, @0

	POP @3
	POP @0
.ENDMACRO

; Converts a pair of hamming bytes into a byte, correcting them in the process
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