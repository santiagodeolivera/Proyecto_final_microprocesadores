; TIMER0SETUP <timer_limit>
.MACRO TIMER0SETUP
	LDI r16, 0b00000010   ; Timer mode
	OUT TCCR0A, r16
	LDI r16, 0b00000101   ; Clock period
	OUT TCCR0B, r16
	LDI r16, @0           ; Timer limit
	OUT OCR0A, r16
	LDI r16, 0b00000010   ; Timer mask
	STS TIMSK0, r16		
.ENDMACRO

; TIMER1SETUP <timer_limit>
.MACRO TIMER1SETUP
	PUSH r16

	LDI r16, 0b00000000   ; Timer mode
	STS TCCR1A, r16

	LDI r16, 0b00001101   ; Clock period
	STS TCCR1B, r16

	LDI r16, high(@0)     ; Timer limit (high byte)
	STS OCR1AH, r16

	LDI r16, low(@0)      ; Timer limit (low byte)
	STS OCR1AL, r16

	LDS r16, TIMSK1
	ORI r16, 0b00000010   ; Timer mask
	STS TIMSK1, r16

	POP r16
.ENDMACRO
