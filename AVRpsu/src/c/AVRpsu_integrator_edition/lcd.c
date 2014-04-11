/********************************************************************
	Title:	lcd.c
	Author:	Thomas Strand
	Date:	22.02.04
	
	Low-level LCD routines for AVRpsu.
	Should be included in main.c
	
********************************************************************/
/*
 * function definitions
 */
 void LCD_byt(uint8_t Data) {
/* Shifts out Data byte to LCD display */
	uint8_t a;
	clr_clk;
	for(a=0;a<8;a++) {
		if(Data&0x80)				// Copy MSB of Data byte to D
			set_d;
		else
			clr_d;
		set_clk;					// Clock pulse to LCD shift register
		clr_clk;
		Data=Data<<1;
	}
}

void LCD_cmd(uint8_t Data) {
/* Sends a command to the LCD display */
	clr_rs;					// RS low for commands
	set_e;
	LCD_byt(Data);
	_delay_loop_1(1);
	clr_e;
	_delay_loop_1(200);		// Delay 60us
}

void LCD_ram(uint8_t Data) {
/* Sends a data byte to the LCD display */
	set_rs;
	set_e;
	LCD_byt(Data);
	_delay_loop_1(1);
	clr_e;
	_delay_loop_1(200);
}

void LCD_cur(uint8_t POS) {
/* Moves the cursor to position POS */
	if(POS>7) 
		POS+=0xB8;
	else
		POS+=0x80;
	LCD_cmd(POS);
}

void LCD_pix(uint8_t uint8_tacter, PGM_P ptr) {
/* Defines a user-defineable uint8_tacter */
	uint8_t a;
	uint8_tacter=(uint8_tacter*8)+64;
	LCD_cmd(uint8_tacter);						// Set CG RAM adress
	for(a=0;a<8;a++)
		LCD_ram(pgm_read_byte_near(ptr+a));
}

void LCD_rstr(uint8_t* ptr, uint8_t pos) {
/* Prints a zero-terminated string in SRAM to display */
	uint8_t data;
	data=*ptr;
	while(data) {
		LCD_cur(pos);
		LCD_ram(data);
		ptr++;
		pos++;
		data=*ptr;
	}
}

void LCD_fstr(PGM_P ptr, uint8_t pos) {
/* Prints a zero-terminated string in flash to display */
	uint8_t data;
	data = pgm_read_byte_near(ptr);
	while(data) {
		LCD_cur(pos);
		LCD_ram(data);
		ptr++;
		pos++;
		data=pgm_read_byte_near(ptr);
	}
}

void LCD_scroll(PGM_P ptr, uint8_t length) {
/* Scrolls a message on the display */
	uint8_t data[length+1], a, b;
	for(a=0;a<length;a++)
		data[a]=pgm_read_byte_near(ptr+a);
	LCD_16rstr(&data[0]);
	for(a=0;a<length;a++) {
		data[length]=data[0];
		for(b=0;b<length;b++)
			data[b]=data[b+1];
		for(b=0;b<8;b++)
			_delay_loop_2(0xFFFF);
		LCD_16rstr(&data[0]);
	}
}

void LCD_16rstr(uint8_t* ptr) {
/* Prints a 16-uint8_tacter SRAM string from pos. 0 */
	uint8_t a;
	for(a=0;a<16;a++) {
		LCD_cur(a);
		LCD_ram(*(ptr+a));
	}
}

void LCD_16str(PGM_P ptr, uint8_t pos) {
/* Prints 16 bytes long string in flash to display */
	uint8_t a;
	for(a=0;a<16;a++) {
		LCD_cur(a);
		LCD_ram(pgm_read_byte_near(ptr+a));
	}
}
