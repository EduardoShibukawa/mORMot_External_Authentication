unit uMainRESTClient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Generics.Collections, uClientConnection,
  Vcl.StdCtrls, Vcl.ExtCtrls, SynCommons, InterfaceCustomRestMethods, Mormot, PersonModel, LicenseModel,
  Vcl.ComCtrls;


type
  TCustomRecord = record helper for rCustomRecord
    procedure FillFromClient();
    function ToString: String;
  end;

  TComplicateCustomRecord = record helper for rCustomComplicatedRecord
    function ToString: String;
  end;

  TServiceCustomAnswerHelper = record helper for TServiceCustomAnswer
    function ToString: String;
  end;

  TLicensaTeste = class(TSynPersistent)
  private
    FNumeroUsuarios: Integer;
    FDataVencimento: TDateTime;
    FPessoa: TPerson;
    FData: TDateTime;
  published
    property Data: TDateTime read FData write FData;
    property DataVencimento: TDateTime read FDataVencimento write FDataVencimento;
    property NumeroUsuarios: Integer read FNumeroUsuarios write FNumeroUsuarios;
    property Pessoa: TPerson read FPessoa write FPessoa;
  end;

  TfMainRESTClient = class(TForm)
    btnConectar: TButton;
    lbledtUsuarios: TLabeledEdit;
    lbledtSenha: TLabeledEdit;
    btnRemoverConexao: TButton;
    btnExecutarMetodos: TButton;
    rgMetodos: TRadioGroup;
    chkAuthenticated: TCheckBox;
    lvConnections: TListView;
    lbllvConexoes: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnConectarClick(Sender: TObject);
    procedure btnRemoverConexaoClick(Sender: TObject);
    procedure btnExecutarMetodosClick(Sender: TObject);
  private
    { Private declarations }
    FConnectionList: TObjectList<TClientConnection>;
    FRestMethods: ICustomRestMethods;

    procedure TesteUsers;
    procedure TestORMClient;
    procedure TestDestList;

    procedure GravarLicensaNova;
    procedure RecuperarLicensa;


    function EncriptyToUTF8(AValue: RawUTF8; AEncripty: BOolean): RawUTF8;

    procedure ConfigCustomMethods(AConnection: TClientConnection);

    function Connect: TClientConnection;
    function Disconnect(AClientConnection: TClientConnection): Boolean;
  public
    { Public declarations }
  end;

var
  fMainRESTClient: TfMainRESTClient;

implementation
uses SynCrypto, mORMotHttpClient;

{$R *.dfm}

procedure TfMainRESTClient.btnConectarClick(Sender: TObject);
var
  aConnection: TClientConnection;
begin
  aConnection := Connect;
  if Assigned(aConnection) then
  begin
    with lvConnections.Items.Add do
    begin
      Caption := Concat(
        aConnection.HTTPServer.SessionID.ToString(),
        ' - ',
        aConnection.HTTPServer.Model.Root
      );
      Data := TObject(aConnection);
    end;
  end;
end;

procedure TfMainRESTClient.btnExecutarMetodosClick(Sender: TObject);
type
  TTipoMetodo = (
    tHelloWorld, tSUM, tGetCustomRecord, tSendCustomRecord, tSendMultipleRecords, tGetMethodCustomResult,
    tORMClient, tCustomUsers, tLicense, tPersonDestList
  );
var
  cr: rCustomRecord;
  ccr: rCustomComplicatedRecord;
  ServiceCustomAnswer: TServiceCustomAnswer;
begin
  if Assigned(FRestMethods) then
  begin
    case TTipoMetodo(rgMetodos.ItemIndex) of
      tHelloWorld:
      begin
        ShowMessage(FRestMethods.HelloWorld());
      end;
      tSUM:
      begin
        ShowMessage(FRestMethods.Sum(Random(100) + 0.6, Random(100) + 0.3).ToString);
      end;
      tGetCustomRecord:
      begin
        cr := FRestMethods.GetCustomRecord();
        ShowMessage(cr.ToString);
      end;
      tSendCustomRecord:
      begin
        cr.FillFromClient();
        FRestMethods.SendCustomRecord(cr);
        ShowMessage(cr.ToString);
      end;
      tSendMultipleRecords:
      begin
        cr.FillFromClient();
        ccr.SimpleString := 'Simple string, Простая строка, 単純な文字列';
        ccr.SimpleInteger := 1;
        ccr.AnotherRecord := cr;
        FRestMethods.SendMultipleCustomRecords(cr, ccr);

        ShowMessage(cr.ToString);
        ShowMessage(ccr.ToString);
      end;
      tGetMethodCustomResult:
      begin
        ServiceCustomAnswer := FRestMethods.GetMethodCustomResult();
        ShowMessage(ServiceCustomAnswer.ToString)
      end;
      tORMClient:
      begin
        TestORMClient;
      end;
      tCustomUsers:
      begin
        TesteUsers;
      end;
      tLicense:
      begin
        GravarLicensaNova;
        RecuperarLicensa;
      end;
      tPersonDestList:
      begin
        TestDestList;
      end;
    end;
  end;
end;

procedure TfMainRESTClient.btnRemoverConexaoClick(Sender: TObject);
begin
  if (lvConnections.ItemFocused <> nil)
      and (lvConnections.ItemIndex <> -1) then
  begin
    if Disconnect(TClientConnection(lvConnections.ItemFocused.Data)) then
    begin
      lvConnections.Items.Delete(lvConnections.ItemIndex);
    end;
  end;
end;

procedure TfMainRESTClient.ConfigCustomMethods(AConnection: TClientConnection);
begin
  AConnection.HTTPServer.ServiceDefine([ICustomRestMethods], SERVICE_INSTANCE_IMPLEMENTATION);
  AConnection.HTTPServer.Services.Resolve(ICustomRestMethods, FRestMethods);
end;

function TfMainRESTClient.Connect: TClientConnection;
begin
  Result := TClientConnection.Create(chkAuthenticated.Checked);
  if Result.Authentication(lbledtUsuarios.Text, lbledtSenha.Text) then
  begin
    ConfigCustomMethods(Result);
    FConnectionList.Add(Result);
  end
  else
  begin
    Result.Free;
    Result := nil;
  end;
end;

function TfMainRESTClient.Disconnect(AClientConnection: TClientConnection): Boolean;
var
  CheckValue: Integer;
  Response: RawUTF8;
begin
  Result := False;
  if Assigned(AClientConnection) then
  begin
    if AClientConnection.HTTPServer.Model.Root = 'root_authenticated' then
      CheckValue := AClientConnection.HTTPServer.CallBackGet('IsSafeDisconnect',[], Response)
    else CheckValue := 200;

    if CheckValue = 200 then
    begin
      FConnectionList.Delete(FConnectionList.IndexOf(AClientConnection));
      Result := True;
    end
    else
    begin
      ShowMessage('Erro!');
    end;
  end;
end;

function TfMainRESTClient.EncriptyToUTF8(AValue: RawUTF8; AEncripty: BOolean): RawUTF8;
var
  aRawValue: RawByteString;
  aBytes: TArray<System.Byte>;
begin
  aRawValue := AESSHA256(AValue, 'SACIROTO', AEncripty);
  RawByteStringToBytes(aRawValue, aBytes);
  Result := ToUTF8(StringOf(aBytes));
end;

procedure TfMainRESTClient.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FConnectionList.Free;
end;

procedure TfMainRESTClient.FormCreate(Sender: TObject);
begin
  FConnectionList := TObjectList<TClientConnection>.Create(True);
  lvConnections.Clear;
end;

procedure TfMainRESTClient.GravarLicensaNova;
var
  aPerson: TPerson;
  aLicensa: TLicense;
  aIdEmpresa: Integer;
begin
  TLicense.AutoFree(aLicensa);
  TPerson.AutoFree(aPerson, FConnectionList.First.HTTPServer, 1);

  aPerson.Document := '8787878787878';
  aIdEmpresa := FConnectionList.First.HTTPServer.Add(aPerson, True);

  aLicensa.UpdateDate := Now;
  aLicensa.UpdateDate := IncMonth(Now);
  aLicensa.UserLimit := 1;
  aLicensa.Person := aPerson.AsTSQLRecord;
  FConnectionList.First.HTTPServer.Add(aLicensa, True);
end;

procedure TfMainRESTClient.RecuperarLicensa;
  procedure Test(ALicense: TLicense);
  var
    aPerson: TPerson;
    aValid: Boolean;
    aJSON: RawUTF8;
    P: PUTF8Char;
  begin
    aPerson := TPerson.Create;
    try
      FConnectionList.First.HTTPServer.Retrieve(1, aPerson);
      ShowMessage(DecryptItAES(aPerson.License, aPerson.Document));

      aJSON := DecryptItAES(aPerson.License, aPerson.Document);
      P := @aJSON[1];
      ALicense := TLicense(JSONToNewObject(P, aValid));
      ShowMessage(ObjectToJSON(ALicense, [woHumanReadable]));
    finally
      aPerson.Free;
    end;
  end;
var
  aLicensa: TLicense;
  aValid: Boolean;
  aJSON: RawUTF8;
  P: PUTF8Char;
begin
  aJSON := DecryptItAES(FRestMethods.GetLicense('8787878787878'), 'SACIROTO');
  P := @aJSON[1];
  aLicensa := TLicense(JSONToNewObject(P, aValid));
  if aValid then
  begin
    Test(aLicensa);
  end;
end;

procedure TfMainRESTClient.TestDestList;
  procedure Add;
  var
    aPerson1: TPerson;
    aPerson2: TPerson;
    aPersonInfo: TPersonInfo;
    aClient: TSQLHttpClientWinHTTP;
    i: Integer;
    aDest: TPersonInfoDest;
  begin
    aClient := FConnectionList.First.HTTPServer;

    aDest := TPersonInfoDest.Create;
    aPerson1 := TPerson.Create(aClient, 1);
    aPerson2 := TPerson.Create(aClient, 2);
    aPersonInfo := TPersonInfo.Create;
    try
      aClient.TransactionBegin(TPerson);
      for i := 0 to 10 do
      begin
        aPersonInfo.MyDate := Now;
        aPersonInfo.MySize := Random(1000);

        aClient.Add(aPersonInfo, True);

        aDest.AssociationTime := Now;
        aDest.ManyAdd(aClient, aPerson1.ID, aPersonInfo.ID, True);
        aDest.ManyAdd(aClient, aPerson2.ID, aPersonInfo.ID, True);
      end;
      aClient.Commit;
    finally
      aDest.Free;
      aPerson1.Free;
      aPersonInfo.Free;
    end;
  end;

  procedure Search;
  var
    aClient: TSQLHttpClientWinHTTP;
    aPerson: TPerson;
    aIDArray: TIDDynArray;
    aId: Integer;
  begin
    aClient := FConnectionList.First.HTTPServer;
    aPerson := TPerson.Create(aClient, 1);
    try
      aPerson.InfoDestList.DestGet(aClient, aPerson.ID, aIDArray);
      for aId in aIDArray do
        ShowMessage(aId.ToString);
    finally
      aPerson.Free;
    end;
  end;

  procedure Delete;
  var
    aClient: TSQLHttpClientWinHTTP;
    aPerson: TPerson;
    aIDArray: TIDDynArray;
    aId: Integer;
  begin
    aClient := FConnectionList.First.HTTPServer;
    aPerson := TPerson.Create(aClient, 1);
    try
      aPerson.InfoDestList.DestGet(aClient, aPerson.ID, aIDArray);
      for aId in aIDArray do
      begin
        aPerson.InfoDestList.ManyDelete(aClient,aPerson.ID, aId);
      end;
    finally
      aPerson.Free;
    end;
  end;

begin
  Add;
  Search;
  Delete;
end;

procedure TfMainRESTClient.TesteUsers;
  procedure ConfigureDefaultUsers;
  var
    User: TSQLAuthUser;
  begin
    User := TSQLAuthUser.Create(FConnectionList.First.HTTPServer, 3);
    try
      User.PasswordPlain := 'Teste';
      FConnectionList.First.HTTPServer.Update(User)
    finally
    end;
  end;

  procedure CoonfigureDefaultGroups;
  var
    Group: TSQLAuthGroup;
  begin

    Group := TSQLAuthGroup.Create(FConnectionList.First.HTTPServer, 3);
    try
      Group.SessionTimeout := 1;
      FConnectionList.First.HTTPServer.Update(Group);
    finally
    end;
  end;
begin
  CoonfigureDefaultGroups;
  ConfigureDefaultUsers;
end;

procedure TfMainRESTClient.TestORMClient;
var
  aPerson: TPerson;
begin
  aPerson := TPerson.Create;
  try
    aPerson.Name := 'Eduardo';
    aPerson.DateTime := Now;
    FConnectionList.Last.HTTPServer.Add(aPerson, True)
  finally
    aPerson.Free;
  end;
end;

{ TCustomRecord }

procedure TCustomRecord.FillFromClient;
var
  i: Integer;
begin
  ResultCode := 200;
  ResultStr := 'Awesome we send this from client';
  ResultTimeStamp := Now();
  SetLength(ResultArray, 3);
  for i := 0 to 2 do
    ResultArray[i] := 'str_' + i.ToString();
end;

function TCustomRecord.ToString: String;
const
  JSONCustomRecord : array[1..6] of string =
    (
       '{',
       '  ResultCode: %d,',
       '  ResultStr:  %s,',
       '  ResultArray: [%s],',
       '  ResultTimeStamp: %s',
       '}'
    );
begin
  Result := Format(String.Join(sLineBreak, JSONCustomRecord), [
    Self.ResultCode,
    Self.ResultStr,
    string.Join(';', Self.ResultArray),
    FormatDateTime('dd/mm/yyyy', Self.ResultTimeStamp)
  ]);
end;

{ TComplicateCustomRecord }

function TComplicateCustomRecord.ToString: String;
const
  JSONCustomRecord : array[1..5] of string =
    (
       '{',
       '  SimpleInteger: %d,',
       '  SimpleString:  %s,',
       '  AnotherRecord: %s,',
       '}'
    );
begin
  Result := Format(String.Join(sLineBreak, JSONCustomRecord), [
    Self.SimpleInteger,
    Self.SimpleString,
    Self.AnotherRecord.ToString
  ]);
end;

{ TServiceCustomAnswerHelper }

function TServiceCustomAnswerHelper.ToString: String;
const
  JSONCustomRecord : array[1..5] of string =
    (
       '{',
       '  Status: %d,',
       '  Header: {%s},',
       '  Content: {%s},',
       '}'
    );
begin
  Result := Format(String.Join(sLineBreak, JSONCustomRecord), [
    Self.Status,
    Self.Header,
    Self.Content
  ]);

end;

end.
