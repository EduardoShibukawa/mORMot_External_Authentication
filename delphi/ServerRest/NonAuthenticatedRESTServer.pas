unit NonAuthenticatedRESTServer;

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
  NonAuthenticatedModel;

type
  ENonAuthenticatedRESTServer = class(EORMException);

  TNonAuthenticatedRestServer = class(TSQLRestServerDB)
  private
    function GetODBCFirebirdProps: TSQLDBConnectionProperties;

    procedure ConfigServices;
  public
    constructor Create; reintroduce;
  end;


implementation
uses System.Hash, ImpCustomRestMethods, InterfaceCustomRestMethods, System.IOUtils;

procedure TNonAuthenticatedRestServer.ConfigServices;
var
  ServiceFactoryServer: TServiceFactoryServer;
begin
  ServiceFactoryServer := Self.ServiceDefine(TCustomRestMethods, [ICustomRestMethods], SERVICE_INSTANCE_IMPLEMENTATION);
  ServiceFactoryServer.SetOptions([], [optErrorOnMissingParam]);
end;

constructor TNonAuthenticatedRestServer.Create;
var
  aModel: TSQLModel;
begin

  SQLite3Log.Family.Level := LOG_VERBOSE;
  SQLite3Log.Family.PerThreadLog := ptIdentifiedInOnFile;
  SQLite3Log.Family.EchoToConsole := LOG_VERBOSE;

  aModel := CreateNonAuthenticadedModel;

  VirtualTableExternalRegisterAll(aModel,GetODBCFirebirdProps);
  inherited Create(aModel,':memory:',false);
  Self.AcquireExecutionMode[execORMGet] := amBackgroundORMSharedThread;
  Self.AcquireExecutionMode[execORMWrite] := amBackgroundORMSharedThread;

  Self.CreateMissingTables;

  ConfigServices;
end;

function TNonAuthenticatedRestServer.GetODBCFirebirdProps: TSQLDBConnectionProperties;
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
      'DBNAME=', TPath.Combine(aDBPath,  'NonAuthenticated.FDB'), ';'
    ), '',''
  );
end;

end.
