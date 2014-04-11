/******************************************************************************
 Title:    isr.c
 Author:   Thomas Strand
 Date:     March 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz
           
 Description:
 Interrupt Service Routines for AVRpsu.
 
*******************************************************************************/

SIGNAL(SIG_OVERFLOW0) {			// Timer0 overflow
/* Executed every 23.7ms */
	relay();
	adc_count++;
	if(adc_count>adc_interval) {
		adc_count=0;
		start_conv;					// Start ADC conversion
	}
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
//		fans();					***************** test *******************************
		if(t_err==TRUE) {			// Temperature sensor error
			if(t_count==0)
				sensor_error();		// Show sensor error message once every ~55 seconds
			t_count++;
		}
		inv_flash;
		esc_timer++;				// Increment Mode Escape timer
	}
	
	// Integrator
	int_counter++;
	if(int_counter==53) {			// ti = (23.7ms * 4 * x) ~1 second
		int_counter=0;
		disp_update=TRUE;
		int_reg+=int_error;
		int_out=(uint8_t)(int_reg>>8);
	}

	if(disp_update==TRUE) {		//***************** test *****************************
		disp_update=FALSE;
		display();
	}
}

SIGNAL(SIG_OVERFLOW2) {						// PWM routine for the cooling fans
/* Executed every ~2.9629ms => 337.5Hz */
	uint8_t pwm_val;
	log_counter++;
	if(log_counter==84) {
		log_counter=0;
		bin2bcd(t_meas, &log_str[0]);
		usart_send(log_str[0]);
		usart_send(log_str[1]);
		usart_send(log_str[2]);
		usart_send(' ');
		bin2bcd(a_meas, &log_str[0]);
		usart_send(log_str[0]);
		usart_send(log_str[1]);
		usart_send(log_str[2]);
		usart_send('\n');
		usart_send('\r');
	}
	
	if(!out)
		fan_speed=15;
	else
		fan_speed=0;
	
	if(fan_speed) {							// fan_speed is [0-15], 0=stop, 15=full speed.
		pwm_val=fan_speed+10;
		if(fan_pwm_dir==RISING) {
			fan_pwm_counter++;
			if(fan_pwm_counter==24)		// TOP value
				fan_pwm_dir=FALLING;
			if(fan_pwm_counter>=pwm_val)
				stop_fans;
		}
		else {
			fan_pwm_counter--;
			if(fan_pwm_counter==0)			// BOTTOM value
				fan_pwm_dir=RISING;
			if(fan_pwm_counter<=pwm_val)
				start_fans;
		}
	}
	else
		stop_fans;
}

SIGNAL(SIG_ADC) {								// ADC conversion complete
	uint8_t resultl, resulth;
	resultl=ADCL;
	resulth=ADCH;
	if((resulth!=255)&&(resultl&0x80))		// Round result up if next significant bit is set
		resulth++;
	if(adc_v)
		v_meas=resulth;
	else
		a_meas=resulth;
	disp_update=TRUE;
	swap_adc;									// Swap ADC channel
}

SIGNAL(SIG_UART_RECV) {			// USART command received
	uint8_t data;
	switch(UDR) {
		case 0x1B:					// Escape
			break;
		case 'V': 					// Set Volt
			data=usart_recv();
			if(data<251)
				v_set=data;
			else {					// Illegal value
				usart_send('?');
				break;
			}
			set_usart_cmd;			// Activate USART icon
			disp_update=TRUE;
			usart_send(13);
			break;
		case 'v':					// Read Volt
			usart_send(v_meas);
			break;
		case 'A':					// Set Ampere
			data=usart_recv();
			if(data<251)
				a_set=data;
			else {					// Illegal value
				usart_send('?');
				break;
			}
			set_usart_cmd;			// Activate USART icon
			disp_update=TRUE;
			usart_send(13);
			break;
		case 'a':					// Read Ampere
			usart_send(a_meas);
			break;
		case 't':					// Read Temperature
			usart_send(t_meas);
			break;
		case 'O':					// Output on
			set_out;
			set_usart_cmd;			// Activate USART icon
			disp_update=TRUE;
			usart_send(13);
			break;
		case 'o':					// Output off
			clr_out;
			set_usart_cmd;			// Activate USART icon
			disp_update=TRUE;
			usart_send(13);
			break;
		case 's':					// Read Output State
			usart_send(out_state);
			break;
		default:
			usart_send('?');
			break;
	}
}
