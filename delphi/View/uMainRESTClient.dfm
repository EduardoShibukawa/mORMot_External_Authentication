object fMainRESTClient: TfMainRESTClient
  Left = 0
  Top = 0
  Caption = 'fMainRESTClient'
  ClientHeight = 329
  ClientWidth = 737
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbllvConexoes: TLabel
    Left = 409
    Top = 25
    Width = 48
    Height = 13
    Caption = 'Conex'#245'es'
  end
  object btnConectar: TButton
    Left = 8
    Top = 16
    Width = 121
    Height = 33
    Caption = 'Connect'
    TabOrder = 0
    OnClick = btnConectarClick
  end
  object lbledtUsuarios: TLabeledEdit
    Left = 8
    Top = 88
    Width = 121
    Height = 21
    EditLabel.Width = 36
    EditLabel.Height = 13
    EditLabel.Caption = 'Usu'#225'rio'
    TabOrder = 1
    Text = 'Admin'
  end
  object lbledtSenha: TLabeledEdit
    Left = 151
    Top = 88
    Width = 121
    Height = 21
    EditLabel.Width = 30
    EditLabel.Height = 13
    EditLabel.Caption = 'Senha'
    TabOrder = 2
    Text = 'synopse'
  end
  object btnRemoverConexao: TButton
    Left = 152
    Top = 18
    Width = 120
    Height = 30
    Caption = 'Disconnect'
    TabOrder = 3
    OnClick = btnRemoverConexaoClick
  end
  object btnExecutarMetodos: TButton
    Left = 8
    Top = 289
    Width = 103
    Height = 25
    Caption = 'Execute'
    TabOrder = 4
    OnClick = btnExecutarMetodosClick
  end
  object rgMetodos: TRadioGroup
    Left = 8
    Top = 117
    Width = 382
    Height = 153
    Caption = 'Methods'
    Columns = 2
    Items.Strings = (
      'HelloWorld'
      'Sum'
      'GetCustomRecord'
      'SendCustomRecord'
      'SendMultipleCustomRecords'
      'GetMethodCustomResult'
      'ORM Cliente Test'
      'Custom Users'
      'License'
      'Person Dest List')
    TabOrder = 5
  end
  object chkAuthenticated: TCheckBox
    Left = 295
    Top = 20
    Width = 95
    Height = 25
    Caption = 'Authenticated'
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
  object lvConnections: TListView
    Left = 409
    Top = 20
    Width = 288
    Height = 226
    Columns = <
      item
        AutoSize = True
        Caption = 'Caption'
        MaxWidth = 300
        MinWidth = 150
      end>
    ColumnClick = False
    IconOptions.Arrangement = iaLeft
    IconOptions.AutoArrange = True
    Items.ItemData = {
      05460000000100000000000000FFFFFFFFFFFFFFFF00000000FFFFFFFF000000
      001672006F006F0074005F006E006F006E005F00610075007400680065006E00
      7400690063006100740065006400}
    RowSelect = True
    ShowColumnHeaders = False
    TabOrder = 7
    ViewStyle = vsReport
  end
end
