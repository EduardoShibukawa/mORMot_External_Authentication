unit LicenseModel;

interface

uses
  System.SysUtils,
  SynCrypto,
  SynCommons,
  SynTable, // for TSynValidateText
  mORMot,
  PersonModel;

type
  TDTOLicense = record
    ID: TID;
    UserLimit: Integer;
    DueDate: TDateTime;
    Person: TID;
    UpdateDate: TDateTime;
  end;

  TLicense = class(TSQLRecord)
  private
    FUserLimit: Integer;
    FDueDate: TDateTime;
    FPerson: TPerson;
    FUpdateDate: TDateTime;
    FCompanyId: Integer;
  published
    property UpdateDate: TDateTime read FUpdateDate write FUpdateDate;
    property DueDate: TDateTime read FDueDate write FDueDate;
    property UserLimit: Integer read FUserLimit write FUserLimit;
    property Person: TPerson read FPerson write FPerson;
    property CompanyId: Integer read FCompanyId write FCompanyId;
  end;

  function EncryptItAES(const s:string; const aKey: string): string;
  function DecryptItAES(const s:string; const aKey: string): string;

implementation

  function EncryptItAES(const s:string; const aKey: string): string;
  var
    key : TSHA256Digest;
    aes : TAESCFB;
    _s:RawByteString;
  begin
    Result := EmptyStr;
    SynCommons.HexToBin(Pointer(SHA256(StringToUTF8(aKey))), @key, 32);

    aes := TAESCFB.Create(key, 256);
    try
      _s := StringToUTF8(s);
      _s := BinToBase64(aes.EncryptPKCS7(_s, True));
      Result := UTF8ToString(_s);
    finally
      aes.Free;
    end;
  end;

  function DecryptItAES(const s:string; const aKey: string): string;
  var
    key : TSHA256Digest;
    aes : TAESCFB;
    _s:RawByteString;
  begin
    Result := EmptyStr;
    SynCommons.HexToBin(Pointer(SHA256(StringToUTF8(aKey))), @key, 32);

    aes := TAESCFB.Create(key, 256);
    try
      _s     := StringToUTF8(s);
      try
        _s     := aes.DecryptPKCS7(Base64ToBin(_s), True);
      except
        Exit(EmptyStr);
      end;
      Result := UTF8ToString(_s);
    finally
      aes.Free;
    end;
  end;

end.
