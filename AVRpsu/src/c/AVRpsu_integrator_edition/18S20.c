/******************************************************************************
 Title:    18s20.c
 Author:   Thomas Strand
 Date:     February 2004
 Software: AVR-GCC 3.3 
 Hardware: ATmega8 at 11.0592 Mhz

 Description:
 Functions for implementing the Dallas 18S20 1-wire temperature sensor.
 Should be included below 'main' function of main file.
 Note that the resolution of the device is 0.5 degrees C.
 This means the 7 most significant bits represents the temperature
 in whole degrees and the LSB is 0.5 deg C. 
 
*******************************************************************************/

void meas_t(void) {
/* Measures the temperature and updates t_meas */
	wr_tsens(0xCC);				// Skip ROM
	wr_tsens(0x44);				// Convert T
	if(rd_tsens()) {				// If coversion is complete
		t_err=t_reset();
		wr_tsens(0xCC);			// Skip ROM
		wr_tsens(0xBE);			// Read scratchpad
		t_meas=rd_tsens();
		t_err=t_reset();
	}
}

void wr_tsens(char data) {
/* Sends a data byte to the temperature sensor */
	char a;
	for(a=0;a<8;a++) {
		_delay_loop_1(18);			// Delay 5us
		if(data&0x01) {			// Send one
			clr_tsens;
			dirt_out;				// Direction for sensor pin is output :)
			_delay_loop_1(18);		// Short pulse = '1'
			dirt_in;
			_delay_loop_2(275);		// Delay 100us
		}
		else {						// Send zero
			clr_tsens;
			dirt_out;
			_delay_loop_2(275);		// Long pulse = '0'
			dirt_in;
			_delay_loop_1(18);
		}
		data=data>>1;
	}
}

char rd_tsens(void) {
/* Reads a byte from the temperature sensor */
	char a, data=0;
	for(a=0;a<8;a++) {
		_delay_loop_1(18);
		clr_tsens;
		dirt_out;
		_delay_loop_1(18);
		dirt_in;
		_delay_loop_1(18);
		data=data>>1;
		if(tsens)
			data|=0x80;
		_delay_loop_2(275);
	}
	return data;
}

char t_reset(void) {
/* Sends a reset pulse to the temperature sensor */
/* Returns 0 if all went well, 1 if no presence were detected */
	char wait_time=0;
	clr_tsens;
	dirt_out;
	_delay_loop_2(1660);			// Delay 600us, reset pulse
	dirt_in;
	_delay_loop_2(275);				// Delay 100us
	while(tsens) {					// Wait for presence pulse
		wait_time++;
		_delay_loop_1(4);			// Delay ~1us
		if(wait_time>200)
			return 1;				// No presence pulse after 200us, return error
	}
	_delay_loop_2(1660);
	set_tsens;
	dirt_out;
	return 0;
}
