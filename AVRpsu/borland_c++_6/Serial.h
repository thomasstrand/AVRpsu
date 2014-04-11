// Serial.h
// Serial class definition. This file represents Serial's public interface.
// The implementations are in Serial.cpp.

class Serial
{
public:
        SetVolt(char voltage);
private:
        char voltstr[2];
        char *voltptr;
};

 