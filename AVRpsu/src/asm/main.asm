.include "m8def.inc"
.include "boot.asm"

;register definitions
;.def		ledig		= r0
;.def		ledig		= r1
.def		v_meas		= r2
.def		a_meas		= r3
.def		v_disp		= r4
.def		a_disp		= r5
.def		sreg_tmp	= r6
.def		rot_val		= r7
.def		ROT			= r8
.def		rel_count	= r9
.def		baudrate	= r10
.def		hold_count	= r11
.def		adc_count	= r12
.def		v_set		= r13
.def		a_set		= r14
;.def		ledig		= r15

.def		Temp0		= r16
.def		Temp1		= r17
.def		Temp2		= r18
.def		POS			= r19
.def		DataL		= r20
.def		DataH		= r21
.def		Count		= r22
.def		MODE		= r23
.def		STAT		= r24
.def		ms_count	= r25

;hardware
.equ		E			= 5
.equ		RS			= 4
.equ		CLK			= 7
.equ		D			= 6
.equ		ROT_A		= 4
.equ		ROT_B		= 5
.equ		SET_K		= 2
.equ		OUT_K		= 3

.equ		RELAY		= PC0
.equ		FAN			= PC1
.equ		T_SENS		= PC2

;STAT register
.equ		ON			= 0
.equ		FLASH		= 1
.equ		USART_CR	= 2

;memory reservations
.dseg
.org 0x60
disp_str:							;SRAM space.
.byte 80

t_meas:
.byte 1

f_start:
.byte 1

f_stop:
.byte 1

.eseg								;EEPROM space for settings.
.org 0x00

vset_ee:							;One byte for v_set.
.byte 1

aset_ee:							;One byte for a_set.
.byte 1

uart_ee:							;One byte for USART baud rate.
.byte 1

fan_ee:								;Two bytes for fan start and stop temperatures.
.byte 2

.cseg								;Actual code starts here.
.org 0x000
rjmp		APP						;These are reset and interrupt vectors.
rjmp		EXT_INT0				;Refer to page 45 in data sheet for details.
rjmp		EXT_INT1
nop			;rjmp		TIM2_COMP
nop			;rjmp		TIM2_OVF
nop			;rjmp		TIM1_CAPT
nop			;rjmp		TIM1_COMPA
nop			;rjmp		TIM1_COMPB
nop			;rjmp		TIM1_OVF
rjmp		TIM0_OVF
nop			;rjmp		SPI_STC
rjmp		USART_RXC
rjmp		USART_UDRE
nop			;rjmp		USART_TXC
rjmp		ADC_DON
nop			;rjmp		EE_RDY
nop			;rjmp		ANA_COMP
nop			;rjmp		TWSI
nop			;rjmp		SPM_RDY


;********************************************************************
.include "init.asm"
;********************************************************************


;********************************************************************
;*																	*
;*							Main program							*
;*																	*
;********************************************************************

MAIN:
	tst		MODE
	breq	MAIN					;If normal mode then try again.

	rcall	RE_ROT					;Read Rotary Encoder.
	tst		rot_val
	breq	MAIN					;If it hasn't moved then look again.

adj_v:								;Adjust volt.
	cpi		MODE,1
	brne	adj_a
	mov		Temp0,v_set
	cpi		Temp0,250
	breq	v_top
	cpi		Temp0,0
	breq	v_bottom
	rjmp	v_ok
		v_top:
		sbrs	rot_val,7			;Allow only negative rotation when at top.
		clr		rot_val
		rjmp	v_ok
		v_bottom:
		sbrc	rot_val,7			;Allow only positive rotation when at bottom.
		clr		rot_val
	v_ok:
	cbr		STAT,(1<<USART_CR)		;Clear USART Command Received flag.
	add		v_set,rot_val			;Update v_disp according to rotation.
	out		OCR1AL,v_set			;Update PWM register with setpoint value.
	mov		v_disp,v_set			;Update voltage value in display.
	mov		a_disp,a_meas			;Update a_disp with ADC measurement.
	cbr		STAT,(1<<FLASH)			;Clear FLASH so that voltage digits appear.
	ldi		ms_count,-8				;Stop flashing for a while.
	rcall	DISPLAY
	rjmp	MAIN

adj_a:								;Adjust ampere.
	cpi		MODE,2
	brne	adj_com
	mov		Temp0,a_set
	cpi		Temp0,250
	breq	a_top
	cpi		Temp0,0
	breq	a_bottom
	rjmp	a_ok
		a_top:
		sbrs	rot_val,7			;Allow only negative rotation when at top.
		clr		rot_val
		rjmp	a_ok
		a_bottom:
		sbrc	rot_val,7			;Allow only positive rotation when at bottom.
		clr		rot_val
	a_ok:
	cbr		STAT,(1<<USART_CR)		;Clear USART Command Received flag.
	add		a_set,rot_val			;Update a_disp according to rotation.
	out		OCR1BL,a_set			;Update PWM register.
	mov		a_disp,a_set			;Update ampere value in display.
	mov		v_disp,v_meas			;Update v_disp with ADC measurement.
	cbr		STAT,(1<<FLASH)			;Clear FLASH so that ampere digits appear.
	ldi		ms_count,-8				;Stop flashing for a while.
	rcall	DISPLAY
	rjmp	MAIN

adj_com:							;Adjust serial port baudrate.
	cpi		MODE,3
	brne	adj_fstart
	mov		Temp0,baudrate
	cpi		Temp0,9
	brsh	com_top
	cpi		Temp0,0
	breq	com_bottom
	rjmp	com_ok
		com_top:
		sbrs	rot_val,7
		clr		rot_val
		rjmp	com_ok
		com_bottom:
		sbrc	rot_val,7
		clr		rot_val
	com_ok:
	add		baudrate,rot_val
	cbr		STAT,(1<<FLASH)
	ldi		ms_count,-8
	rcall	DISPLAY
	rjmp	MAIN

adj_fstart:							;Adjust fan start temperature.
	cpi		MODE,4
	brne	adj_fstop
	clr		XH
	ldi		XL,(f_start)
	ld		Temp0,X+				;Temp0=f_start.
	ld		Temp1,X					;Temp1=f_stop.
	subi	Temp1,254				;f_stop=f_stop+2.
	cpi		Temp0,240				;Upper limit is 120 deg C.
	brsh	fstart_top
	cp		Temp0,Temp1
	breq	fstart_bottom			;Lower limit is f_stop+1 degrees.
	rjmp	fstart_ok
		fstart_top:
		sbrs	rot_val,7
		clr		rot_val
		rjmp	fstart_ok
		fstart_bottom:
		sbrc	rot_val,7
		clr		rot_val
	fstart_ok:
	add		Temp0,rot_val
	ldi		XL,(f_start)
	st		X,Temp0					;Store new f_start to SRAM.
	cbr		STAT,(1<<FLASH)
	ldi		ms_count,-8
	rcall	DISPLAY
	rjmp	MAIN

adj_fstop:							;Adjust fan stop temperature.
	cpi		MODE,5
	brne	none
	clr		XH
	ldi		XL,(f_start)
	ld		Temp1,X+				;Temp1=f_start.
	ld		Temp0,X					;Temp0,f_stop.
	subi	Temp1,2					;f_start=f_start-2
	cp		Temp0,Temp1
	brsh	fstop_top				;Lower limit is f_start+1 deg.
	cpi		Temp0,60				;Upper limit is 30 degrees.
	breq	fstop_bottom
	rjmp	fstop_ok
		fstop_top:
		sbrs	rot_val,7
		clr		rot_val
		rjmp	fstop_ok
		fstop_bottom:
		sbrc	rot_val,7
		clr		rot_val
	fstop_ok:
	add		Temp0,rot_val
	ldi		XL,(f_stop)
	st		X,Temp0
	cbr		STAT,(1<<FLASH)
	ldi		ms_count,-8
	rcall	DISPLAY

none:
	rjmp	MAIN

START_CHAR:
	.db		0x00,0x00,0x0E,0x15,0x1F,0x1F,0x0E,0x11	;Alien

	.db		0x03,0x07,0x06,0x0E,0x0F,0x1C,0x1C,0x00	;AVR logo.
	.db		0x1B,0x1D,0x0D,0x0E,0x1E,0x07,0x07,0x00
	.db		0x00,0x11,0x11,0x1B,0x1B,0x0E,0x0E,0x04
	.db		0x1B,0x16,0x16,0x0F,0x0E,0x1C,0x1C,0x00
	.db		0x1E,0x07,0x07,0x1E,0x18,0x0C,0x0C,0x00

	.db		0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.db		0xFF,0xFF

ALIEN:
	.db		0x00,0x00,0x02,0x04,0x0E,0x15,0x1F,0x0E	;Frame0
	.db		0x00,0x04,0x04,0x0E,0x15,0x1F,0x1F,0x0E
	.db		0x08,0x04,0x0E,0x15,0x1F,0x11,0x0E,0x00
	.db		0x10,0x08,0x0E,0x15,0x1F,0x1F,0x0E,0x00
	.db		0x08,0x04,0x0E,0x15,0x1F,0x11,0x0E,0x00
	.db		0x04,0x04,0x0E,0x15,0x1F,0x1F,0x0E,0x00
	.db		0x02,0x04,0x0E,0x15,0x1F,0x11,0x0E,0x00
	.db		0x00,0x01,0x02,0x0E,0x15,0x1F,0x1F,0x0E	;Frame7

STARS:
	.db		0x10,0x00,0x00,0x04,0x01,0x08,0x02,0x00	;Frame0
	.db		0x08,0x00,0x10,0x02,0x00,0x04,0x01,0x00
	.db		0x04,0x00,0x08,0x01,0x00,0x02,0x00,0x10
	.db		0x02,0x10,0x04,0x00,0x00,0x01,0x00,0x08
	.db		0x01,0x08,0x02,0x00,0x10,0x00,0x00,0x04
	.db		0x00,0x04,0x01,0x00,0x08,0x00,0x10,0x02
	.db		0x00,0x02,0x00,0x10,0x04,0x00,0x08,0x01
	.db		0x00,0x01,0x00,0x08,0x02,0x10,0x04,0x00	;Frame7

SYS_CHAR:
	.db		0x18,0x18,0x03,0x04,0x04,0x04,0x03,0x00	;Degree C character.
	.db		0x04,0x04,0x15,0x0E,0x04,0x1F,0x1F,0x00	;Serial port icon.
	.db		0xFF,0xFF

COM_STR:
	.db		"COM  ",0," 8N1",0,0

;Text strings. All strings are zero-terminated and have to consist of an even
;number of bytes.
TEST_STR:
	.db		7,1,7,7,2,3,4,5,6,"psu",7,7,1,7,0,0

OVERHEAT_STR:
	.db		"OVERHEATING - the output has been switched off. OVERHEATING - t",0

BAUD:
	.db		"       ",0,"    300",0,"    600",0,"   1200",0,"   2400",0,"   4800",0,"   9600",0," 19 200",0," 38 400",0," 57 600",0,"115 200",0

BAUD_RATE:
	.db		0x08,0xFF,0x04,0x7F,0x02,0x3F,0x01,0x1F,0x00,0x8F,0x00,0x47,0x00,0x23,0x00,0x11,0x00,0x0B,0x00,0x05

FAN_START:
	.db		"FANstart   ",0

FAN_STOP:
	.db		"FANstop   ",0,0

TEMP_SCR:
	.db		"Temp.:    ",0,0

;********************************************************************
.include "isr.asm"
;********************************************************************


;********************************************************************
;*																	*
;*							Subroutines								*
;*																	*
;********************************************************************

.include "delay.asm"

MEAS_T:
;Starts a temperature conversion and updates t_meas when the result
;is ready.
	push	DataL
	ldi		DataL,0xCC				;Skip ROM.
	rcall	wr_tsens
	ldi		DataL,0x44				;Convert T.
	rcall	wr_tsens
	rcall	rd_tsens
	cpi		DataL,0xFF
	brne	meas_ret				;If not done yet then exit.
	rcall	t_reset
	ldi		DataL,0xCC				;Skip ROM.
	rcall	wr_tsens
	ldi		DataL,0xBE				;Read Scratchpad.
	rcall	wr_tsens
	rcall	rd_tsens				;Read Temperature LSB.
	clr		XH
	ldi		XL,(t_meas)
	st		X,DataL
	rcall	t_reset
	meas_ret:
	pop		DataL
	ret

FANS:
;Start/stop fans according to t_meas, f_start and f_stop.
	push	Temp0
	push	Temp1
	push	Temp2
	push	XL
	push	XH

	clr		XH
	ldi		XL,(t_meas)
	ld		Temp0,X+				;Temp0=t_meas.
	ld		Temp1,X+				;Temp1=f_start.
	ld		Temp2,X					;Temp2=f_stop.
	cp		Temp0,Temp1
	brsh	start_fan
	cp		Temp2,Temp0
	brsh	stop_fan
	rjmp	fans_ret
		start_fan:
		sbi		PORTC,FAN
		rjmp	fans_ret
		stop_fan:
		cbi		PORTC,FAN
	fans_ret:
	pop		XH
	pop		XL
	pop		Temp2
	pop		Temp1
	pop		Temp0
	ret

wr_tsens:							;Writes DataL byte to the Temperature sensor. 
	push	Count
	ldi		Count,8
	wt_loop:
	rcall	WAIT5us
	ror		DataL
	brcs	send1
		send0:
		cbi		PORTC,T_SENS
		sbi		DDRC,T_SENS
		rcall	WAIT100us
		cbi		DDRC,T_SENS
		rcall	WAIT5us
		rjmp	wt_loopend
		send1:
		cbi		PORTC,T_SENS
		sbi		DDRC,T_SENS
		rcall	WAIT5us
		cbi		DDRC,T_SENS
		rcall	WAIT100us
	wt_loopend:
	dec		Count
	brne	wt_loop
	pop		Count
	ret

rd_tsens:							;Reads a byte from the Temperature sensor into DataL.
	push	Count
	clr		Temp2
	ldi		Count,8
	rt_loop:
	rcall	WAIT5us
	cbi		PORTC,T_SENS
	sbi		DDRC,T_SENS
	rcall	WAIT5us
	cbi		DDRC,T_SENS
	rcall	WAIT5us
	sbis	PINC,T_SENS
		rjmp	read0
		read1:
		sec
		rjmp	rt_loopend
		read0:
		clc
	rt_loopend:
	ror		DataL
	rcall	WAIT100us
	dec		Count
	brne	rt_loop
	pop		Count
	ret

t_reset:							;Resets the Temperature sensor.
	cbi		PORTC,T_SENS
	sbi		DDRC,T_SENS
	rcall	WAIT600us				;Reset pulse.
	cbi		DDRC,T_SENS
	rcall	WAIT100us				;Wait for presence pulse.
	wait_pre:
	sbic	PINC,T_SENS
	rjmp	wait_pre
	rcall	WAIT600us
	sbi		PORTC,T_SENS
	sbi		DDRC,T_SENS
	ret

EE_READ:
;Read byte from EEPROM into DataL.
;Adress must be written to Temp0:Temp1 before call.
	sbic	EECR,EEWE
	rjmp	EE_READ
	out		EEARH,Temp0
	out		EEARL,Temp1
	sbi		EECR,EERE
	in		DataL,EEDR
	ret

EE_WRITE:
;Write byte to EEPROM from DataL.
;Adress must be written to Temp0:Temp1 before call.
	sbic	EECR,EEWE
	rjmp	EE_WRITE
	out		EEARH,Temp0
	out		EEARL,Temp1
	out		EEDR,DataL
	sbi		EECR,EEMWE
	sbi		EECR,EEWE
	ret

RECV_BYT:
;Receives a byte from USART into DataL.
	sbis	UCSRA,RXC
	rjmp	recv_byt
	in		DataL,UDR
	ret

SEND_BYT:
;Sends a byte to USART from DataL.
	sbis	UCSRA,UDRE
	rjmp	send_byt
	out		UDR,DataL
	ret

FLUSH_USART:
;Flush the USART Receiver buffer.
	sbis	UCSRA,RXC
	ret
	in		Temp0,UDR
	rjmp	FLUSH_USART

SET_BAUD:
;Set Baud Rate according to baudrate.
	push	Temp0
	push	Temp1

	ldi		Temp0,(0<<RXEN)|(0<<TXEN)|(0<<RXCIE)
	out		UCSRB,Temp0				;Disable receiver and transmitter.
	clr		Temp0
	mov		Temp1,baudrate
	ldi		ZH,high(BAUD_RATE*2)
	ldi		ZL,low(BAUD_RATE*2)
	lsl		Temp1
	add		ZL,Temp1
	adc		ZH,Temp0
	lpm		Temp0,Z+
	out		UBRRH,Temp0
	lpm		Temp0,Z
	out		UBRRL,Temp0
	ldi		Temp0,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
	out		UCSRB,Temp0				;Re-enable receiver and transmitter.

	pop		Temp1
	pop		Temp0
	ret

;********************************************************************
.include "lcd.asm"
;********************************************************************

BIN2BCD:
;Converts the hex value in DataL to BCD.
;Output in ASCII code to Temp0, Temp1 and Temp2. MSD - LSD.
	push	DataL
	push	DataH
	push	Count

	ldi		Count,0x30				;Offset for ASCII codes.
	clr		Temp0
	clr		Temp1					;Clear output variables.
	clr		Temp2

	sub100:	
		subi	DataL,100
		brcs	don1 				;If result is negative then goto don1.
		inc		Temp0				;Else increment Temp0
		rjmp	sub100
		don1:
		subi	DataL,156			;Restore corruption.

	sub10:	
		subi	DataL,10
		brcs	don2				;If result is negative then done.
		inc		Temp1
		rjmp	sub10
		don2:
		subi	DataL,246			;Restore corruption.
	
	mov		Temp2,DataL				;The rest is ones.

	add		Temp0,Count
	add		Temp1,Count				;Convert to ASCII.
	add		Temp2,Count

	pop		Count
	pop		DataH
	pop		DataL
	ret

RE_ROT:
;Read Rotary Encoder.
;Reads the rotary encoder and returns -1, 0 or 1 in rot_val.
;Note that the uC is trapped in this routine while ROT_A is static,
;except for Interrupt Service Routines.
	push	Temp0
	clr		rot_val
	in		Temp0,PIND
	andi	Temp0,0b00110000
	cp		Temp0,ROT				;Check if it has rotated.
	breq	rot_ret					;If not then return.
	rcall	WAIT1ms
	
	a_flk:
	sbic	PinD,ROT_A				;Wait for ROT_A falling edge.
	rjmp	a_flk
	rcall	WAIT1ms					;Wait to eliminate bounces.

	sbis	PIND,ROT_B
	dec		rot_val					;Counter-clockwise.				
	sbic	PIND,ROT_B
	inc		rot_val					;Clockwise.

	rot_end:
	sbis	Pind,ROT_A				;Wait for ROT_A to go high again.
	rjmp	rot_end
	rcall	WAIT1ms
	in		Temp0,PIND
	andi	Temp0,0b00110000
	mov		ROT,Temp0				;Update ROT with new state.

	rot_ret:
	pop		Temp0
	ret

RES_T0:
;Reset Timer0 and its prescaler.
	push	Temp0

	in		Temp0,SFIOR
	ori		Temp0,0x01				;Set the PSR10 bit in SFIOR.
	out		SFIOR,Temp0				;This will clear the Timer0 prescaler.
	clr		Temp0
	out		TCNT0,Temp0				;Clear Timer0.
	clr		ms_count

	pop		Temp0
	ret

DISPLAY:
;Updates disp_str in SRAM according to STAT and MODE.
;Then prints disp_str to display. Also updates PWM registers.
	push	Temp0
	push	Temp1
	push	Temp2
	push	DataL
	push	DataH

	cpi		MODE,0					;Jump according to MODE .
	brne	set_v
norm:
	mov		v_disp,v_meas			;Write measured voltage to string.
	rcall	wr_v
	mov		a_disp,a_meas			;Write measured current to string.
	rcall	wr_a
	rcall	wr_output
	rjmp	mode2_ret

set_v:
	cpi		MODE,1
	brne	set_a
	mov		v_disp,v_set			;Wanted voltage to string.
	mov		a_disp,a_meas			;Measured current to string.
	rcall	wr_a
	sbrc	STAT,FLASH
	rcall	blk_v					;If FLASH is set then blank voltage field.
	sbrs	STAT,FLASH
	rcall	wr_v					;If FLASH is clear then write wanted voltage.
	rcall	WR_OUTPUT
	rjmp	mode2_ret

set_a:
	cpi		MODE,2
	brne	com_adj
	mov		v_disp,v_meas			;Measured voltage to string.
	mov		a_disp,a_set			;Wanted current to string.
	rcall	wr_v
	sbrc	STAT,FLASH
	rcall	blk_a					;If FLASH is set then blank current field.
	sbrs	STAT,FLASH
	rcall	wr_a					;If FLASH is clear then write wanted current.
	rcall	WR_OUTPUT

	mode2_ret:
	rcall	wr_string
	rjmp	display_ret

com_adj:							;Write COM menu.
	cpi		MODE,3
	brne	set_fstart
	ldi		POS,0
	ldi		ZH,high(COM_STR*2)
	ldi		ZL,low(COM_STR*2)
	rcall	LCD_FMSG

	wr_baud:
	mov		Temp0,baudrate
	inc		Temp0					;First element in BAUD table is spaces.
	sbrc	STAT,FLASH				;If FLASH is set then load first element (space).
	clr		Temp0
	clr		Temp1
	ldi		POS,5
	lsl		Temp0
	lsl		Temp0
	lsl		Temp0
	ldi		ZH,high(BAUD*2)
	ldi		ZL,low(BAUD*2)
	add		ZL,Temp0
	adc		ZH,Temp1
	rcall	LCD_FMSG
	ldi		POS,12
	ldi		ZH,high((COM_STR+3)*2)
	ldi		ZL,low((COM_STR+3)*2)
	rcall	LCD_FMSG
	rjmp	display_ret

set_fstart:
	cpi		MODE,4
	brne	set_fstop
	ldi		POS,0
	ldi		ZH,high(FAN_START*2)
	ldi		ZL,low(FAN_START*2)
	rcall	LCD_FMSG
	ldi		POS,10
	clr		XH
	ldi		XL,(f_start)
	ld		DataL,X					;load f_start from SRAM.
	sbrc	STAT,FLASH
	clr		DataL					;If FLASH bit is set then write spaces.
	rcall	wr_temp
	ldi		POS,15
	rcall	LCD_CUR
	ldi		DataL,0x01
	rcall	LCD_RAM					;Write degree C icon.
	rjmp	display_ret

set_fstop:
	cpi		MODE,5
	brne	view_temp
	ldi		POS,0
	ldi		ZH,high(FAN_STOP*2)
	ldi		ZL,low(FAN_STOP*2)
	rcall	LCD_FMSG
	ldi		POS,10
	clr		XH
	ldi		XL,(f_stop)
	ld		DataL,X					;Load f_stop from SRAM.
	sbrc	STAT,FLASH
	clr		DataL					;If FLASH bit is set then write spaces.
	rcall	wr_temp
	ldi		POS,15
	rcall	LCD_CUR
	ldi		DataL,0x01
	rcall	LCD_RAM					;Write degree C icon.
	rjmp	display_ret

view_temp:
	cpi		MODE,6
	brne	display_ret
	ldi		POS,0
	ldi		ZH,high(TEMP_SCR*2)
	ldi		ZL,low(TEMP_SCR*2)
	rcall	LCD_FMSG
	clr		XH
	ldi		XL,(t_meas)
	ld		DataL,X					;Load t_meas from SRAM.
	ldi		POS,10
	rcall	wr_temp
	ldi		POS,15
	rcall	LCD_CUR
	ldi		DataL,0x01
	rcall	LCD_RAM					;Write degree C icon.

	display_ret:
	pop		DataH
	pop		DataL
	pop		Temp2
	pop		Temp1
	pop		Temp0
	ret

;********************************************************************

wr_string:
	ldi		ZH,high(disp_str)
	ldi		ZL,low(disp_str)		;Load start adress of disp_str
	rcall	LCD_SMSG				;and write disp_str to display
	ret

wr_temp:
;Write Temperature stored in DataL from cursor position POS.
;Has zero blanking for hundreds digit.
;If DataL=0 then spaces will be written. 
	push	Temp0
	push	Temp1
	push	Temp2
	push	DataH
	rcall	LCD_CUR
	tst		DataL
	breq	spaces
	lsr		DataL
	brcs	set5
	ldi		DataH,'0'
	rjmp	set0
	set5:
	ldi		DataH,'5'
	set0:
	rcall	BIN2BCD
	ldi		POS,8
	cpi		Temp0,'0'
	brne	no_tblank
	ldi		Temp0,' '
	no_tblank:
	mov		DataL,Temp0
	rcall	LCD_RAM
	mov		DataL,Temp1
	rcall	LCD_RAM
	mov		DataL,Temp2
	rcall	LCD_RAM
	ldi		DataL,'.'
	rcall	LCD_RAM
	mov		DataL,DataH
	rcall	LCD_RAM
	rjmp	temp_ret
	spaces:
		ldi		DataL,' '
		rcall	LCD_RAM
		rcall	LCD_RAM
		rcall	LCD_RAM
		rcall	LCD_RAM
		rcall	LCD_RAM
	temp_ret:
	pop		DataH
	pop		Temp2
	pop		Temp1
	pop		Temp0
	ret

wr_v:
;Write Voltage.
;Converts the value in v_disp to BCD and updates voltage field in disp_str.
	push	DataL					;Store variables.
	push	Temp0
	push	Temp1
	push	Temp2

	mov		DataL,v_disp
	rcall	BIN2BCD					;Convert to BCD.
	cpi		Temp0,'0'
	brne	no_vblank
	ldi		Temp0,' '				;Leading zero blanking.
	no_vblank:
	ldi		DataL,'.'
	sts		0x60,Temp0
	sts		0x61,Temp1
	sts		0x62,DataL
	sts		0x63,Temp2
	ldi		DataL,'V'
	sts		0x64,DataL
	ldi		DataL,' '
	sts		0x65,DataL
	sts		0x66,DataL

	pop		Temp2
	pop		Temp1
	pop		Temp0
	pop		DataL					;Restore variables.
	ret

wr_a:
;Write Ampere.
;Converts the value in a_disp to BCD and updates ampere field in disp_str.
	push	DataL					;Store variables.
	push	Temp0
	push	Temp1
	push	Temp2

	ldi		DataL,' '
	sts		0x6A,DataL
	mov		DataL,a_disp			;Copy a_disp to DataL.
	rcall	BIN2BCD					;Convert to BCD.
	ldi		DataL,'.'
	sts		0x6B,Temp0
	sts		0x6C,DataL
	sts		0x6D,Temp1
	sts		0x6E,Temp2
	ldi		DataL,'A'
	sts		0x6F,DataL

	pop		Temp2
	pop		Temp1
	pop		Temp0
	pop		DataL					;Restore variables.
	ret

blk_v:
;Blank Volt.
;Blanks out the voltage field in disp_str.
	push	DataL

	ldi		DataL,' '				;Write spaces in the voltage field.
	sts		0x60,DataL
	sts		0x61,DataL
	sts		0x62,DataL
	sts		0x63,DataL

	pop		DataL
	ret

blk_a:
;Blank Ampere.
;Blanks out the ampere field in disp_str.
	push	DataL

	ldi		DataL,' '
	sts		0x6B,DataL
	sts		0x6C,DataL
	sts		0x6D,DataL
	sts		0x6E,DataL

	pop		DataL
	ret

wr_output:
	push	DataL
	push	Temp0

	sbrc	STAT,USART_CR			;Check if commands have been received through
	rjmp	wr_remote				;the serial port.
	sbrs	STAT,USART_CR
	rjmp	wr_local
	wr_remote:
		ldi		DataL,0x02			;Write the serial port icon.
		sts		0x66,DataL
		rjmp	cont_ret
	wr_local:
		ldi		DataL,' '
		sts		0x66,DataL
	cont_ret:

	sbrc	STAT,ON					;Write CV, CC or OFF in middle of string. Done in all default modes menus.
	rjmp	wr_on					;If ON flag is set then write 'CV' or 'CC'.

	wr_off:							;Else write 'OFF' and turn output off.
	clr		Temp0					;Load both PWM's with zero.
	out		OCR1AL,Temp0			;Will effectively turn the output off.
	out		OCR1BL,Temp0
	ldi		DataL,'O'
	sts		0x67,DataL
	ldi		DataL,'F'				;Write 'OFF'.
	sts		0x68,DataL
	sts		0x69,DataL
	rjmp	on_ret

	wr_on:							;Turn output on and write 'on' state.
	out		OCR1AL,v_set			;Load PWM's with setvalues, will turn ouput on.
	out		OCR1BL,a_set			
	ldi		DataL,'C'
	sts		0x67,DataL				;Write a 'C' first. Will be followed by 'C' or 'V'.

	cp		v_meas,v_set			;Compare wanted voltage with measured voltage.
	brsh	wr_cv					;If equal then write 'CV'.
	
	ldi		DataL,'C'				;Else write 'CC'.
	sts		0x68,DataL
	ldi		DataL,' '				;Write a space, in case 'OFF' was displayed
	sts		0x69,DataL				;previously.
	rjmp	on_ret
	wr_cv:
	ldi		DataL,'V'
	sts		0x68,DataL
	ldi		DataL,' '				;Write a space, in case 'OFF' was displayed
	sts		0x69,DataL				;previously.
	on_ret:
	pop		Temp0
	pop		DataL
	ret
