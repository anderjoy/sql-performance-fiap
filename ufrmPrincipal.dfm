object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 528
  ClientWidth = 631
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    631
    528)
  PixelsPerInch = 96
  TextHeight = 13
  object btnCarregar: TButton
    Left = 12
    Top = 126
    Width = 75
    Height = 25
    Caption = 'Carregar'
    TabOrder = 0
    OnClick = btnCarregarClick
  end
  object edtServer: TLabeledEdit
    Left = 12
    Top = 21
    Width = 321
    Height = 21
    EditLabel.Width = 40
    EditLabel.Height = 13
    EditLabel.Caption = 'Servidor'
    TabOrder = 1
    Text = 'srvdatabase'
  end
  object edtUsername: TLabeledEdit
    Left = 12
    Top = 61
    Width = 105
    Height = 21
    EditLabel.Width = 36
    EditLabel.Height = 13
    EditLabel.Caption = 'Usu'#225'rio'
    TabOrder = 2
    Text = 'fiap'
  end
  object edtPassword: TLabeledEdit
    Left = 123
    Top = 61
    Width = 210
    Height = 21
    EditLabel.Width = 30
    EditLabel.Height = 13
    EditLabel.Caption = 'Senha'
    PasswordChar = '*'
    TabOrder = 3
    Text = 'fiap123'
  end
  object edtDatabase: TLabeledEdit
    Left = 12
    Top = 101
    Width = 321
    Height = 21
    EditLabel.Width = 46
    EditLabel.Height = 13
    EditLabel.Caption = 'Database'
    TabOrder = 4
    Text = 'PERFORMANCE'
  end
  object Memo1: TMemo
    Left = 12
    Top = 157
    Width = 611
    Height = 361
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 5
  end
  object btnProcBoleto: TButton
    Left = 90
    Top = 126
    Width = 75
    Height = 25
    Caption = 'Boletos'
    TabOrder = 6
    OnClick = btnProcBoletoClick
  end
  object btnPagar: TButton
    Left = 169
    Top = 126
    Width = 75
    Height = 25
    Caption = 'Pagar Boletos'
    TabOrder = 7
    OnClick = btnPagarClick
  end
  object btnEnvBoleto: TButton
    Left = 250
    Top = 126
    Width = 103
    Height = 25
    Caption = 'Enviar Boletos Msg'
    TabOrder = 8
    OnClick = btnEnvBoletoClick
  end
  object btnEnvBltArqv: TButton
    Left = 357
    Top = 126
    Width = 103
    Height = 25
    Caption = 'Enviar Boletos Arqv'
    TabOrder = 9
    OnClick = btnEnvBltArqvClick
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Database=PERFORMANCE'
      'User_Name=fiap'
      'Password=fiap123'
      'Server=ajesus.ddns.net,3312'
      'DriverID=MSSQL')
    Left = 364
    Top = 69
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    ScreenCursor = gcrHourGlass
    Left = 364
    Top = 13
  end
  object FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink
    Left = 500
    Top = 13
  end
  object FDConnection2: TFDConnection
    Params.Strings = (
      'Database=PERFORMANCE'
      'User_Name=fiap'
      'Password=fiap123'
      'Server=ajesus.ddns.net,3312'
      'DriverID=MSSQL')
    Left = 500
    Top = 69
  end
end
