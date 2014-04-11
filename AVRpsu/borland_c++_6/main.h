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
#include "CommPort.h"
#include <ExtCtrls.hpp>
#include "VrMeter.hpp"
//---------------------------------------------------------------------------
// OutState
#define OFF     0
#define ON      1

// CommState
#define IDLE    0
#define GET_V   1
#define SET_V   2
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
        TVrLabel *OutputLabel;
        TLabel *AmpereSetLabel;
        TCommPort *CommPort;
        TTimer *Meaurement;
    TVrLabel *TemperatureLabel;
        void __fastcall VoltSliderChange(TObject *Sender);
        void __fastcall VoltUpDownClick(TObject *Sender,
          TUDBtnType Button);
        void __fastcall AmpereSliderChange(TObject *Sender);
        void __fastcall AmpereUpDownClick(TObject *Sender,
          TUDBtnType Button);
        void __fastcall OutputButtonClick(TObject *Sender);
        void __fastcall MeaurementTimer(TObject *Sender);
        void __fastcall CommPortDataReceived(TObject *Sender,
          const char *Buffer, unsigned Length);
private:	// User declarations
        int VoltSet;
        int AmpereSet;
        int OutState;

        AnsiString CommBuffer;      // Serial port buffer
        int CommState;              // Describes what data is in the buffer
        bool CommRxFlag;            // Data received flag
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
