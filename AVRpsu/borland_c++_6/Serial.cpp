// Serial.cpp
// Serial member-function definitions.
// This file contains implementations of the functions prototyped in Serial.h.

#include "Serial.h"
#include "CommPort.h"

#pragma link "CommPort"

Serial::SetVolt(char voltage)
{
        voltptr = &voltstr[1];
        voltstr[0] = 'V';
        voltstr[1] = voltage;
        
}
