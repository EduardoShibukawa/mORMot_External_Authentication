unit AuthenticatedModel;

interface
uses
  SynCommons,
  SynTable, // for TSynValidateText
  mORMot,
  PersonModel,
  LicenseModel;


function CreateAuthenticadedModel: TSQLModel;

const
  SERVER_ROOT = 'root_authenticated';
  SERVER_PORT = '888';


implementation

function CreateAuthenticadedModel: TSQLModel;
begin
  Result := TSQLModel.Create([TPerson, TSQLAuthUser, TSQLAuthGroup, TLicense, TPersonInfo, TPersonInfoDest],SERVER_ROOT);
  TPerson.AddFilterOrValidate('Name',TSynValidateText.Create); // ensure exists
end;

end.
