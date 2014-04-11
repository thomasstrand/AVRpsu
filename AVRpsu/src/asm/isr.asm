;********************************************************************
;*																	*
;*					Interrupt Service Routines						*
;*																	*
;********************************************************************

ADC_DON:
;Interrupt routine for ADC conversion complete.
	in		sreg_tmp,SREG
	push	Temp0
	push	Temp1
	push	DataL
	push	DataH


	in		DataL,ADCL
	in		DataH,ADCH
	cpi		DataH,255
	breq	no_roundup				;If result=255 then we will not round up.
	sbrc	DataL,7					;Round result up if ADCL=>2,
	inc		DataH

	no_roundup:
	sbis	ADMUX,MUX0
	rjmp	ampere					;If ampere is measured, update ampere.
	volt:							;Else update volt.
	mov		v_meas,DataH
	rjmp	adc_ret
	ampere:
	mov		a_meas,DataH
	adc_ret:
	in		Temp0,ADMUX				;Copy ADMUX register.
	ldi		Temp1,0x01
	eor		Temp0,Temp1				;Invert MUX0 bit. Will toggle between ADC6/7.
	out		ADMUX,Temp0

	rcall	DISPLAY

	pop		DataH
	pop		DataL
	pop		Temp1
	pop		Temp0
	out		SREG,sreg_tmp
	reti

EXT_INT0:
;Interrupt routine for SET key.
;Is executed when SET key is pressed.
	in		sreg_tmp,SREG
	push	Temp0
	push	Temp1
	push	DataL
	clr		hold_count
	holds_loop:
	rcall	WAIT10ms				;Eliminate bounces.
	sbic	PIND,SET_K				;If key is still pressed then continue.
	rjmp	s_short					;Else interpret key push as short.
	inc		hold_count
	sbrs	hold_count,5
	rjmp	holds_loop				;If less than 32 rounds have passed then repeat.

	s_long:							;SET key pushed a long time.
	tst		MODE
	breq	enter_smenu				;If entering from normal mode then enter SET menu.
	clr		MODE					;Else exit SET menu.
	mov		DataL,baudrate
	ldi		Temp0,high(uart_ee)
	ldi		Temp1,low(uart_ee)
	rcall	EE_WRITE				;Write baudrate to EEPROM.
	rcall	SET_BAUD
	clr		XH
	ldi		XL,(f_start)
	ldi		Temp0,high(fan_ee)
	ldi		Temp1,low(fan_ee)
	ld		DataL,X+				;Load f_start from SRAM.
	rcall	EE_WRITE				;Write f_start to EEPROM.
	ldi		Temp0,high(fan_ee+1)
	ldi		Temp1,low(fan_ee+1)
	ld		DataL,X					;Load f_stop from SRAM
	rcall	EE_WRITE				;Write f_stop to EEPROM,
	rjmp	int0_ret
	enter_smenu:
	ldi		MODE,3					;MODE=3.
	ldi		Temp0,high(uart_ee)
	ldi		Temp1,low(uart_ee)
	rcall	EE_READ					;Read baudrate from EEPROM.
	mov		baudrate,DataL
	ldi		Temp0,high(fan_ee)
	ldi		Temp1,low(fan_ee)
	rcall	EE_READ					;Read f_start from EEPROM.
	clr		XH
	ldi		XL,(f_start)
	st		X+,DataL				;Store f_start to SRAM.
	ldi		Temp0,high(fan_ee+1)
	ldi		Temp1,low(fan_ee+1)
	rcall	EE_READ					;Read f_stop from EEPROM.
	st		X,DataL					;Store f_stop to SRAM.
	rjmp	int0_ret

	s_short:						;SET key pushed a short time.
	inc		MODE
	cpi		MODE,3
	breq	clr_mode				;If MODE=set_a then MODE=normal.
	cpi		MODE,6
	breq	com_mode				;If MODE=set_fstop then MODE=set_com.
	rjmp	int0_ret

	com_mode:
	ldi		MODE,3
	rjmp	int0_ret

	clr_mode:
	clr		MODE
	ldi		Temp0,high(vset_ee)
	ldi		Temp1,low(vset_ee)
	mov		DataL,v_set
	rcall	EE_WRITE				;Write v_set to EEPROM.
	ldi		Temp0,high(aset_ee)
	ldi		Temp1,low(aset_ee)
	mov		DataL,a_set
	rcall	EE_WRITE				;Write a_set to EEPROM.

	int0_ret:
	rcall	DISPLAY
	rcall	WAIT10ms
	skey_release:
	sbis	PIND,SET_K
	rjmp	skey_release

	rcall	WAIT10ms

	pop		DataL
	pop		Temp1
	pop		Temp0
	out		SREG,sreg_tmp
	reti

EXT_INT1:
;Interrupt routine for OUTPUT key.
;Executed when OUTPUT key is pressed.
	in		sreg_tmp,SREG
	push	Temp0
	clr		hold_count
	holdo_loop:
	rcall	WAIT10ms				;Eliminate bounces.
	sbic	PIND,OUT_K				;If key is still pressed then continue.
	rjmp	o_short					;Else interpret key push as short.
	inc		hold_count
	sbrs	hold_count,5
	rjmp	holdo_loop				;If less than 32 rounds have passed then repeat.

	o_long:							;OUTPUT key pressed for a long time.
	tst		MODE
	breq	enter_omenu				;If MODE=0 then enter OUTPUT menu.
	clr		MODE					;Else exit OUTPUT menu.
	rjmp	int1_ret

	enter_omenu:
	ldi		MODE,6					;Enter the view_temp mode.
	rjmp	int1_ret

	o_short:						;OUTPUT key pressed for a short time.
	cbr		STAT,(1<<USART_CR)		;Clear USART Command Received flag.
	ldi		Temp0,(1<<ON)
	eor		STAT,Temp0				;Invert the ON flag.

	int1_ret:
	rcall	DISPLAY
	rcall	WAIT10ms
	okey_release:
	sbis	PIND,OUT_K
	rjmp	okey_release

	rcall	WAIT10ms
	pop		Temp0
	out		SREG,sreg_tmp
	reti

TIM0_OVF:
;Interrupt routine for Timer0 overflow.
;Happens every 23.7ms.
	in		sreg_tmp,SREG
	push	Temp0
;adc
	inc		adc_count
	mov		Temp0,adc_count
	cpi		Temp0,3
	brlo	skip_adc
	clr		adc_count
	sbi		ADCSR,ADSC				;Start ADC conversion.
	skip_adc:

;relay								;The relay should respond almost immidately when activated,
	sbrs	STAT,0					;but slow when deactivated.
	rjmp	rel_ret					;If output is off then skip relay.

	mov		Temp0,v_meas
	cpi		Temp0,135
	brsh	set_relay				;If measured voltage=>13.5V then activate relay.
	cpi		Temp0,125
	brlo	clr_relay				;If measured voltage<12.5V then deactivate relay.
	clr		rel_count
	rjmp	rel_ret
	set_relay:
	sbi		PORTC,RELAY				;Activate relay.
	clr		rel_count				;Clear the relay counter.
	rjmp	rel_ret
	clr_relay:
	inc		rel_count				;Increment relay counter.
	mov		Temp0,rel_count			;Check how long since last change.
	cpi		Temp0,200				;Relay response time (n*23.7ms).
	brlo	rel_ret					;If it is too soon then exit.
	cbi		PortC,RELAY				;Else deactivate the relay.
	clr		rel_count
	rel_ret:

;display flashing
	inc		ms_count
	cpi		ms_count,8				;Determines flash speed of parameter being adjusted .
	brlt	tim0_ret				;If less then exit (this test is signed).

	clr		ms_count
	ldi		Temp0,(1<<FLASH)		;Invert FLASH bit.
	eor		STAT,Temp0
	rcall	DISPLAY

;temperature
	rcall	MEAS_T					;Start a temperature conversion.
	rcall	FANS					;Start/stop fans.
	clr		XH
	ldi		XL,(t_meas)
	ld		Temp0,X					;Load t_meas from SRAM.
	cpi		Temp0,180				;Check for overtemperature. 180 means 90 degrees C.
	brlo	tim0_ret
	over_temp:						;Overtemperature.
	cbr		STAT,(1<<ON)			;Switch output off.
	rcall	wr_output
	sbi		PORTC,FAN				;Start fans.
	clr_z:
	ldi		ZH,high(disp_str+16)
	ldi		ZL,low(disp_str+16)
	overt_loop:
	rcall	LCD_SMSG				;Write OVERHEATING message to display.
	rcall	WAIT100ms
	rcall	WAIT100ms
	adiw	ZH:ZL,1					;Shift display one step left.
	cpi		ZL,0xA0
	brsh	clr_z
	rcall	MEAS_T					;Update temperature measurement.
	clr		XH
	ldi		XL,(t_meas)
	ld		Temp0,X					;Temp0=t_meas.
	cpi		Temp0,80
	brlo	tim0_ret				;Check if things have cooled down to below 40 degrees C.
	rjmp	overt_loop
	tim0_ret:
	pop		Temp0
	out		SREG,sreg_tmp
	reti

USART_RXC:
;Interrupt routine for USART Receive Completed.
	in		sreg_tmp,SREG
	push	Temp0
	push	DataL

	in		Temp0,UDR

	cpi		Temp0,0x1B
	breq	usart_rxret				;If ESC then return.

	usart_v:						;Set voltage.
	cpi		Temp0,'V'
	brne	usart_a
	rcall	RECV_BYT				;Receive voltage value.
	cpi		DataL,251
	brsh	usart_ill				;Exclude illegal values.
	sbr		STAT,(1<<USART_CR)		;Set the USART Command Received flag.
	mov		v_set,DataL
	ldi		DataL,13
	rcall	SEND_BYT				;Reply with a CR.
	rjmp	usart_rxret

	usart_a:						;Set current.
	cpi		Temp0,'A'
	brne	out_on
	rcall	RECV_BYT				;Receive current value.
	cpi		DataL,251
	brsh	usart_ill				;Exclude illegal values.
	sbr		STAT,(1<<USART_CR)		;Set the USART Command Received flag.
	mov		a_set,DataL
	ldi		DataL,13
	rcall	SEND_BYT				;Reply with a CR.
	rjmp	usart_rxret

	out_on:							;Output ON.
	cpi		Temp0,'O'
	brne	out_off
	ldi		DataL,13
	rcall	SEND_BYT
	sbr		STAT,(1<<USART_CR)		;Set the USART Command Received flag.
	sbr		STAT,(1<<ON)
	rjmp	usart_rxret

	out_off:						;Output OFF.
	cpi		Temp0,'o'
	brne	return_dis
	ldi		DataL,13
	rcall	SEND_BYT
	sbr		STAT,(1<<USART_CR)		;Set the USART Command Received flag.
	cbr		STAT,(1<<ON)
	rjmp	usart_rxret

	return_dis:						;Return Display String.
	cpi		Temp0,'d'
	brne	usart_ill
	clr		XH
	ldi		XL,0x60					;Start of display string.
	sbi		UCSRB,UDRIE				;Enable UDR interrupt. This will start transmission.
	rjmp	usart_rxret

	usart_ill:						;Illegal command.
	ldi		DataL,'?'
	rcall	SEND_BYT
	rjmp	usart_rxret

	usart_rxret:
	rcall	DISPLAY
	pop		DataL
	pop		Temp0
	out		SREG,sreg_tmp
	reti

USART_UDRE:
;USART Data Register Empty.
	in		sreg_tmp,SREG
	push	DataL
	cpi		XL,0x70
	brsh	tx_done
	ld		DataL,X+
	out		UDR,DataL
	rjmp	usart_udrret
	tx_done:
		cbi		UCSRB,UDRIE			;Disable DRE Interrupt.
		clr		DataL
		rcall	SEND_BYT			;Send a zero at the end.
	usart_udrret:
	pop		DataL
	out		SREG,sreg_tmp
	reti
