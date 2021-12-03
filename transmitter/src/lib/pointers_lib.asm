; Store a literal byte into the SRAM in a stack-like fashion via the Z pointer
; STZ <value_to_store>
.MACRO STZ
	LDI r16, @0
	ST Z+, r16
.ENDMACRO

; Set the Z pointer to a literal word
; SETZ <pointer_location>
.MACRO SETZ
	LDI ZH, high(@0)
	LDI ZL, low(@0)
.ENDMACRO

; Add the content of a byte register into the Z pointer
; SUMZ <register>
.MACRO SUMZ
	ADD ZL, @0
	BRCC PC+2
		INC ZH
.ENDMACRO

; Add the content of a word register to the Z pointer
; SUMZW <high_register> <low_register>
.MACRO SUMZW
	ADD ZH, @0
	SUMZ @1
.ENDMACRO

; Loads a byte from an array of bytes in SRAM
; LOADBYTEFROMSLICE <output> <input_pointer> <input_index>
.MACRO LOADBYTEFROMSLICE
	SETZ @1
	SUMZ @2
	LD @0, Z
.ENDMACRO

; Stores a byte into an array of bytes in SRAM
; STOREBYTEINTOSLICE <output_pointer> <output_index> <input>
.MACRO STOREBYTEINTOSLICE
	SETZ @0
	SUMZ @1
	ST Z, @2
.ENDMACRO