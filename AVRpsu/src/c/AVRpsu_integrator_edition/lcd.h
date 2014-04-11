/********************************************************************
	Title:	lcd.h
	Author:	Thomas Strand
	Date:	22.02.04
	
	Header file for lcd.c
	Should be included at the top of main.c
	
********************************************************************/

// macros
#define set_d (PORTD|=0x40)			// Set data signal
#define clr_d (PORTD&=0xBF)			// Clear data signal
#define set_clk (PORTD|=0x80)		// Set clock signal
#define clr_clk (PORTD&=0x7F)		// Clear clock signal
#define set_e (PORTC|=0x20)			// Set enable signal
#define clr_e (PORTC&=0xCF)			// Clear enable signal
#define set_rs (PORTC|=0x10)		// Set register select signal
#define clr_rs (PORTC&=0xEF)		// Clear register select signal

// prototypes
void LCD_byt(uint8_t Data);
void LCD_cmd(uint8_t Data);
void LCD_ram(uint8_t Data);
void LCD_cur(uint8_t POS);
void LCD_pix(uint8_t uint8_tacter, PGM_P ptr);
void LCD_rstr(uint8_t* ptr, uint8_t pos);
void LCD_fstr(PGM_P ptr, uint8_t pos);
void LCD_scroll(PGM_P ptr, uint8_t length);
void LCD_16rstr(uint8_t* ptr);
void LCD_16str(PGM_P ptr, uint8_t pos);

