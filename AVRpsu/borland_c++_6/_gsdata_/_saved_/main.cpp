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
#pragma resource "*.dfm"
TMainForm *MainForm;
//---------------------------------------------------------------------------
__fastcall TMainForm::TMainForm(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::VoltSliderChange(TObject *Sender)
{
        VoltSet = VoltSlider->Position;
        VoltUpDown->Position = VoltSet;
        VoltSetLabel->Caption = (VoltSet / 10.0);

}
//---------------------------------------------------------------------------


void __fastcall TMainForm::VoltUpDownClick(TObject *Sender,
      TUDBtnType Button)
{
        VoltSet = VoltUpDown->Position;
        VoltSlider->Position = VoltSet;
}
//---------------------------------------------------------------------------




