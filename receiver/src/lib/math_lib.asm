.MACRO INTEGERDIVISION
	CLR @2
	byte_to_digits_start:
		CPI @0, @1
		BRLO byte_to_digits_end
		SUBI @0, @1
		INC @2
		RJMP byte_to_digits_start
	byte_to_digits_end:
.ENDMACRO

; WORDINTEGERDIVISION <dividend's high register> <dividend's low register> <literal quotient divider> <quotient's high register> <quotient's low register>
.MACRO WORDINTEGERDIVISION
	CLR @4
	CLR @3
	short_to_digits_start:
		CPI @0, high(@2)
			BRLO short_to_digits_end
			BRNE short_to_digits_add
		CPI @1, low(@2)
			BRLO short_to_digits_end
	short_to_digits_add:
		SUBI @1, low(@2)
		BRPL PC+2
			DEC @0
		SUBI @0, high(@2)
		INC @4
		BRNE PC+2
			INC @3
		RJMP short_to_digits_start
	short_to_digits_end:
.ENDMACRO

; DECW <high_register> <low_register>
.MACRO DECW
	DEC @1
	CPI @1, 0xFF
	BRNE PC+2
		DEC @0
.ENDMACRO

; INCW <high_register> <low_register>
.MACRO INCW
	INC @1
	BRNE PC+2
		INC @0
.ENDMACRO

; CPWI <high_register> <low_register> <literal>
.MACRO CPWI
	CPI @0, high(@2)
	BRNE cpwi_end
		CPI @1, low(@2)
	cpwi_end:
.ENDMACRO

; ADDW1 <high_register_result> <low_register_result> <register>
.MACRO ADDW1
	ADD @1, @2
	BRCC PC+2
		INC @0
.ENDMACRO