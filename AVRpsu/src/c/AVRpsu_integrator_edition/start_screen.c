/******************************************************************************
 Title:    start_screen.c
 Author:   Thomas Strand
 Date:     March 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz
           
 Description:
 Draws an animated start screen.
 Press SET or OUTPUT to exit.
 
*******************************************************************************/

uint8_t start_str[16] PROGMEM = {0x06,0x07,0x06,0x06,0x01,0x02,0x03,0x04,0x05,'p','s','u',0x06,0x06,0x07,0x06};

uint8_t logo[5][8] PROGMEM = {
	{0x03,0x07,0x06,0x0E,0x0F,0x1C,0x1C,0x00},
	{0x1B,0x1D,0x0D,0x0E,0x1E,0x07,0x07,0x00},
	{0x00,0x11,0x11,0x1B,0x1B,0x0E,0x0E,0x04},
	{0x1B,0x16,0x16,0x0F,0x0E,0x1C,0x1C,0x00},
	{0x1E,0x07,0x07,0x1E,0x18,0x0C,0x0C,0x00}
	};

uint8_t alien[8][8] PROGMEM = {
	{0x00,0x00,0x02,0x04,0x0E,0x15,0x1F,0x0E},	// Frame 0
	{0x00,0x04,0x04,0x0E,0x15,0x1F,0x1F,0x0E},	// Frame 1
	{0x08,0x04,0x0E,0x15,0x1F,0x11,0x0E,0x00},	// Frame 2
	{0x10,0x08,0x0E,0x15,0x1F,0x1F,0x0E,0x00},	// Frame 3
	{0x08,0x04,0x0E,0x15,0x1F,0x11,0x0E,0x00},	// Frame 4
	{0x04,0x04,0x0E,0x15,0x1F,0x1F,0x0E,0x00},	// Frame 5
	{0x02,0x04,0x0E,0x15,0x1F,0x11,0x0E,0x00},	// Frame 6
	{0x00,0x01,0x02,0x0E,0x15,0x1F,0x1F,0x0E},	// Frame 7
	};

uint8_t stars[8][8] PROGMEM = {
	{0x00,0x00,0x00,0x04,0x10,0x02,0x00,0x09},	// Frame 0
	{0x00,0x00,0x00,0x02,0x08,0x01,0x00,0x04},	// Frame 1
	{0x00,0x00,0x00,0x01,0x04,0x00,0x10,0x02},	// Frame 2
	{0x00,0x00,0x00,0x00,0x02,0x00,0x08,0x01},	// Frame 3
	{0x00,0x00,0x00,0x00,0x01,0x00,0x04,0x10},	// Frame 4
	{0x00,0x00,0x00,0x00,0x00,0x10,0x02,0x08},	// Frame 5
	{0x00,0x00,0x00,0x10,0x00,0x08,0x01,0x04},	// Frame 6
	{0x00,0x00,0x00,0x08,0x00,0x04,0x00,0x12},	// Frame 7
	};

void start_screen(void) {
	uint8_t a, b;
	for(a=0;a<5;a++)
		LCD_pix(a+1, &(logo[a][0]));		// Load logo
	LCD_fstr(&start_str[0], 0);
	while(SET_K&&OUT_K) {
		for(a=0;a<8;a++) {
			LCD_pix(6, &(stars[a][0]));	// Load stars
			LCD_pix(7, &(alien[a][0]));	// Load alien
			for(b=0;b<5;b++) {
				if(!(SET_K&&OUT_K))
					break;
				else
					_delay_loop_2(0xFFFF);
			}
		}
	}
	_delay_loop_2(10000);
	while(!(SET_K&&OUT_K));
}