;********************************************************************
;*																	*
;*							Boot Loader								*
;*																	*
;* This is a boot loader for the AVR109 protocol.					*
;* 																	*
;********************************************************************

.include "m8def.inc"

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

.def		din			= r24		;Data in.
.def		dout		= r25		;Data out.

.def		AL			= r28		;Adress low.
.def		AH			= r29		;Adress high.

;display
.equ		E			= 5
.equ		RS			= 4
.equ		CLK			= 7
.equ		D			= 6
.equ		ROT_A		= 4
.equ		ROT_B		= 5
.equ		SET_K		= 2
.equ		OUT_K		= 3

.cseg
.org 0x000
main:

.org THIRDBOOTSTART					;0xE00

;************************ Initialization ****************************

;Stack pointer.
	ldi		Temp0,high(RAMEND)		;Set Stack Pointer to top of RAM.
	out		SPH,Temp0
	ldi		Temp0,low(RAMEND)
	out		SPL,Temp0

;Ports.
	ldi		Temp0,0b00000110		;PortB Data Direction.
	out		DDRB,Temp0				;Bits 1 and 2 are outputs (PWM), the rest are inputs.
	ldi		Temp0,0b00111000
	out		PortB,Temp0				;Enable Pull-up on pins 3,4 and 5.

	ldi		Temp0,0b00111011		;PortC Data Direction. PortC is only 7 bits wide!
	out		DDRC,Temp0				;Bits 2 and 6 are inputs, the rest are outputs.
	ldi		Temp0,0b0000100
	out		PortC,Temp0				;Enable pull-up on pin 2.

	ldi		Temp0,0b11000010		;PortD Data Direction.
	out		DDRD,Temp0				;Bits 1, 6 and 7 are outputs, the rest are inputs.
	ldi		Temp0,0b00110100
	out		PortD,Temp0				;Enable Pull-up on pins 2,4 and 5.		

;USART.
	ldi		Temp0,(1<<RXEN)|(1<<TXEN)
	out		UCSRB,Temp0				;Enable receiver and transmitter.

	ldi		Temp0,0x86
	out		UCSRC,Temp0				;Set frame format:8data, 1stopbit, no parity.

	clr		Temp0
	out		UBRRH,Temp0
	ldi		Temp0,35				;Set baud rate=19200bps.
	out		UBRRL,Temp0

;LCD.
	ldi		Temp0,0x38				;Function Set.
	rcall	dis_cmd								
	rcall	delay100ms

	ldi		Temp0,0x38				;Function Set.
	rcall	dis_cmd								
	rcall	delay10ms

	ldi		Temp0,0x0C				;Display ON/OFF.
	rcall	dis_cmd
	rcall	delay10ms

	ldi		Temp0,0x01				;Clear Display.
	rcall	dis_cmd
	rcall	delay10ms

	ldi		Temp0,0x06				;Entry Mode
	rcall	dis_cmd
	rcall	delay10ms

;Bootcheck.
	rcall	delay10ms
	sbic	PIND,2					;Check if SET key is pressed.
	rjmp	main					;If not then goto main program.

;******************** Main Boot Loader Loop *************************

	ldi		ZH,high(boot_msg*2)
	ldi		ZL,low(boot_msg*2)
	rcall	dis_msg					;Write boot message on display.

boot_loop:
	rcall	recv_byte				;Wait for a byte to be received.

	cpi		din,0x1B				;ESC.
	breq	boot_loop

enter_prg:
	cpi		din,'P'
	brne	auto_inc
	rcall	send13
	rjmp	boot_loop

auto_inc:							;Auto Increment Adress.
	cpi		din,'a'
	brne	set_adress
	ldi		dout,'Y'
	rcall	send_byte
	rjmp	boot_loop

set_adress:							;Receive adress and copy to AH:AL.
	cpi		din,'A'
	brne	write_low
	rcall	recv_byte
	mov		AH,din
	rcall	recv_byte
	mov		AL,din
	lsl		AL						;Convert word adress to byte adress.
	rol		AH
	rcall	send13
	rjmp	boot_loop

write_low:							;Receive low data byte and copy to DataL.
	cpi		din,'c'
	brne	write_high
	rcall	recv_byte
	mov		DataL,din
	rcall	send13
	rjmp	boot_loop

write_high:							;Receive high data byte and write word to page buffer.
	cpi		din,'C'
	brne	write_page
	movw	ZH:ZL,AH:AL				;Copy adress to Z-pointer.
	rcall	recv_byte
	mov		DataH,din
	movw	r1:r0,DataH:DataL		;Copy DataH:DataL to r1:r0.
	ldi		Temp1,0x01
	rcall	do_spm					;Write page.
	adiw	AH:AL,2					;Adress=adress+2.
	rcall	send13
	rjmp	boot_loop

write_page:							;Writes the page buffer into flash memory.
	cpi		din,'m'
	brne	read_pmem
	movw	ZH:ZL,AH:AL
	ldi		Temp1,0x05
	rcall	do_spm
	rcall	enable_rww
	rcall	send13
	rjmp	boot_loop

read_pmem:							;Read Program Memory.
	cpi		din,'R'
	brne	read_dmem
	rcall	wait_spm				;Wait until previous spm is executed.
	movw	ZH:ZL,AH:AL
	lpm		DataL,Z+				;Notice adress increment!
	lpm		dout,Z+
	rcall	send_byte				;Send MSB first.
	movw	AH:AL,ZH:ZL				;Save updated adress.
	mov		dout,DataL
	rcall	send_byte				;And then LSB.
	rjmp	boot_loop

read_dmem:							;Read Data Memory (EEPROM).
	cpi		din,'d'
	brne	write_dmem
	rcall	wait_spm
	rcall	wait_ee
	out		EEARH,AH
	out		EEARL,AL
	adiw	AH:AL,1					;Adress=adress+1.
	sbi		EECR,EERE
	in		dout,EEDR
	rcall	send_byte
	rjmp	boot_loop

write_dmem:							;Write Data Memory (EEPROM).
	cpi		din,'D'
	brne	chip_erase
	rcall	wait_ee
	out		EEARH,AH
	out		EEARL,AL
	rcall	recv_byte
	out		EEDR,din
	sbi		EECR,EEMWE
	sbi		EECR,EEWE
	adiw	AH:AL,1					;Adress=adress+1.
	rcall	wait_ee
	rcall	send13
	rjmp	boot_loop

chip_erase:							;Chip Erase. Will erase all pages of application memory,
	cpi		din,'e'					;but not boot section.
	brne	leave_prg
	clr		AH
	clr		AL
	clr		Count
	erase_loop:
	movw	ZH:ZL,AH:AL
	ldi		Temp1,0x03
	rcall	do_spm
	rcall	enable_rww
	adiw	AH:AL,PAGESIZE			;Increment with pagesize in bytes, not words.
	adiw	AH:AL,PAGESIZE
	inc		Count
	cpi		Count,96				;96 pages
	brlo	erase_loop
	rcall	send13
	rjmp	boot_loop

leave_prg:							;Leave Programming Mode.
	cpi		din,'L'
	brne	select_dev
	rcall	send13
	rjmp	boot_loop

select_dev:							;Select Device Type.
	cpi		din,'T'
	brne	return_sign
	rcall	recv_byte
	rcall	send13
	rjmp	boot_loop

return_sign:						;Return Signature Bytes.
	cpi		din,'s'
	brne	return_dev
	ldi		dout,0x1E
	rcall	send_byte
	ldi		dout,0x93
	rcall	send_byte
	ldi		dout,0x07
	rcall	send_byte
	rjmp	boot_loop

return_dev:							;Return Supported Devices.
	cpi		din,'t'
	brne	return_SI
	ldi		dout,0x77				;Part code for mega8boot.
	rcall	send_byte
	clr		dout					;End list with 0x00.
	rcall	send_byte
	rjmp	boot_loop

return_SI:							;Return Software Identifier.
	cpi		din,'S'
	brne	prg_type
	ldi		dout,'A'
	rcall	send_byte
	ldi		dout,'V'
	rcall	send_byte
	ldi		dout,'R'
	rcall	send_byte
	ldi		dout,'B'
	rcall	send_byte
	ldi		dout,'O'
	rcall	send_byte
	rcall	send_byte
	ldi		dout,'T'
	rcall	send_byte
	rjmp	boot_loop

prg_type:							;Return Programmer Type.
	cpi		din,'p'
	brne	set_led
	ldi		dout,'S'
	rcall	send_byte
	rjmp	boot_loop

set_led:
	cpi		din,'x'
	brne	clr_led
	rcall	recv_byte
	rcall	send13
	rjmp	boot_loop

clr_led:
	cpi		din,'y'
	brne	unknown
	rcall	recv_byte
	rcall	send13
	rjmp	boot_loop

unknown:
	ldi		dout,'?'				;If none of the above then send a question mark.
	rcall	send_byte

	rjmp	boot_loop

;************************* Subroutines ******************************

recv_byte:
;Receive Byte. Waits until a byte is received into USART and copies
;the byte to din.
	sbis	UCSRA,RXC
	rjmp	recv_byte				;Wait until a byte is received.
	in		din,UDR				;Copy received byte to Temp0.
	ret

send_byte:
;Send Byte. Waits until the transmit buffer is empty and sends
;the content of dout.
	sbis	UCSRA,UDRE				;Wait until transmit buffer is empty.
	rjmp	send_byte
	out		UDR,dout				;Send data to USART Data Register.
	ret

do_spm:								;Copy Temp1 to SPMCR and execute spm.
	rcall	wait_spm
	rcall	wait_ee
	out		SPMCR,Temp1
	spm
	ret

wait_spm:							;Wait until previous spm is completed.
	push	Temp0
	spm_loop:
	in		Temp0,SPMCR
	sbrc	Temp0,SPMEN
	rjmp	spm_loop
	pop		Temp0
	ret

enable_rww:							;Re-enable the RWW section.
	push	Temp1
	rcall	wait_spm
	ldi		Temp1,0x11
	rcall	do_spm
	pop		Temp1
	ret

send13:								;Send a carriage return.
	ldi		dout,13
	rcall	send_byte
	ret

wait_ee:							;Wait until previous EEPROM read/write is completed.
	sbic	EECR,EEWE
	rjmp	wait_ee
	ret

;********************* Display subroutines **************************

delay100us:
	push	Temp1
	ldi		Temp1,0xFF
	L100us:
		wdr
		dec		Temp1
		brne	L100us	
	pop		Temp1
	ret

delay10ms:
	push	Temp0
	push	Temp1
	ldi		Temp0,0xFF
	ldi		Temp1,0x90
	L10ms:
		wdr
		dec		Temp0
		brne	L10ms
	wdr
	ldi		Temp0,0xFF
	dec		Temp1
	brne	L10ms
	pop		Temp1
	pop		Temp0
	ret

delay100ms:
	push	Temp2
	ldi		Temp2,0x0A
	L100ms:
	wdr
	rcall	delay10ms
	dec		Temp2
	brne	L100ms
	pop		Temp2
	ret

dis_cmd:
;Executes command stored in Temp0.
	cbi		PortC,RS				;Clear the RS signal.
	sbi		PortC,E					;Set the E signal.
	rcall	dis_byt					;Load data byte into shift register.
	nop
	cbi		PortC,E					;Clear the E signal.
	rcall	delay100us
	ret

dis_ram:
;Writes a character stored in DataL.
	sbi		PortC,RS				;Set the RS signal.
	sbi		PortC,E					;Set the E signal.
	rcall	dis_byt					;Load data byte into shift register.
	nop
	cbi		PortC,E					;Clear the E signal.
	rcall	delay100us
	ret

dis_cur:
;Moves the cursor to position POS (0-15).
	push	Temp0					;Store variable on stack.
	cpi		POS,8					;Test if POS=>8.
	brsh	right_h					;If it is then goto 'right'.
	ldi		Temp0,0x80				;If not then Temp0=0x80.
	rjmp	cur_return				;Call LCD_CMD and return.
	right_h:
	ldi		Temp0,0xB8				;If POS=>8 then Temp0=0xB8.
	cur_return:
	add		Temp0,POS
	rcall	dis_cmd
	rcall	delay100us
	pop		Temp0					;Restore variable from stack.
	ret

dis_byt:
;Shifts the byte stored in Temp0, to the LCD module.
	push	Count					;Save data on stack.
	ldi		Count,8					;Load bit counter.
	cbi		PortD,CLK
	byte_loop:
	rol		Temp0					;Shift data one step left. C <- MSB
	brcs	set_Data				;If Carry set, goto set_D.
	cbi		PortD,D					;If not then clear data signal
	rjmp	clk_pulse					;and jump to clock pulse.
	set_Data:
	sbi		PortD,D					;Set data signal for shift register.
	clk_pulse:
	sbi		PortD,CLK				;Set clk signal for shift register.
	cbi		PortD,CLK				;Clear clk signal for shift register.
	dec		Count					;Decrement bit counter.
	brne	byte_loop				;Not zero? Next bit.
	pop		Count					;Restore data from stack.
	ret

dis_msg:
;Writes a 16 byes long message which starts at adress ZH:ZL in Program Memory (flash).
;Cursor start at position 0.
	push	Temp0
	push	Count
	clr		Count
	clr		POS
	rcall	dis_cur					;Move cursor to position 0.
	mess_loop:
	wdr
	lpm		Temp0,Z+				;Load (ZH:ZL) into Temp0, and increment Z.
	rcall	dis_ram					;If not then write character.
	cpi		Count,15
	brsh	mess_ret				;If Count =>15 then return.
	inc		Count
	inc		POS						;Increment POS.
	rcall	dis_cur					;Move cursor.
	rjmp	mess_loop
	mess_ret:
	pop		Count
	pop		Temp0
	ret

boot_msg:
	.db		"Boot Loader Mode"

