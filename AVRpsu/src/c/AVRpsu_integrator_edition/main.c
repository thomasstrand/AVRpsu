/******************************************************************************
 Title:    AVRpsu
 Author:   Thomas Strand
 Date:     February-May 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz
           
 Description:
 This is a laboratory Power Supply Unit controlled by a mega8.
 
*******************************************************************************/
#include <inttypes.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/eeprom.h>
#include <avr/delay.h>
#include <avr/signal.h>
#include <avr/interrupt.h>

#include "main.h"
#include "lcd.h"
#include "18s20.h"

/*
 * global variables
 */
bool out;						// Output
bool overtemp;					// Overtemperature
volatile bool flash;			// Flash Flag
volatile bool usart_cmd;		// USART Command Received
volatile bool disp_update;		// Display update needed?
volatile bool t_err;			// Temperature sensor error

uint8_t v_set, a_set,  rel_count, rot_prev, mode, out_state;
volatile uint8_t v_meas, a_meas, fan_count, fan_anim, esc_timer;

uint8_t t_start, t_stop, t_count;
volatile uint8_t t_meas;

volatile uint8_t log_counter;
uint8_t log_str[3];

uint8_t adc_interval=2;
volatile uint8_t adc_count;

volatile int8_t ms_count;

volatile uint8_t fan_pwm_counter, fan_pwm_dir, fan_speed;

uint8_t baud_set;
uint8_t keypress;

// Integrator
volatile uint8_t int_in, int_out, int_counter;
uint8_t int_error;
volatile uint16_t int_reg;

// The rest
uint8_t v_str[3], a_str[3], out_str[2];

uint8_t rot_state[4] PROGMEM = {0x10,0x30,0x20,0x00};		// State sequence for rotary encoder, Left->Right = Clockwise

uint8_t overtemp_str[] PROGMEM = "OVERHEATING - the output has been switched off. ";

uint8_t sens_err_str[] PROGMEM = "                Temperature sensor failure, check connection.";

// Icons for normal modes
uint8_t degc_icon[] PROGMEM = {0x18,0x18,0x03,0x04,0x04,0x04,0x03,0x00};	// Degrees C icon	ASCII 1
uint8_t usart_icon[] PROGMEM = {0x04,0x04,0x15,0x0E,0x04,0x1F,0x1F,0x00};	// USART icon		ASCII 2
uint8_t off_icon[2][8] PROGMEM = {											// OFF icon			ASCII 3 and 4
	{0x00,0x00,0x02,0x05,0x05,0x05,0x02,0x00},
	{0x00,0x00,0x1B,0x12,0x1B,0x12,0x12,0x00} };
uint8_t fan_icon[4][8] PROGMEM = {											// Fan icon			ASCII 5
	{0x00,0x0C,0x0C,0x04,0x06,0x06,0x00,0x00},								// Animated with 4 frames
	{0x00,0x03,0x03,0x04,0x18,0x18,0x00,0x00},
	{0x00,0x00,0x03,0x1F,0x18,0x00,0x00,0x00},
	{0x00,0x18,0x18,0x04,0x03,0x03,0x00,0x00} };

// Icons for Bargraph mode
uint8_t empty[] PROGMEM = {0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x1F};		// Empty bar		ASCII 1
uint8_t full[] PROGMEM = {0x00,0x1F,0x1F,0x1F,0x1F,0x00,0x01,0x1F};		// Full bar			ASCII 2
uint8_t adj[4][8] PROGMEM = {												// adjustable bar	ASCII 6 and 7
	{0x00,0x10,0x10,0x10,0x10,0x00,0x01,0x1F},
	{0x00,0x18,0x18,0x18,0x18,0x00,0x01,0x1F},
	{0x00,0x1C,0x1C,0x1C,0x1C,0x00,0x01,0x1F},
	{0x00,0x1E,0x1E,0x1E,0x1E,0x00,0x01,0x1F} };

uint8_t screen[11][17] PROGMEM = {		// Static text for menus
	{"    V          A\0"},				// Normal
	{"    V          A\0"},				// Set V
	{"    V          A\0"},				// Set A
	{"RS232        8N1\0"},				// Set Baud
	{"Fan start       \0"},				// Set FanMax
	{"Fan stop        \0"},				// Set FanStart
	{"V\1\1\1\1\1    A\1\1\1\1\1\0"},	// Normal Bargraph
	{"    V     A     \0"},				// Set V Bargraph
	{"V              A\0"},				// Set A Bargraph
	{"                \0"},				// Power and temperature (from Normal)
	{"                \0"} };			// Power and temperature (from Normal Bargraph)

uint8_t menu_table[11][5] PROGMEM = {	// Defines what happens when keys are pressed in different modes
// 	SET_short		SET_long		OUT_short	OUT_long		SET_OUT
	{M_set_v,		M_set_baud,		M_inv_out,	M_power,		M_normal_bar},		// Mode0	- Normal
	{M_set_a,		M_set_baud,		M_inv_out,	M_NULL,			M_normal_bar},		// Mode1	- Set V
	{M_normal,		M_set_baud,		M_inv_out,	M_NULL,			M_normal_bar},		// Mode2	- Set A
	{M_set_tstart,	M_normal,		M_NULL,		M_NULL,			M_NULL		},		// Mode3	- Set Baud
	{M_set_tstop,	M_normal,		M_NULL,		M_NULL,			M_NULL		},		// Mode4	- Set FanStart
	{M_set_baud,	M_normal,		M_NULL,		M_NULL,			M_NULL		},		// Mode5	- Set FanStop
	{M_set_v_bar,	M_NULL,			M_inv_out,	M_power_bar,	M_normal	},		// Mode6	- Normal Bargraph
	{M_set_a_bar,	M_NULL,			M_inv_out,	M_NULL,			M_normal	},		// Mode7	- Set V Bargraph
	{M_normal_bar,	M_NULL,			M_inv_out,	M_NULL,			M_normal	},		// Mode8	- Set A Bargraph
	{M_NULL,		M_NULL,			M_NULL,		M_normal,		M_NULL		},		// Mode9	- Power and temperature (from Normal)
	{M_NULL,		M_NULL,			M_NULL,		M_normal_bar,	M_NULL		} };	// Mode10	- Power and temperature (from Normal Bargraph)

struct rs232 {						// Struct for baud_set
	unsigned int ubrr_val;			// Value for baud rate register
	uint8_t text[7];				// Text for that baud rate
};

const struct rs232 baudrate[11] PROGMEM = {
	{0x0000, "      \0"},
	{0x08FF, "   300\0"},
	{0x047F, "   600\0"},
	{0x023F, "  1200\0"},
	{0x011F, "  2400\0"},
	{0x008F, "  4800\0"},
	{0x0047, "  9600\0"},
	{0x0023, " 19200\0"},
	{0x0011, " 38400\0"},
	{0x000B, " 57600\0"},
	{0x0005, "115200\0"} };

/*
 * main
 */
int main(void) {
	int8_t rot;
	uint8_t new_mode;
	meas_t();
	start_screen();
	init();
	meas_t();
	sei();

/*/test *******************************************************************************	
	mode=M_power;
	print_screen();
	
	int8_t rot_val=0;
	write_v(int_reg, 0);
	write_signed(int_error);	
	
	for(;;) {
		rot_val=read_rot();
		int_error+=rot_val;
		if(disp_update==TRUE) {
			disp_update=FALSE;
			write_v(int_reg, 0);
			write_signed(int_error);
		}
	}
*/
//test ********************************************************************************

	for(;;) {
		keypress=read_keys();
		if(keypress) {
			new_mode=pgm_read_byte_near(&(menu_table[mode][keypress-1]));
			switch(new_mode) {
				case M_inv_out:
					inv_out;
					disp_update=TRUE;
					break;
				case M_normal:
					normal_icons();
					adc_interval=2;
					mode=new_mode;
					print_screen();
					if(keypress==SET_short) {
						eeprom_write_byte((uint8_t*)v_set_ee, v_set);	// Save v_set to EEPROM
						eeprom_write_byte((uint8_t*)a_set_ee, a_set);	// Save a_set to EEPROM
					}
					else if(keypress==SET_long) {
						set_baud();
						eeprom_write_byte((uint8_t*)t_start_ee, t_start);	// Save t_start, t_stop and baud_set to EEPROM
						eeprom_write_byte((uint8_t*)t_stop_ee, t_stop);
						eeprom_write_byte((uint8_t*)baud_set_ee,baud_set);
					}
					break;
				case M_normal_bar:
					bargraph_icons();
					adc_interval=0;
					mode=new_mode;
					print_screen();
					break;
				case M_power_bar:
					normal_icons();
					mode=new_mode;
					print_screen();
					break;
				default:
					if(new_mode!=M_NULL) {
						mode=new_mode;
						print_screen();
					}
					break;
			}
		}
		rot=read_rot();
		if(rot) {
			esc_timer=0;						// Reset Mode Escape timer
			disp_update=TRUE;
			switch(mode) {
			case M_set_v: case M_set_v_bar:	// Set V (including bargraph)
				if((v_set<1)&&(rot<0))			// Lower Volt limit
					rot=0;
				if((v_set>=250)&&(rot>0)) 		// Upper Volt limit
					rot=0;
				v_set+=rot;
				ms_count=-8;
				clr_flash;						// Stop flashing for a while
				clr_usart_cmd;					// Remove USART icon from display
				break;
			case M_set_a: case M_set_a_bar:	// Set A (including bargraph)
				if((a_set<1)&&(rot<0)) 		// Lower Ampere limit
					rot=0;
				if((a_set>=250)&&(rot>0)) 		// Upper Ampere limit
					rot=0;
				a_set+=rot;
				ms_count=-8;
				clr_flash;						// Stop flashing for a while
				clr_usart_cmd;					// Remove USART icon from display
				break;
			case M_set_baud:					// Set baud
				if((baud_set<1)&&(rot<0)) 
					rot=0;
				if((baud_set>=9)&&(rot>0)) 
					rot=0;
				baud_set+=rot;
				ms_count=-8;
				clr_flash;
				break;
			case M_set_tstart:								// Set Fan Start
				if((t_start<(t_stop+3))&&(rot<0)) 		// Lower t_start limit, 1 deg C distance to t_stop
					rot=0;
				if ((t_start>=160)&&(rot>0)) 				// Upper t_start limit
					rot=0;
				t_start+=rot;
				ms_count=-8;
				clr_flash;
				break;
			case M_set_tstop:								// Set Fan Stop
				if((t_stop<=60)&&(rot<0)) 					// Lower t_max limit
					rot=0;
				if((t_stop>(t_start-3))&&(rot>0)) 		// Upper t_max limit, 1 deg C distance to t_start
					rot=0;
				t_stop+=rot;
				ms_count=-8;
				clr_flash;
				break;
			}
		}
	}
	return 0;
}

/*
 * external functions
 */
#include "start_screen.c"
#include "isr.c"
#include "lcd.c"
#include "18s20.c"

/*
 * function definitions
 */
 void init(void) {
	uint8_t state_now, a=0;										// Load initial rotary encoder state
	state_now=PIND&0x30;
	while(state_now!=(pgm_read_byte_near(&rot_state[a])))			// Find element in table
		a++;														// The rotary encoder state is stored as the
	rot_prev=a;														// flash table index
	
	// Timer0 - General interrupt timer
	TIMSK=(1<<TOIE0)|(1<<TOIE2);		// Enable Timer0 and Timer2 overflow interrupt
	TCCR0=0x05;							// clk/1024
	
	// Timer1 - Hardware PWM for voltage and current setting
	TCCR1A=0xA0;						// Phase and Frequency correct PWM, ICR1=TOP
	TCCR1B=0x11;						// clk/1, mode 8 on page 97 of the data sheet
	ICR1=256;							// TOP value

	// Timer2 - PWM generation for the cooling fans
	TCCR2=0x05;							// clk/128

	// ADC
	ADMUX=0x66;							// Aref=Avcc, left adjust result, input=ADC6
	ADCSR=0x8E;							// Enable ADC, single conversions, enable interrupt, clk/64
	
	// USART
	UCSRB=(1<<RXCIE);					// Enable USART RX complete interrupt
	
	// Variables
	v_set=eeprom_read_byte((uint8_t*)v_set_ee);			// Read settings from EEPROM
	a_set=eeprom_read_byte((uint8_t*)a_set_ee);
	baud_set=eeprom_read_byte((uint8_t*)baud_set_ee);
	t_start=eeprom_read_byte((uint8_t*)t_start_ee);
	t_stop=eeprom_read_byte((uint8_t*)t_stop_ee);
	
	normal_icons();
	
	print_screen();
	display();
	set_baud();
	flush_usart();
}

void normal_icons(void) {
/* Loads user-defined icons used in normal modes */
	LCD_pix(1,&degc_icon[0]);			// Load degree C icon at ASCII code 1
	LCD_pix(2,&usart_icon[0]);			// Load USART icon at ASCII code 2
	LCD_pix(3,&off_icon[0][0]);		// Load OFF icons at ASCII codes 3 and 4
	LCD_pix(4,&off_icon[1][0]);
}

void bargraph_icons(void) {
/* Loads icons for Bargraph Mode */
	LCD_pix(1,&empty[0]);
	LCD_pix(2,&full[0]);
}
	
void bin2bcd(uint8_t in, uint8_t* out) {
/* Converts a byte to 3 digits ASCII code */
	uint8_t a;
	for(a=0;a<3;a++)
		*(out+a)=0x30;				// Clear output and add offset for ASCII
	while(in>99) {
		(*(out))++;				// Hundreds
		in=in-100;
	}
	while(in>9) {
		(*(out+1))++;				// Tens
		in=in-10;
	}
	*(out+2)=*(out+2)+in;			// The rest is ones
}

uint8_t read_keys(void) {
/* Reads the keys */
	uint8_t key_time=0;
	if(!(SET_K)) {
		while(!(SET_K)) {
			key_time++;
			_delay_loop_2(10000);
			if(!(keypress)) {
				if(!(OUT_K))
					return SET_OUT;
				if(key_time==255)
					return SET_long;
			}
		}
		if(!(keypress))
			return SET_short;
	}
	if(!(OUT_K)) {
		while(!(OUT_K)) {
			key_time++;
			_delay_loop_2(10000);
			if(!(keypress)) {
				if(!(SET_K))
					return SET_OUT;
				if(key_time==255)
					return OUT_long;
			}
		}
		if(!(keypress))
			return OUT_short;
	}
	return 0;
}

int8_t read_rot(void) {
/* Reads the rotary encoder and returns -1, 0 or 1 */
	uint8_t state_now, rot_now, a=0;
	int8_t val=0;
	_delay_loop_2(500);
	state_now=PIND&0x30;
	while(state_now!=(pgm_read_byte_near(&rot_state[a])))		// Find element in table
		a++;
	rot_now=a;
	if(rot_now!=rot_prev) {
		if((rot_prev==1)&&(rot_now==2))
			val=1;
		if((rot_prev==0)&&(rot_now==3))
			val=-1;
		rot_prev=rot_now;
	}
	return val;
}

void set_baud(void) {
/* Updates the UBRR according to baudrate */
	uint16_t baudcode;
	baudcode=pgm_read_word_near(&(baudrate[baud_set+1].ubrr_val));
	disable_usart;
	UBRRH=(uint8_t)(baudcode>>8);
	UBRRL=(uint8_t)baudcode;
	flush_usart();
	enable_usart;
}
	
void usart_send(uint8_t data) {
/* Sends a byte to the USART */
	while(!(UCSRA&1<<UDRE));		// Wait until data register empty
	UDR=data;						// Send data
}

uint8_t usart_recv(void) {
/* Receives a byte from the USART */
	while(!(UCSRA&(1<<RXC)));		// Wait until data is received
	return UDR;
}

void flush_usart(void) {
/* Flushes the USART Receive buffer */
	uint8_t a;
	while(UCSRA&(1<<RXC))
		a=UDR;
}

void relay(void) {
/* Operates the relay according to measured voltage */
	if(out) {
		if(v_meas>115) {			// Upper trig point for relay
			act_relay;
			rel_count=0;
		}
		if(v_meas<100) {			// Lower trig point for relay
			rel_count++;		
			if(rel_count>100) {
				rel_count=0;
				deact_relay;
			}
		}
	}
}

void fans(void) {
/* Operates the fans according to measured temperature */
	if(t_meas>=t_start)
		start_fans;
	if(t_meas<=t_stop)
		stop_fans;
	if(t_meas>=t_over)
		overheat();
}

void sensor_error(void) {
/* Writes temperature sensor failure message on display */
	LCD_scroll(&(sens_err_str[0]), 61);
	print_screen();
}

void overheat(void) {
/* Switches the output off and the fans on, and scrolls the
   overheat message on the display */
	clr_out;
	OCR1A=0;
	OCR1B=0;
	start_fans;
	while(t_meas>(t_over-10)) {
		LCD_scroll(&(overtemp_str[0]), 48);
		meas_t();
	}
	print_screen();
}

void display(void) {
/* Updates display according to mode */
	switch(mode) {
		case M_normal:							// Normal
			write_v(v_meas, 0);
			write_out();
			write_a(a_meas, 0);
			esc_timer=0;
			break;
		case M_set_v:							// Set Volt
			write_v(v_set, flash);
			write_out();
			write_a(a_meas, 0);
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=M_normal;
				print_screen();
			}
			break;
		case M_set_a:							// Set Ampere
			write_v(v_meas, 0);
			write_out();
			write_a(a_set, flash);
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=M_normal;
				print_screen();
			}
			break;
		case M_set_baud:						// Set Baud
			write_baud(flash);
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=M_normal;
				print_screen();
			}
			break;
		case M_set_tstart:						// Set Fan start temperature
			write_t(t_start, flash);
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=0;
				print_screen();
			}
			break;
		case M_set_tstop:						// Set Fan stop temperature
			write_t(t_stop, flash);
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=M_normal;
				print_screen();
			}
			break;
		case M_normal_bar:						// Bargraph
			v_bar();
			write_out();
			a_bar();
			esc_timer=0;
			break;
		case M_set_v_bar:						// Set Volt Bargraph
			write_v(v_set, flash);
			write_out();
			a_bar();
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=M_normal_bar;
				print_screen();
			}
			break;
		case M_set_a_bar:						// Set Ampere Bargraph
			v_bar();
			write_out();
			write_a(a_set, flash);
			if(esc_timer>esc_time)	{			// Long time without adjusting anything?
				mode=M_normal_bar;
				print_screen();
			}
			break;
		case M_power: case M_power_bar:		// View power and temperature (from Normal or Normal Bargraph)
			write_p();
			write_t(t_meas, 0);
			break;
	}
}

void write_v(uint8_t volt, uint8_t blank) {
/* Writes v_disp in the voltage field if blank=0 */
/* Else the field is filled with spaces */
	uint8_t a;
	LCD_cur(0);
	if(!blank) {
		bin2bcd(volt, &v_str[0]);
		if(v_str[0]=='0')
			v_str[0]=' ';					// Leading zero blanking
		LCD_ram(v_str[0]);
		LCD_ram(v_str[1]);
		LCD_ram('.');
		LCD_ram(v_str[2]);
	}
	else
		for(a=0;a<4;a++)
			LCD_ram(' ');
}

void write_out(void) {
/* Updates out_str according to on, v_meas and v_set */
/* and writes it in the output field */
	LCD_cur(6);
	if(usart_cmd)
		LCD_ram(2);									// Write USART icon
	else
		LCD_ram(' ');								// Remove USART icon
	if(out) {
		OCR1A=v_set;
		OCR1B=a_set;
		if((v_meas<v_set)&&(a_meas==a_set)) {		// Constant current
			out_state='C';
			out_str[0]='C';
			out_str[1]='C';
		}
		else {										// Constant voltage
			out_state='V';
			out_str[0]='C';
			out_str[1]='V';
		}
	}
	else {											// Off
		OCR1A=0;
		OCR1B=0;
		out_state='O';
		out_str[0]=3;
		out_str[1]=4;
	}
	LCD_ram(out_str[0]);
	LCD_cur(8);
	LCD_ram(out_str[1]);
	if(fans_run)
		LCD_ram(5);
	else
		LCD_ram(' ');
}

void write_a(uint8_t ampere, uint8_t blank) {
/* Writes a_disp in the ampere field if blank=0 */
/* Else the field is filled with spaces */
	uint8_t a;
	LCD_cur(11);
	if(!blank) {
		bin2bcd(ampere, &a_str[0]);
		LCD_ram(a_str[0]);
		LCD_ram('.');
		LCD_ram(a_str[1]);
		LCD_ram(a_str[2]);
	}
	else
		for(a=0;a<4;a++)
			LCD_ram(' ');
}


// ************** test ****************************
void write_signed(int8_t data) {
/* Writes a signed byte in the Ampere field */
	LCD_cur(11);
	if(data<0) {
		LCD_ram('-');
		data-=1;
		data^=0xFF;
	}
	else
		LCD_ram(' ');
	bin2bcd((uint8_t)data, &a_str[0]);
	LCD_ram(a_str[0]);
	LCD_ram(a_str[1]);
	LCD_ram(a_str[2]);
}
// ***************** test **************************

void write_baud(uint8_t blank) {
	int data;
	data=baud_set+1;
	if(blank)
		data=0;
	LCD_fstr(&(baudrate[data].text[0]), 6);
}

void v_bar(void) {
/* Draws a bargraph in the voltage field */
	uint8_t bar[6]={1,1,1,1,1,0};
	uint8_t pixels, position=0;
	pixels=v_meas/10;
	if((v_meas%10)>4)
		pixels++;
	while(pixels>4) {						// SKip to correct uint8_tacter
		bar[position]=2;					// While filling the lower ones
		pixels-=5;
		position++;
	}
	if(pixels) {
		LCD_pix(6,&(adj[pixels-1][0]));	// Generate variable uint8_tacter
		bar[position]=6;
	}
	LCD_rstr(&bar[0],1);
}

void a_bar(void) {
/* Draws a bargraph in the ampere field */
	uint8_t bar[6]={1,1,1,1,1,0};
	uint8_t pixels, position=0;
	pixels=a_meas/10;
	if((a_meas%10)>4)
		pixels++;
	while(pixels>4) {						// SKip to correct uint8_tacter
		bar[position]=2;					// While filling the lower ones
		pixels-=5;
		position++;
	}
	if(pixels) {
		LCD_pix(7,&(adj[pixels-1][0]));	// Generate variable uint8_tacter
		bar[position]=7;
	}
	LCD_rstr(&bar[0],11);
}

void write_p(void) {
	uint8_t digit[5]="00000";
	unsigned int p;
	p=v_meas*a_meas;
	while(p>9999) {
		digit[0]++;
		p=p-10000;
	}
	while(p>999) {
		digit[1]++;
		p=p-1000;
	}
	while(p>99) {
		digit[2]++;
		p=p-100;
	}
	while(p>9) {
		digit[3]++;
		p=p-10;
	}
	digit[4]=digit[4]+p;
	if(digit[0]=='0')
		digit[0]=' ';
	LCD_cur(0);
	LCD_ram(digit[0]);
	LCD_ram(digit[1]);
	LCD_ram('.');
	LCD_ram(digit[2]);
	LCD_ram(digit[3]);
	LCD_ram(digit[4]);
	LCD_ram('W');
}

void write_t(uint8_t data, uint8_t blank) {
/* Writes temperature data on the far right of the display.
   May be blanked. */
	uint8_t a, text[5]="000.0";		// Initial output string
	bin2bcd((data>>1), &text[0]);		// Convert input except for the 0.5 degree bit
	if(text[0]=='0') {
		text[0]=' ';
		if(text[1]=='0')
			text[1]=' ';
	}
	if(data&0x01)						// If the LSB is set then the rightmost digit is 5
		text[4]='5';
	LCD_cur(10);
	if(blank) {
		for(a=0;a<5;a++)
			text[a]=' ';
	}
	LCD_ram(text[0]);
	LCD_ram(text[1]);
	LCD_ram(text[2]);
	LCD_ram(text[3]);
	LCD_ram(text[4]);
	LCD_ram(1);
}

void print_screen(void) {
/* Prints static screens according to mode
   Should only be called when changing mode */
	LCD_fstr(&(screen[mode][0]), 0);
	disp_update=TRUE;
}
