
WAIT5us:
	push	Temp0
	ldi		Temp0,0x0C
	Loop5us:
		wdr
		dec		Temp0
		brne	Loop5us
	pop		Temp0
	ret

WAIT100us:
	push	Temp1
	ldi		Temp1,0xDC
	Loop100us:
		wdr
		nop
		dec		Temp1
		brne	Loop100us
	pop		Temp1
	ret

WAIT600us:
	push	Temp0
	ldi		Temp0,6
	Loop600us:
		wdr
		rcall	WAIT100us
		dec		Temp0
		brne	Loop600us
	pop		Temp0
	ret

WAIT1ms:
	push	Temp0
	ldi		Temp0,10
	Loop1ms:
		wdr
		rcall	wait100us
		dec		Temp0
		brne	Loop1ms
	pop		Temp0
	ret

WAIT10ms:
	push	Temp0
	push	Temp1
	ldi		Temp0,0xFF
	ldi		Temp1,0x90
	Loop10ms:
		wdr
		dec		Temp0
		brne	Loop10ms
	wdr
	ldi		Temp0,0xFF
	dec		Temp1
	brne	Loop10ms
	pop		Temp1
	pop		Temp0
	ret

WAIT100ms:
	push	Temp2
	ldi		Temp2,0x08		;0x0A
	Loop100ms:
	wdr
	rcall	WAIT10ms
	dec		Temp2
	brne	Loop100ms
	pop		Temp2
	ret