/******************************************************************************
 Title:    18s20.h
 Author:   Thomas Strand
 Date:     February 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz
           
 Description:
 Header file for 18s20.c
 
*******************************************************************************/

// Macros
#define tsens PINC&0x04				// Temperature sensor (for reading)
#define set_tsens (PORTC|=0x04)		// Set temperature sensor pin
#define clr_tsens (PORTC&=0xFB)		// Clear temperature sensor pin
#define dirt_out (DDRC|=0x04)		// Make temperature sensor pin output
#define dirt_in (DDRC&=0xFB)		// Make temperature sensor pin input

// Function prototypes
void meas_t(void);
void wr_tsens(char data);
char rd_tsens(void);
char t_reset(void);
