/******************************************************************************
 Title:    isr.c
 Author:   Thomas Strand
 Date:     March 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz
           
 Description:
 Interrupt Service Routines for AVRpsu.
 
*******************************************************************************/

// --- Timer0 overflow ---------------------------------------------------------
ISR(TIMER0_OVF_vect) {
/* Is executed every 23.7ms */
	relay();

	fan_count++;
	if((fan_count>3)&&(fans_run)) {
		fan_count=0;
		fan_anim++;								// Next frame of animation
		if(fan_anim>3)
			fan_anim=0;
		LCD_pix(5,&fan_icon[fan_anim][0]);
	}
	ms_count++;
	if(ms_count>8) {				// Adjust flash speed here
		ms_count=0;
		meas_t();
		fans();
		if(t_err==TRUE) {			// Temperature sensor error
			if(t_count==0)
				sensor_error();		// Show sensor error message once every ~55 seconds
			t_count++;
		}
		inv_flash;
		esc_timer++;				// Increment Mode Escape timer
	}
	if(disp_update==TRUE) {
		disp_update=FALSE;
		display();
	}
}
// -----------------------------------------------------------------------------

// --- Timer2 Compare Match ----------------------------------------------------
ISR(TIMER2_COMP_vect) {
	adc_count++;
	if(adc_count == adc_interval) {
		adc_count=0;
		start_conv;							// Start ADC conversion
	}
}
// -----------------------------------------------------------------------------

// --- ADC Conversion Complete -------------------------------------------------
ISR(ADC_vect) {
	uint16_t reading;
	
	reading = ADC;
	reading = (reading >> 1);
	reading ++;
	reading = (reading >> 1);
	if(ADC_V) {
		v_meas = reading;
	}
	else {
		a_meas = reading;
	}
	disp_update = TRUE;
	SWAP_ADC_CH;							// Swap ADC channel
}
// -----------------------------------------------------------------------------

// --- USART Data Received -----------------------------------------------------
ISR(USART_RXC_vect) {
	char data;
	switch(UDR) {
		case 0x1B:						// Escape ........................
			break;
		case 'M':						// Read Measurements .............
			usart_send_ascii(v_meas);	//		Voltage (3 digits)
			usart_send_ascii(a_meas);	//		Current (3 digits)
			usart_send(out_state);		//		Output (V, C or O)
			usart_send_temp(t_meas);	//		Temperature (3 digits)
			break;
		case 'V': 						// Set Volt ......................
			data=usart_recv();
			if(data<251)
				v_set=data;
			else {						// 		Illegal value
				usart_send('?');
				break;
			}
			set_usart_cmd;				// 		Activate USART icon
			disp_update=TRUE;
//			usart_send(13);
			break;		
		case 'A':						// Set Ampere ....................
			data=usart_recv();
			if(data<251)
				a_set=data;
			else {						// 		Illegal value
				usart_send('?');
				break;
			}
			set_usart_cmd;				// 		Activate USART icon
			disp_update=TRUE;
//			usart_send(13);
			break;
		case 'O':						// Output on .....................
			set_out;
			set_usart_cmd;				// 		Activate USART icon
			disp_update=TRUE;
//			usart_send(13);
			break;
		case 'o':						// Output off ....................
			clr_out;
			set_usart_cmd;				// 		Activate USART icon
			disp_update=TRUE;
//			usart_send(13);
			break;
		default:
			usart_send('?');
			break;
	}
}
// -----------------------------------------------------------------------------
