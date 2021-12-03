; Performs a 1-byte integer division, leaving the reminder in the dividend register
; INTEGERDIVISION <dividend register> <literal divider> <quotient register>
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

; Performs a 2-byte integer division, leaving the reminder in the dividend registers
; WORDINTEGERDIVISION <dividend's high register> <dividend's low register> <literal divider> <quotient's high register> <quotient's low register>
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

; Decreases a word by 1
; DECW <high_register> <low_register>
.MACRO DECW
	DEC @1
	CPI @1, 0xFF
	BRNE PC+2
		DEC @0
.ENDMACRO

; Increases a word by 1
; INCW <high_register> <low_register>
.MACRO INCW
	INC @1
	BRNE PC+2
		INC @0
.ENDMACRO

; Performs a comparison between a word register and a word literal
; May only work with unsigned comparisions, though
; CPWI <high_register> <low_register> <literal>
.MACRO CPWI
	CPI @0, high(@2)
	BRNE cpwi_end
		CPI @1, low(@2)
	cpwi_end:
.ENDMACRO

; Performs a comparison between two word registers
; May only work with unsigned comparisions, though
; CPWI <register_1_high> <register_1_low> <register_2_high> <register_2_low>
.MACRO CPW
	CP @0, @2
	BRNE cpw_end
		CP @1, @3
	cpw_end:
.ENDMACRO

; Adds the content of a register into a word register
; ADDW1 <high_register_result> <low_register_result> <register>
.MACRO ADDW1
	ADD @1, @2
	BRCC PC+2
		INC @0
.ENDMACRO

; Adds the content of a word register into another word register
; ADDW2 <high_register_result> <low_register_result> <register_high> <register_low>
.MACRO ADDW2
	ADD @0, @2
	ADDW1 @0, @1, @3
.ENDMACRO

; Adds the content of a byte register into a 3-byte register
; ADD3B1 <register_result_2> <register_result_1> <register_result_0> <register>
.MACRO ADD3B1
	ADD @2, @3
	BRCC add3b1_end
		INC @1
	BRNE add3b1_end
		INC @0
	add3b1_end:
.ENDMACRO
