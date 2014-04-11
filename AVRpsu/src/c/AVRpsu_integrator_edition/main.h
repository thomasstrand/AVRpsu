/******************************************************************************
 Title:    main.h
 Author:   Thomas Strand
 Date:     March 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz
           
 Description:
 Header file for main.c
 
*******************************************************************************/

#define bool 	uint8_t
#define TRUE 	1
#define FALSE 	0

#define t_over		160		// Overtemperature trip point
#define esc_time	100		// Escape time to return to normal mode: t=X*(9*23.7ms)

// Menu states
#define M_normal		0
#define M_set_v			1
#define M_set_a			2
#define M_set_baud		3
#define M_set_tstart	4
#define M_set_tstop		5
#define M_normal_bar	6
#define M_set_v_bar		7
#define M_set_a_bar		8
#define M_power			9
#define M_power_bar		10

#define M_NULL			11
#define M_inv_out		12

// Key presses
#define SET_short	1
#define SET_long	2
#define OUT_short	3
#define OUT_long	4
#define SET_OUT		5

// Fan PWM
#define RISING		0
#define FALLING		1

// Pins
#define ROT_A PIND&0x10								// Rotary encoder pin A
#define ROT_B PIND&0x20								// Rotary encoder pin B
#define SET_K PIND&0x04								// Set key
#define OUT_K PIND&0x08								// Output key

// Status flags
#define ON 		0		// Output ON flag
#define FLASH	1		// Flash flag for display
#define UCR		2		// USART command received

// Macros
#define inv_flash 			(flash^=0x01)						// Invert flash flag
#define clr_flash 			(flash=0)							// Clear flash flag

#define inv_out				(out^=0x01)							// Invert the on flag
#define set_out				(out=1)								// Set the on flag
#define clr_out				(out=0)								// Clear the on flag

#define start_conv 			(ADCSR|=0x40)						// Start ADC conversion
#define swap_adc 			(ADMUX=((ADMUX)^(0x01)))			// Swap ADC channel
#define adc_v 				(ADMUX&0x01)						// ADC voltage channel selected (for reading)

#define enable_usart 		(UCSRB|=0x18)						// Enable USART tranmitter and receiver
#define disable_usart 		(UCSRB&=~(0x18))					// Disable USART transmitter and receiver
#define usart_rxc 			(UCSRA&(1<<RXC))					// USART receive complete flag (for reading)
#define usart_dre 			(UCSRA&(1<<UDRE))					// USART data register empty flag (for reading)
#define set_usart_cmd 		(usart_cmd=1)						// Set USART command received flag
#define clr_usart_cmd 		(usart_cmd=0)						// Clear USART command teceived flag

#define act_relay 			(PORTC|=0x1)						// Activate relay
#define deact_relay 		(PORTC&=0xFE)						// Deactivate relay

#define start_fans 			(PORTC|=0x02)						// Start fans
#define stop_fans 			(PORTC&=0xFD)						// Stop fans
#define fans_run 			(PORTC&0x02)						// Read fans

#define v_set_ee	0		// EEPROM adresses
#define a_set_ee	1
#define baud_set_ee	2
#define t_start_ee	3
#define t_stop_ee	4

/*
 * function prototypes
 */
void init(void);
void normal_icons(void);
void bargraph_icons(void);
void bin2bcd(uint8_t in, uint8_t* out);
void display(void);
uint8_t read_keys(void);
int8_t read_rot(void);
void set_baud(void);
void usart_send(uint8_t data);
uint8_t usart_recv(void);
void flush_usart(void);
void relay(void);
void fans(void);
void sensor_error(void);
void overheat(void);
void write_v(uint8_t volt, uint8_t blank);
void write_out(void);
void write_a(uint8_t ampere, uint8_t blank);

void write_signed(int8_t data);

void write_baud(uint8_t blank);
void v_bar(void);
void a_bar(void);
void write_p(void);
void write_t(uint8_t data, uint8_t blank);
void print_screen(void);
void start_screen(void);
