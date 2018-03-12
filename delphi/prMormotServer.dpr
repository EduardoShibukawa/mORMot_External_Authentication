program prMormotServer;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SynCommons,
  SynLog,
  mORMot,
  SynSQLite3Static,
  mORMotHttpServer,
  System.SysUtils,
  PersonModel in 'Model\PersonModel.pas',
  AuthenticatedRESTServer in 'ServerRest\AuthenticatedRESTServer.pas',
  InterfaceCustomRestMethods in 'Interfaces\InterfaceCustomRestMethods.pas',
  ImpCustomRestMethods in 'Implementation\ImpCustomRestMethods.pas',
  AuthenticatedModel in 'Model\AuthenticatedModel.pas',
  NonAuthenticatedRESTServer in 'ServerRest\NonAuthenticatedRESTServer.pas',
  NonAuthenticatedModel in 'Model\NonAuthenticatedModel.pas',
  LicenseModel in 'Model\LicenseModel.pas';

var
  aAuthenticated: TAuthenticatedRESTServer;
  aNonAuthenticadedServer: TNonAuthenticatedRestServer;
  aHttpServer: TSQLHttpServer;
begin
  try
    aAuthenticated := TAuthenticatedRESTServer.Create;
    aNonAuthenticadedServer := TNonAuthenticatedRestServer.Create;
    aHttpServer := TSQLHttpServer.Create(SERVER_PORT,[aNonAuthenticadedServer, aAuthenticated],'+',useHttpApiRegisteringURI);
    try
      aHttpServer.AccessControlAllowOrigin := '*'; // allow cross-site AJAX queries
      writeln('Background server is running.'#10);
      write('Press [Enter] to close the server.');
      readln;
    finally
      aAuthenticated.Free;
      aHttpServer.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      readln;
    end;
  end;
end.
