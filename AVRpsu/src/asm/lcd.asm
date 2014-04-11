LCD_CMD:
;Executes command stored in DataL.
	cbi		PortC,RS				;Clear the RS signal.
	sbi		PortC,E					;Set the E signal.
	rcall	LCD_BYT					;Load data byte into shift register.
	nop
	cbi		PortC,E					;Clear the E signal.
	rcall	WAIT100us
	ret

LCD_RAM:
;Writes a character stored in DataL.
	sbi		PortC,RS				;Set the RS signal.
	sbi		PortC,E					;Set the E signal.
	rcall	LCD_BYT					;Load data byte into shift register.
	nop
	cbi		PortC,E					;Clear the E signal.
	rcall	WAIT100us
	ret

LCD_CUR:
;Moves the cursor to position POS (0-15).
	push	DataL
	cpi		POS,8					;Test if POS=>8.
	brsh	right
	ldi		DataL,0x80
	rjmp	cur_ret
	right:
	ldi		DataL,0xB8				;Taking care of adress offset in middle of display.
	cur_ret:
	add		DataL,POS
	rcall	LCD_CMD
	rcall	WAIT100us
	pop		DataL
	ret

LCD_FMSG:
;Writes a zero-terminated message which starts at adress ZH:ZL in Flash.
;Cursor start at position POS.
	push	DataL
	rcall	LCD_CUR					;Move cursor to position POS.
	fmsg_loop:
	wdr
	lpm		DataL,Z+
	cpi		DataL,0
	breq	fmsg_ret				;If zero then exit.
	rcall	LCD_RAM					;Else write character.
	inc		POS
	rcall	LCD_CUR
	rjmp	fmsg_loop
	fmsg_ret:
	pop		DataL
	ret

LCD_SMSG:
;Writes a 16 byes long message which starts at adress ZH:ZL in SRAM.
;Cursor start at position 0.
	push	DataL
	push	Count
	push	ZH
	push	ZL
	clr		Count
	clr		POS
	rcall	LCD_CUR					;Move cursor to position 0.
	msg_loop:
	wdr
	ld		DataL,Z+				;Load (ZH:ZL) into DataL, and increment Z.
	rcall	LCD_RAM
	cpi		Count,15
	breq	msg_ret					;If Count=15 then return.
	inc		Count
	inc		POS
	rcall	LCD_CUR
	rjmp	msg_loop
	msg_ret:
	pop		ZL
	pop		ZH
	pop		Count
	pop		DataL
	ret

LCD_BYT:
;Shifts the byte stored in DataL, to the LCD module.
	push	DataL
	push	Count
	ldi		Count,8					;Load bit counter.
	cbi		PortD,CLK
	byt_loop:
	sbrs	DataL,7
		cbi		PortD,D				;Copy bit7 to Data signal.
	sbrc	DataL,7
		sbi		PortD,D
	rol		DataL					;Shift data one step left.
	sbi		PortD,CLK
	cbi		PortD,CLK
	dec		Count					;Decrement bit counter.
	brne	byt_loop				;Not zero? Next bit.
	pop		Count
	pop		DataL
	ret

LCD_PIX:
;Changes pixel rows of one user-defined character.
;The CG RAM adress of the first row of the character must be in DataH.
;The pixel data must be in a table starting at ZH:ZL.
;The data table must be 8 bytes long.
	push	DataL
	push	DataH
	push	Count
	push	ZL
	push	ZH
	ldi		Count,8
	mov		DataL,DataH
	rcall	LCD_CMD					;Set CG RAM adress. It is auto-incremented by the display itself.
	pix_loop:
	lpm		DataL,Z+
	rcall	LCD_RAM					;Write pixel data.
	dec		Count
	brne	pix_loop				;Repeat 8 times.
	pop		ZH
	pop		ZL
	pop		Count
	pop		DataH
	pop		DataL
	ret