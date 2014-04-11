//---------------------------------------------------------------------------

#ifndef mainH
#define mainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "VrButtons.hpp"
#include "VrControls.hpp"
#include "VrDigit.hpp"
#include "VrDisplay.hpp"
#include "VrLabel.hpp"
#include "VrSlider.hpp"
#include <ComCtrls.hpp>

//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TVrDisplay *MainDisplay;
        TVrDigitGroup *VoltDigitGroup;
        TVrDigitGroup *AmpereDigitGroup;
        TVrSlider *VoltSlider;
        TGroupBox *MainSettingsGroupBox;
        TLabel *VoltSliderLabel;
        TLabel *AmpereSliderLabel;
        TVrSlider *AmpereSlider;
        TVrPowerButton *OutputButton;
        TUpDown *VoltUpDown;
        TUpDown *AmpereUpDown;
        TLabel *VoltSetLabel;
        TVrLabel *VoltDigitLabel;
        TVrLabel *AmpereDigitLabel;
        TVrLabel *VrLabel1;
        void __fastcall VoltSliderChange(TObject *Sender);
        void __fastcall VoltUpDownClick(TObject *Sender,
          TUDBtnType Button);
private:	// User declarations
        int VoltSet;
        int AmpereSet;
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
