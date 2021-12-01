; Set in a stack-like fashion into the SRAM via the Z pointer
; STZ <value_to_store>
.MACRO STZ
	LDI r16, @0
	ST Z+, r16
.ENDMACRO

; Set the Z pointer
; SETZ <pointer_location>
.MACRO SETZ
	LDI ZH, high(@0)
	LDI ZL, low(@0)
.ENDMACRO

.MACRO SUMZ
	ADD ZL, @0
	BRCC PC+2
		INC ZH
.ENDMACRO

; Adds the content of a word register to the Z pointer
; SUMZW <high_register> <low_register>
.MACRO SUMZW
	ADD ZH, @0
	SUMZ @1
.ENDMACRO

; LOADBYTEFROMSLICE <output> <input_pointer> <input_index>
.MACRO LOADBYTEFROMSLICE
	SETZ @1
	SUMZ @2
	LD @0, Z
.ENDMACRO
