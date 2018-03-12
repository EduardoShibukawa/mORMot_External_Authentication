unit AuthenticatedRESTServer;

interface
uses
  SysUtils,
  Classes,
  PersonModel,
  SynCommons,
  SynLog,
  mORMot,
  mORMotSQLite3,
  mORMotDB,
  SynSQLite3Static,
  SynDBODBC,
  SynDB,
  System.Generics.Collections,
  AuthenticatedModel;

type
  EAuthenticatedRESTServer = class(EORMException);

  TAuthenticatedRESTServer = class(TSQLRestServerDB)
  private type
    TUserName = string;
    TUserIP = string;
    TConnectionId = Integer;

    TUserConnection = class
    strict private
      FDic: TDictionary<Integer, TList<TConnectionId>>;
      function HashBobJenkins(AUserName: TUSerName; AUserIP: TUserIP): Integer;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Add(AUserName: TUserName; AUserIP: TUSerIp; AConnectionId: TConnectionId);
      procedure Remove(AUserName: TUserName; AUserIP: TUSerIp; AConnectionId: TConnectionId);

      function CountDistinct: Integer;

      function ContainsKey(AUserName: TUserName; AUserIP: TUserIP): Boolean;
    end;
  private
    FUserLimit: Integer;
    FUsersConnection: TUserConnection;

    function GetODBCFirebirdProps: TSQLDBConnectionProperties;

    function OnImpSessionCreate(Sender: TSQLRestServer; Session: TAuthSession;
    Ctxt: TSQLRestServerURIContext): Boolean;

    function OnImpSessionClose(Sender: TSQLRestServer; Session: TAuthSession;
    Ctxt: TSQLRestServerURIContext): Boolean;

    procedure ConfigServices;
  public
    constructor Create; reintroduce;
  published
    function Authentication(aParams: TSQLRestServerURIContext): Integer;
    {}
    function RemainingConnections: Integer;
    function CountConnection: Integer;
    function IsSafeDisconnect(aParams: TSQLRestServerURIContext): Integer;
  end;


implementation
uses System.Hash, ImpCustomRestMethods, InterfaceCustomRestMethods, System.IOUtils;

{ TRESTServer }

function TAuthenticatedRESTServer.Authentication(aParams: TSQLRestServerURIContext): Integer;
  function ValidaConexoesRestantes: Boolean;
  begin
    if FUsersConnection.ContainsKey(aParams.SessionUserName, aParams.SessionRemoteIP) then
    begin
      Result := ((Self.RemainingConnections + 1) >= 0)
    end
    else
    begin
      Result := (Self.RemainingConnections >= 0)
    end;
  end;
var
  Usuario:RawUTF8;
begin
  aParams.Results([-1]);
  if not UrlDecodeNeedParameters(aParams.Parameters,'User,CompanyID') then
  begin
    result := 404; // invalid Request
    exit;
  end;

  SQLite3Log.Enter.Log(sllInfo,'Autenticacao');
  SQLite3Log.Enter.Log(sllInfo,format('Read Usuario: %s',[Usuario]));
  if ValidaConexoesRestantes then
  begin
    SQLite3Log.Enter.Log(sllInfo,format('Número de Conexões: %d',[Self.CountConnection]));

    aParams.Results([Self.RemainingConnections]);
    Result := 200;
  end
  else
  begin
    SQLite3Log.Enter.Log(sllInfo,'Superado o Máximo de conexões - 405');
    Result := 405;
    aParams.Results([-1]);
  end;
end;

procedure TAuthenticatedRESTServer.ConfigServices;
var
  ServiceFactoryServer: TServiceFactoryServer;
begin
  ServiceFactoryServer := Self.ServiceDefine(TCustomRestMethods, [ICustomRestMethods], SERVICE_INSTANCE_IMPLEMENTATION);
  ServiceFactoryServer.SetOptions([], [optErrorOnMissingParam]);
end;


function TAuthenticatedRESTServer.RemainingConnections: Integer;
begin
  Result := FUserLimit - Self.CountConnection;
end;

constructor TAuthenticatedRESTServer.Create;
var
  aModel: TSQLModel;
begin
  FUsersConnection := TUserConnection.Create;
  FUserLimit := 2;


  SQLite3Log.Family.Level := LOG_VERBOSE;
  SQLite3Log.Family.PerThreadLog := ptIdentifiedInOnFile;
  SQLite3Log.Family.EchoToConsole := LOG_VERBOSE;

  aModel := CreateAuthenticadedModel;

  VirtualTableExternalRegisterAll(aModel,GetODBCFirebirdProps);
  inherited Create(aModel,':memory:',True);
  Self.AcquireExecutionMode[execORMGet] := amBackgroundORMSharedThread;
  Self.AcquireExecutionMode[execORMWrite] := amBackgroundORMSharedThread;

  Self.CreateMissingTables;

  ConfigServices;

  Self.OnSessionCreate := Self.OnImpSessionCreate;
  Self.OnSessionClosed := Self.OnImpSessionClose;
end;

function TAuthenticatedRESTServer.GetODBCFirebirdProps: TSQLDBConnectionProperties;
var
  aDBPath: String;
begin
  aDBPath := TPath.Combine(
    TDirectory.GetParent(TDirectory.GetParent(ExcludeTrailingPathDelimiter(GetCurrentDir))),
    'DataBase'
  );

  Result := TODBCConnectionProperties.Create(
    '',
    Concat(
      'DRIVER=Firebird/InterBase(r) driver;UID=SYSDBA;PWD=masterkey;',
      'DBNAME=', TPath.Combine(aDBPath,  'Authenticated.FDB'), ';'
    ), '',''
  );
end;

function TAuthenticatedRESTServer.IsSafeDisconnect(aParams: TSQLRestServerURIContext): Integer;
begin
  Result := 503;
  aParams.Results([0]);

  if fSessions.SafeCount > 0 then
  begin
    Self.SessionDelete(0, nil);
    aParams.Results([1]);
    Result := 200;
  end;
end;

function TAuthenticatedRESTServer.CountConnection: Integer;
begin
  Result := FUsersConnection.CountDistinct;
end;

function TAuthenticatedRESTServer.OnImpSessionClose(Sender: TSQLRestServer; Session: TAuthSession;
  Ctxt: TSQLRestServerURIContext): Boolean;
begin
  FUsersConnection.Remove(Session.UserName, Session.RemoteIP, Session.IDCardinal);
  Result := False;
end;

function TAuthenticatedRESTServer.OnImpSessionCreate(Sender: TSQLRestServer; Session: TAuthSession;
  Ctxt: TSQLRestServerURIContext): Boolean;
begin
  FUsersConnection.Add(Session.UserName, Session.RemoteIP, Session.IDCardinal);
  Result := False;
end;

{ TRESTServer.TConexoesUsuario }

procedure TAuthenticatedRESTServer.TUserConnection.Add(AUserName: TUserName; AUserIP: TUSerIp;
  AConnectionId: TConnectionId);
var
  aKey: Integer;
begin
  aKey := HashBobJenkins(AUserName, AUserIP);
  if not FDic.ContainsKey(aKey) then
    FDic.Add(aKey, TList<TConnectionId>.Create);

  FDic[aKey].Add(AConnectionId);
end;

function TAuthenticatedRESTServer.TUserConnection.ContainsKey(AUserName: TUserName; AUserIP: TUSerIP): Boolean;
begin
  Result := FDic.ContainsKey(HashBobJenkins(AUserName, AUserIP));
end;

function TAuthenticatedRESTServer.TUserConnection.CountDistinct: Integer;
begin
  Result := FDic.Count;
end;

constructor TAuthenticatedRESTServer.TUserConnection.Create;
begin
  FDic := TDictionary<Integer, TList<TConnectionId>>.Create;
end;

destructor TAuthenticatedRESTServer.TUserConnection.Destroy;
begin
  FDic.Free;
  inherited;
end;

function TAuthenticatedRESTServer.TUserConnection.HashBobJenkins(AUserName: TUSerName;
  AUserIP: TUserIP): Integer;
var
  Hash: THashBobJenkins;
begin
  Hash := THashBobJenkins.Create;
  result := Hash.GetHashValue(AUserName + AUserIP);
end;

procedure TAuthenticatedRESTServer.TUserConnection.Remove(AUserName: TUserName; AUserIP: TUSerIp;
  AConnectionId: TConnectionId);
var
  aKey: Integer;
begin
  aKey := HashBobJenkins(AUserName, AUserIP);;

  if FDic.ContainsKey(aKey)
      and FDic[aKey].Contains(AConnectionId)  then
  begin
    FDic[aKey].Remove(AConnectionId);

    if FDic[aKey].Count <= 0 then
      FDic.Remove(aKey);
  end;
end;

end.
