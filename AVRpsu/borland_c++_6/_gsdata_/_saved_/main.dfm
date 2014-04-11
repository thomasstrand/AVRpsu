object MainForm: TMainForm
  Left = 379
  Top = 105
  Width = 633
  Height = 632
  Caption = 'AVRpsu'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object MainDisplay: TVrDisplay
    Left = 16
    Top = 64
    Width = 593
    Height = 90
    ShadowColor1 = clBlack
    ShadowColor2 = clBlack
    ShadowLayout = soTopLeft
    Color = clBlack
    object VoltDigitGroup: TVrDigitGroup
      Left = 16
      Top = 16
      Width = 120
      Height = 60
      Hint = 'Measured Voltage'
      Decimals = 1
      Digits = 3
      Palette.Low = clBlack
      Palette.High = clLime
      LeadingZero = False
      ParentShowHint = False
      ShowHint = True
    end
    object AmpereDigitGroup: TVrDigitGroup
      Left = 440
      Top = 16
      Width = 120
      Height = 60
      Hint = 'Measured current'
      Decimals = 2
      Digits = 3
      Palette.Low = clBlack
      Palette.High = clLime
      ParentShowHint = False
      ShowHint = True
    end
    object VoltDigitLabel: TVrLabel
      Left = 136
      Top = 16
      Width = 20
      Height = 20
      ColorHighlight = clBlack
      ColorShadow = clBlack
      Color = clBlack
      Caption = 'V'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object AmpereDigitLabel: TVrLabel
      Left = 560
      Top = 16
      Width = 20
      Height = 20
      ColorHighlight = clBlack
      ColorShadow = clBlack
      Color = clBlack
      Caption = 'A'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object VrLabel1: TVrLabel
      Left = 264
      Top = 32
      Width = 60
      Height = 25
      ColorHighlight = clBlack
      ColorShadow = clBlack
      Color = clBlack
      Caption = 'OFF'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
  end
  object MainSettingsGroupBox: TGroupBox
    Left = 16
    Top = 176
    Width = 593
    Height = 145
    Caption = 'Settings'
    TabOrder = 1
    object VoltSliderLabel: TLabel
      Left = 16
      Top = 40
      Width = 36
      Height = 13
      Caption = 'Voltage'
    end
    object AmpereSliderLabel: TLabel
      Left = 352
      Top = 40
      Width = 34
      Height = 13
      Caption = 'Current'
    end
    object VoltSetLabel: TLabel
      Left = 192
      Top = 40
      Width = 22
      Height = 13
      Caption = '0.0V'
    end
    object VoltSlider: TVrSlider
      Left = 16
      Top = 55
      Width = 201
      Height = 36
      Hint = 'Set voltage'
      MaxValue = 250
      Orientation = voHorizontal
      KeyIncrement = 10
      Bevel.InnerShadow = clBtnShadow
      Bevel.InnerHighlight = clBtnHighlight
      Bevel.InnerWidth = 2
      Bevel.InnerStyle = bsLowered
      Bevel.InnerSpace = 1
      Bevel.InnerColor = clBlack
      Bevel.OuterShadow = clBtnShadow
      Bevel.OuterHighlight = clBtnHighlight
      Bevel.OuterStyle = bsRaised
      Bevel.OuterOutline = osOuter
      Palette.Low = clGreen
      Palette.High = clLime
      OnChange = VoltSliderChange
      TabOrder = 0
    end
    object AmpereSlider: TVrSlider
      Left = 352
      Top = 55
      Width = 201
      Height = 36
      Hint = 'Set current'
      Orientation = voHorizontal
      Bevel.InnerShadow = clBtnShadow
      Bevel.InnerHighlight = clBtnHighlight
      Bevel.InnerWidth = 2
      Bevel.InnerStyle = bsLowered
      Bevel.InnerSpace = 1
      Bevel.InnerColor = clBlack
      Bevel.OuterShadow = clBtnShadow
      Bevel.OuterHighlight = clBtnHighlight
      Bevel.OuterStyle = bsRaised
      Bevel.OuterOutline = osOuter
      Palette.Low = clGreen
      Palette.High = clLime
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
    end
    object OutputButton: TVrPowerButton
      Left = 264
      Top = 56
      Width = 65
      Height = 33
      Hint = 'Toggle the output'
      Palette.Low = clGreen
      Palette.High = clLime
      Caption = 'Output'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object VoltUpDown: TUpDown
      Left = 217
      Top = 55
      Width = 20
      Height = 36
      Hint = 'Step voltage'
      Associate = VoltSlider
      Min = 0
      Max = 250
      ParentShowHint = False
      Position = 0
      ShowHint = True
      TabOrder = 3
      Wrap = False
      OnClick = VoltUpDownClick
    end
    object AmpereUpDown: TUpDown
      Left = 553
      Top = 55
      Width = 20
      Height = 36
      Hint = 'Step current'
      Associate = AmpereSlider
      Min = 0
      ParentShowHint = False
      Position = 0
      ShowHint = True
      TabOrder = 4
      Wrap = False
    end
  end
end
