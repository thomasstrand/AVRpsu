;********************************************************************
;*																	*
;*				Initialization and configuration					*
;*																	*
;********************************************************************

APP:
;The stack pointer, ports and LCD are initialized in the boot loader.

;Timer1.
	ldi		Temp0,0b10100000		;Set OC1A/OC1B when up-counting, clear them when down-counting.
	out		TCCR1A,Temp0			;Phase and frequency correct PWM. (Mode 8 on page 97).

	ldi		Temp0,high(256)			;Set TOP value.
	out		ICR1H,Temp0
	ldi		Temp0,low(256)
	out		ICR1L,Temp0

	clr		Temp0
	out		OCR1AH,Temp0
	out		OCR1AL,Temp0
	out		OCR1BH,Temp0
	out		OCR1BL,Temp0

	ldi		Temp0,0b00010001		;Clock select: no prescaling.
	out		TCCR1B,Temp0

;USART.
;The USART frame format is set in the boot loader. 
;The Transmitter and Receiver are also enabled there.
	ldi		Temp0,high(uart_ee)
	ldi		Temp1,low(uart_ee)
	rcall	EE_READ					;Read USART baud rate from EEPROM.
	mov		baudrate,DataL
	rcall	SET_BAUD

	ldi		Temp0,0b10011000
	out		UCSRB,Temp0				;Enable Receive Complete Interrupt.
	rcall	FLUSH_USART

;ADC
	ldi		Temp0,0x66
	out		ADMUX,Temp0				;Vref=AVCC, Left adjusted result, ADC6 input.

	ldi		Temp0,0x8E
	out		ADCSR,Temp0				;Enable ADC, Free running, IRQ, clk/64.

;Start Screen.
	ldi		DataL,0x48				;Set CG RAM Adress to the second user-definable
	rcall	LCD_CMD					;character and load start screen characters (cannot use ASCII code 0).
	ldi		ZH,high(START_CHAR*2)
	ldi		ZL,low(START_CHAR*2)
	char_loop:
	lpm		DataL,Z+
	cpi		DataL,0xFF
	breq	char_ret
	rcall	LCD_RAM
	rjmp	char_loop
	char_ret:
	ldi		POS,0
	rcall	LCD_CUR

	ldi		POS,0
	ldi		ZH,high(TEST_STR*2)
	ldi		ZL,low(TEST_STR*2)
	rcall	LCD_FMSG

start_screen:
	clr		POS	
	start_loop:
	ldi		ZH,high(ALIEN*2)
	ldi		ZL,low(ALIEN*2)
	ldi		Temp0,8
	mul		POS,Temp0
	add		ZL,r0
	adc		ZH,r1					;ZH:ZL=((ALIEN*2)+(POS*8))
	ldi		DataH,0x48				;First pixel row of alien character.
	rcall	LCD_PIX

	ldi		ZH,high(STARS*2)
	ldi		ZL,low(STARS*2)
	ldi		Temp0,8
	mul		POS,Temp0
	add		ZL,r0
	adc		ZH,r1					;ZH:ZL=((ALIEN*2)+(POS*8))
	ldi		DataH,0x78				;First pixel row of star character.
	rcall	LCD_PIX

	rcall	WAIT100ms
	sbis	PIND,SET_K
	rjmp	start_ret
	inc		POS
	cpi		POS,8
	brlo	start_loop
	rjmp	start_screen
	start_ret:

;User-defined characters.
	ldi		DataL,0x48				;Set CG RAM Adress to the second user-definable
	rcall	LCD_CMD					;character and load user-defined characters (cannot use ASCII code 0).
	ldi		ZH,high(SYS_CHAR*2)
	ldi		ZL,low(SYS_CHAR*2)
	syschar_loop:
	lpm		DataL,Z+
	cpi		DataL,0xFF
	breq	syschar_ret
	rcall	LCD_RAM
	rjmp	syschar_loop
	syschar_ret:
	ldi		POS,0
	rcall	LCD_CUR


;External interrupts.
	ldi		Temp0,0x00				;Sleep modes and external interrupts.
	out		MCUCR,Temp0				;Low level on INT0 and INT1 generates interrupts.
	ldi		Temp0,0xC0
	out		GICR,Temp0				;Enable INT0 and INT1.

;Timer0.
	ldi		Temp0,0x00000001
	out		TIMSK,Temp0				;Enable Timer0 overflow interrupt.
	ldi		Temp0,0b00000101
	out		TCCR0,Temp0				;Clock select: clkIO/1024.

;Temperature sensor.
	rcall	t_reset					;Initialize temperature sensor.
	ldi		Temp0,high(fan_ee)		;Read f_start from EEPROM.
	ldi		Temp1,low(fan_ee)
	rcall	EE_READ
	clr		XH
	ldi		XL,(f_start)
	st		X+,DataL				;Store f_start to SRAM.

	ldi		Temp0,high(fan_ee+1)	;Read f_stop from EEPROM.
	ldi		Temp1,low(fan_ee+1)
	rcall	EE_READ
	st		X,DataL					;Store f_stop to SRAM.

;Copy overtemperature string to SRAM.
	ldi		ZH,high(OVERHEAT_STR*2)
	ldi		ZL,low(OVERHEAT_STR*2)	;Pointer for input.
	ldi		YH,high(disp_str+16)
	ldi		YL,low(disp_str+16)		;Pointer for output.
	copy_loop:
	lpm		DataL,Z+
	tst		DataL
	breq	copy_ret
	st		Y+,DataL
	rjmp	copy_loop
	copy_ret:

;General initialization.
	clr		STAT					;Initial variable values.
	clr		MODE
	clr		adc_count
	clr		rel_count
	in		Temp0,PortD
	andi	Temp0,0b00110000		;Load initial state for
	mov		ROT,Temp0				;rotary encoder.

;Settings
	ldi		Temp0,high(vset_ee)
	ldi		Temp1,low(vset_ee)
	rcall	EE_READ					;Load v_set from EEPROM.
	mov		v_set,DataL
	ldi		Temp0,high(aset_ee)
	ldi		Temp1,low(aset_ee)
	rcall	EE_READ					;Load a_set from EEPROM.
	mov		a_set,DataL
	rcall	DISPLAY
	mov		v_disp,v_set
	mov		a_disp,a_set
	clr		Count
	set_loop:
	rcall	wr_v
	rcall	wr_a
	rcall	wr_string
	rcall	WAIT100ms
	rcall	WAIT100ms
	rcall	blk_v
	rcall	blk_a
	rcall	wr_string
	rcall	WAIT100ms
	rcall	WAIT100ms
	inc		Count
	cpi		Count,8
	brlo	set_loop

	rcall	DISPLAY

	sei								;Enable interrupts.