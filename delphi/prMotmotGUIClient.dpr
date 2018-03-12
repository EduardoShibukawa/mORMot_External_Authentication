program prMotmotGUIClient;

uses
  Vcl.Forms,
  uMainRESTClient in 'View\uMainRESTClient.pas' {fMainRESTClient},
  uClientConnection in 'Connection\uClientConnection.pas',
  PersonModel in 'Model\PersonModel.pas',
  InterfaceCustomRestMethods in 'Interfaces\InterfaceCustomRestMethods.pas',
  AuthenticatedModel in 'Model\AuthenticatedModel.pas',
  NonAuthenticatedModel in 'Model\NonAuthenticatedModel.pas',
  LicenseModel in 'Model\LicenseModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMainRESTClient, fMainRESTClient);
  Application.Run;
end.
