unit NonAuthenticatedModel;

interface
uses
  SynCommons,
  SynTable, // for TSynValidateText
  mORMot,
  PersonModel,
  LicenseModel;


function CreateNonAuthenticadedModel: TSQLModel;

const
  SERVER_ROOT = 'root_non_authenticaded';

implementation

function CreateNonAuthenticadedModel: TSQLModel;
begin
  Result := TSQLModel.Create([TPerson, TSQLAuthUser, TSQLAuthGroup, TLicense, TPersonInfo, TPersonInfoDest],SERVER_ROOT);
  TPerson.AddFilterOrValidate('Name',TSynValidateText.Create); // ensure exists
end;

end.
