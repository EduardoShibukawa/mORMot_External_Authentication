unit PersonModel;

interface

uses
  SynCommons,
  SynTable, // for TSynValidateText
  mORMot;

type
  TPersonInfo = class;
  TPerson = class;

  TPersonInfoDest = class(TSQLRecordMany)
  private
    fTime: TDateTime;
    fDest: TPersonInfo;
    fSource: TPerson;
  published
    property Source: TPerson read fSource;
    property Dest: TPersonInfo read fDest;
    property AssociationTime: TDateTime read fTime write fTime;
  end;

  TPersonInfo = class(TSQLRecord)
  private
    FMyDate: TDateTime;
    FMySize: Int64;
  published
    property MyDate: TDateTime read FMyDate write FMyDate;
    property MySize: Int64 read FMySize write FMySize;
  end;

  TPerson = class(TSQLRecord) // TSQLRecord has already ID: integer primary key
  private
    fName: RawUTF8;
    FOptimizedDate: TTimeLog;
    FDateTime: TDateTime;
    FInfoOne: TPersonInfo;
    FInfoTwo: TPersonInfo;
    FDocument: RawUTF8;
    FLicense: RawUTF8;
    fDestList: TPersonInfoDest;
  published
    /// ORM will create a NAME VARCHAR(80) column
    property Name: RawUTF8 index 80 read fName write fName;
    property Document: RawUTF8 index 22 read FDocument write FDocument;
    property DateTime: TDateTime read FDateTime write FDateTime;
    property OptimizedDate: TTimeLog read FOptimizedDate write FOptimizedDate;
    property InfoOne: TPersonInfo read FInfoOne write FInfoOne;
    property InfoTwo: TPersonInfo read FInfoTwo write FInfoTwo;
    property License: RawUTF8 read FLicense write FLicense;
    property InfoDestList: TPersonInfoDest read fDestList;
  end;

implementation

end.
