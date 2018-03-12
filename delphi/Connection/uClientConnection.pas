unit uClientConnection;

interface
uses
  System.SysUtils,
  SynCommons,
  mORMot,
  mORMotHttpClient,
  AuthenticatedModel,
  NonAuthenticatedModel,
  InterfaceCustomRestMethods;

type
  TClientConnection = class
  private
    FModel: TSQLModel;
    FHTTPServer: TSQLHttpClient;
  public
    constructor Create(AAuthenticated: Boolean);
    destructor Destroy; override;

    function Authentication(AUsuario, ASenha: String): Boolean;
  published
    property HTTPServer: TSQLHttpClient read FHTTPServer;
  end;



implementation

{ TConexaoMormot }

function TClientConnection.Authentication(AUsuario, ASenha: String): Boolean;
var
  CheckLicense: RawUTF8;
begin
  Result := FModel.Root = 'root_non_authenticaded';
  if not Result then
    if FHTTPServer.SetUser(AUsuario ,ASenha) then
    begin
      CheckLicense := FHTTPServer.CallBackGetResult('Authentication',['User',StringtoUTF8(AUsuario), 'CompanyID', '1']);
      Result := not (UTF8ToString(CheckLicense).ToInteger < 0);
    end;
end;

constructor TClientConnection.Create(AAuthenticated: Boolean);
begin
  if AAuthenticated then
  begin
    FModel := CreateAuthenticadedModel;
  end
  else
  begin
    FModel := CreateNonAuthenticadedModel;
  end;


  FHTTPServer := TSQLHttpClientWinHTTP.Create('localhost', SERVER_PORT, FModel);
end;

destructor TClientConnection.Destroy;
begin
  FHTTPServer.SessionClose;
  FHTTPServer.Free;
  FModel.Free;
  inherited;
end;

end.
