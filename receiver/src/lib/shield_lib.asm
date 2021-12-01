.MACRO SHIELDSETUP
	PUSH r16
	IN		r16,    DDRB
	ORI		r16,    0b00000001
	OUT		DDRB,	r16			; SD (serial data)

	IN		r16,    PORTB
	ORI		r16,    0b00000001
	OUT		PORTB,	r16

	IN		r16,	DDRD
	ORI		r16,	0b10010000
	OUT		DDRD,	r16
	IN		r16,	PORTD
	ANDI	r16,	0b01101111  ; SCLK (bit 7, serial clock) and LCH (bit 4, latch clock)
	OUT		PORTD,	r16
	POP r16
.ENDMACRO

; Writes a digit into a concrete digit slot of the shield
; Parameters:
;     r16: The digit to write
;     r17: The digit slot
write_shield: 
	CALL	write_bytes_into_PB0
	MOV		r1, r2
	CALL	write_bytes_into_PB0
	SBI		PORTD, 4		; LCHCLK = 1
	CBI		PORTD, 4		; LCHCLK = 0
	RET

write_bytes_into_PB0:
	LDI		r18, 0x08
	PB0_loop:
		CBI		PORTD, 7		; SCLK = 0
		LSR		r1
		BRCS	PB0_set
		CBI		PORTB, 0		; SD = 0
		RJMP	PB0_set_end
	PB0_set:
		SBI		PORTB, 0		; SD = 1
	PB0_set_end:
		SBI		PORTD, 7		; SCLK = 1
		DEC		r18
		BRNE	PB0_loop
		RET

