//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "main.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "VrControls"
#pragma link "VrDigit"
#pragma link "VrDisplay"
#pragma link "VrSlider"
#pragma link "VrButtons"
#pragma link "VrLabel"
#pragma link "VrBanner"
#pragma link "VrButtons"
#pragma link "VrControls"
#pragma link "VrDigit"
#pragma link "VrDisplay"
#pragma link "VrLabel"
#pragma link "VrSlider"
#pragma link "VrButtons"
#pragma link "VrControls"
#pragma link "VrDigit"
#pragma link "VrDisplay"
#pragma link "VrLabel"
#pragma link "VrSlider"
#pragma link "CommPort"
#pragma link "VrMeter"
#pragma resource "*.dfm"

TMainForm *MainForm;
//---------------------------------------------------------------------------
__fastcall TMainForm::TMainForm(TComponent* Owner)
        : TForm(Owner)
{
    CommPort->Open();
    CommState = IDLE;
    CommRxFlag = FALSE;
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::VoltSliderChange(TObject *Sender)
{
    AnsiString Vstr;
    char voltstr[2] = "V ";

    VoltSet = VoltSlider->Position;

    voltstr[1] = VoltSet;
    CommPort->Write(&voltstr, 2);
    VoltUpDown->Position = VoltSet;
    Vstr = FloatToStrF((VoltSet / 10.0), ffFixed, 3, 1);
    VoltSetLabel->Caption = Vstr + " V";

	CommState = SET_V;
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::VoltUpDownClick(TObject *Sender,
        TUDBtnType Button)
{
	VoltSet = VoltUpDown->Position;
	VoltSlider->Position = VoltSet;
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::AmpereSliderChange(TObject *Sender)
{
	AnsiString Astr;
	char ampstr[2] = "A ";

	AmpereSet = AmpereSlider->Position;

	ampstr[1] = AmpereSet;
	CommPort->Write(&ampstr, 2);
	AmpereUpDown->Position = AmpereSet;
	Astr = FloatToStrF((AmpereSet / 100.0), ffFixed, 3, 2);
	AmpereSetLabel->Caption = Astr + " A";
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::AmpereUpDownClick(TObject *Sender,
      TUDBtnType Button)
{
	AmpereSet = AmpereUpDown->Position;
	AmpereSlider->Position = AmpereSet;
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::OutputButtonClick(TObject *Sender)
{
	char outstr;

	if(OutputButton->Active == TRUE)
		outstr = 'O';
	else
		outstr = 'o';
	CommPort->Write(&outstr, 1);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::MeaurementTimer(TObject *Sender)
{
	char outstr;
	char *outptr = &outstr;
	char *pointer;
    AnsiString tempstring;

    outstr = 'M';
    CommPort->Write(outptr, 1);
    if(CommRxFlag == TRUE)
    {
     CommRxFlag = FALSE;
     tempstring = CommBuffer.SubString(0, 3);              // Voltage
     VoltDigitGroup->Value = tempstring.ToInt() / 10.0;

     tempstring = CommBuffer.SubString(4, 3);              // Current
     AmpereDigitGroup->Value = tempstring.ToInt() / 100.0;

     tempstring = CommBuffer.SubString(7, 1);              // Output
     if(tempstring == "V")
     {
      OutputLabel->Caption = "CV";
     }
     if(tempstring == "C")
     {
      OutputLabel->Caption = "CC";
     }
     if(tempstring == "O")
     {
      OutputLabel->Caption = "OFF";
     }

     tempstring = CommBuffer.SubString(8, 3);              // Temperature
     tempstring.Insert(".", 3);
     TemperatureLabel->Caption = tempstring + " \xB0\C";
    }
}
//---------------------------------------------------------------------------


void __fastcall TMainForm::CommPortDataReceived(TObject *Sender,
	  const char *Buffer, unsigned Length)
{
	CommBuffer = AnsiString(Buffer);
	CommBuffer.SetLength(Length);
	CommRxFlag = TRUE;
}
//---------------------------------------------------------------------------

