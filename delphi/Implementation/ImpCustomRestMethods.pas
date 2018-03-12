unit ImpCustomRestMethods;

interface

uses
  // RTL
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // mORMot
  mORMot,
  mORMotHttpServer,
  SynCommons,
  // Custom
  InterfaceCustomRestMethods, PersonModel, LicenseModel;

type
  TCustomRecord = record helper for rCustomRecord
    procedure FillResultFromServer();
  end;

  TCustomRestMethods = class(TInjectableObjectRest, ICustomRestMethods)
  private
    class procedure CustomWriter(const aWriter: TTextWriter; const aValue);
    class function CustomReader(P: PUTF8Char; var aValue; out aValid: Boolean): PUTF8Char;
  public
    function HelloWorld(): string;
    function Sum(val1, val2: Double): Double;
    function GetCustomRecord(): rCustomRecord;
    function SendCustomRecord(const CustomResult: rCustomRecord): Boolean;
    function SendMultipleCustomRecords(const CustomResult: rCustomRecord; const CustomComplicatedRecord: rCustomComplicatedRecord): Boolean;
    function GetMethodCustomResult(): TServiceCustomAnswer;
    function GetLicense(ADocument: RawUTF8): RawUTF8;
  end;

implementation
uses DateUtils, SynCrypto;

{ TCustomRecord }

procedure TCustomRecord.FillResultFromServer();
var
  i: Integer;
begin
  ResultCode := 200;
  ResultStr := 'Awesome we got it from server';
  ResultTimeStamp := Now();
  SetLength(ResultArray, 3);
  for i := 0 to 2 do
    ResultArray[i] := 'str_' + i.ToString();
end;

{ TRestMethods }

// [!] ServiceContext can be used from any method to access low level request data

function TCustomRestMethods.HelloWorld(): string;
begin
  Result := 'Hello world';
end;

function TCustomRestMethods.Sum(val1, val2: Double): Double;
begin
  Result := val1 + val2;
end;

class function TCustomRestMethods.CustomReader(P: PUTF8Char; var aValue; out aValid: Boolean): PUTF8Char;
var
  aLicensa: TDTOLicense absolute aValue;
  Values: TPUtf8CharDynArray;
begin
  Result := JSONDecode(P,['ID','UpdateDate','DueDate', 'UserLimit', 'Person'],Values);

  if Result = nil then
    aValid := false else begin
    aLicensa.ID := GetInt64(Values[0]);
    aLicensa.UpdateDate :=  TimeLogToDateTime(TTimelog(GetInt64(Values[1])));
    aLicensa.DueDate :=  TimeLogToDateTime(TTimelog(GetInt64(Values[2])));
    aLicensa.UserLimit := GetInteger(Values[3]);
    aLicensa.Person := GetInt64(Values[4]);
    aValid := true;
  end;
end;

class procedure TCustomRestMethods.CustomWriter(const aWriter: TTextWriter; const aValue);
var
  V: TDTOLicense absolute aValue;
begin
  aWriter.AddJSONEscape([
    'ID',V.ID,
    'UpdateDate',TimeLogFromDateTime(V.UpdateDate),
    'DueDate',TimeLogFromDateTime((V.DueDate)),
    'UserLimit',V.UserLimit,
    'Person',V.Person
  ]);
end;

function TCustomRestMethods.GetCustomRecord(): rCustomRecord;
begin
  Result.FillResultFromServer();
end;

function TCustomRestMethods.SendCustomRecord(const CustomResult: rCustomRecord): Boolean;
begin
  Result := CustomResult.ResultCode = 200;
end;

function TCustomRestMethods.SendMultipleCustomRecords(const CustomResult: rCustomRecord; const CustomComplicatedRecord: rCustomComplicatedRecord): Boolean;
  function SavePerson: Integer;
  var
    aPerson: TPerson;
  begin
    Result := -1;

    aPerson := TPerson.Create;
    try
      aPerson.DateTime := CustomComplicatedRecord.AnotherRecord.ResultTimeStamp;
      aPerson.OptimizedDate := TimeLogFromDateTime(aPerson.DateTime);
      aPerson.Name := CustomComplicatedRecord.SimpleString+Int32ToUtf8(Random(10000));
      Result := Self.Server.Add(aPerson, True);
    finally
      aPerson.Free;
    end;
  end;

  procedure GetPersonMethod1;
  var
    aPerson: TPerson;
  begin
    aPerson := TPerson.Create;
    try
      Self.Server.Retrieve(CustomComplicatedRecord.SimpleInteger, aPerson);
      Writeln('Name read for ID=',aPerson.ID,' from DB = "',aPerson.Name,'"');
    finally
      aPerson.Free;
    end;
  end;

  procedure GetPersonMethod2;
  var
    aPerson: TPerson;
  begin
    aPerson := TPerson.Create(Self.Server, CustomComplicatedRecord.SimpleInteger);
    try
      Self.Server.Retrieve(CustomComplicatedRecord.SimpleInteger, aPerson);
      Writeln('Name read for ID=',aPerson.ID,' from DB = "',aPerson.Name,'"');
    finally
      aPerson.Free;
    end;
  end;

  procedure DeletePerson(Id: Integer);
  begin
    Self.Server.Delete(TPerson, Id);
  end;

  procedure UpdatePersonDate(Id: Integer);
  var
    aPerson: TPerson;
  begin
    aPerson := TPerson.Create;
    try
      Self.Server.Retrieve(Id, aPerson);
      aPerson.DateTime := IncDay(EncodeDateTime(1900, 1, 1, 0, 0, 0, 0), aPerson.ID);
      aPerson.OptimizedDate := TimeLogFromDateTime(aPerson.DateTime);

      Self.Server.Update(aPerson)
    finally
      aPerson.Free;
    end;
  end;


  procedure GetAllFilteredPerson;
  var
    aPersonName1XX: TPerson;
    aDate: TDateTime;
  begin
    aPersonName1XX := TPerson.CreateAndFillPrepare(
      Self.Server,
      'NAME LIKE ?' +
      ' AND DateTime >= ?' +
      ' AND OptimizedDate <= ?'
      ,
      [
        '%Name1%',
        DateTimeToSQL(Now), //Iso8601ToSQL(DateTimeToIso8601(Now))
        TimeLogFromDateTime(Now)
      ]
    );
    try
      while aPersonName1XX.FillOne do
      begin
        Writeln(ObjectToJSONDebug(aPersonName1XX));
        UpdatePersonDate(aPersonName1XX.ID);
      end;
    finally
      aPersonName1XX.Free;
    end;
  end;

  procedure GetFilteredPersonColumns;
  var
    aList: TSQLTableJSON;
    Row: integer;
  begin
    aList := Self.Server.MultiFieldValues(
      TPerson,
      'NAME',
      'NAME LIKE ?' +
      ' AND DateTime >= ?' +
      ' AND OptimizedDate <= ?',
      [
        '%Name1%',
        DateTimeToSQL(Now), //Iso8601ToSQL(DateTimeToIso8601(Now))
        TimeLogFromDateTime(Now)
      ]
    );

    if aList = nil then
      raise Exception.Create('Impossible to retrieve data from Server' );

    try
      for Row := 1 to aList.RowCount do
        Writeln('Name=', aList.GetU(Row, 0));
    finally
      aList.Free;
    end;
  end;

  procedure UpdateAllPersonWithTransaction;
  var
    aList: TSQLTableJSON;
    Row: integer;
  begin
    aList := Self.Server.MultiFieldValues(
      TPerson,
      'ID'
    );

    if aList = nil then
      raise Exception.Create('Impossible to retrieve data from Server' );

    try
//      if Self.Server.TransactionBegin(TPerson) then
      begin
        try
          for Row := 1 to aList.RowCount do
//            UpdatePersonDate(aList.GetU(Row, 0));

//          Self.Server.Commit;
        except
//          Self.Server.RollBack;
        end;
      end;
    finally
      aList.Free;
    end;
  end;

begin
  GetPersonMethod1;
  GetPersonMethod2;
  GetAllFilteredPerson;
  GetFilteredPersonColumns;
//  UpdateAllPersonWithTransaction;
  DeletePerson(SavePerson);

  Result := CustomResult.ResultCode = CustomComplicatedRecord.AnotherRecord.ResultCode;
end;

function TCustomRestMethods.GetLicense(ADocument: RawUTF8): RawUTF8;
var
  aLicense: TLicense;
  aLicense2: TLicense;
  P: PUTF8Char;
  aValid: Boolean;
  aRecordLicense: TDTOLicense;
begin
  TTextWriter.RegisterCustomJSONSerializer(
    TypeInfo(TDTOLicense),
    TCustomRestMethods.CustomReader,
    TCustomRestMethods.CustomWriter
   );

  aLicense := TLicense.CreateAndFillPrepareJoined(
    Self.Server,
    'DOCUMENT LIKE ?',
    [],
    [ADocument]
  );

  while aLicense.FillOne do
  begin
    aLicense := TLicense.Create(Self.Server, aLicense.ID);
    Result := ObjectToJSON(aLicense, [woStoreClassName]);
    Result := LicenseModel.EncryptItAES(Result, 'SACIROTO');
    Result := AESSHA256(Result, 'SACIROTO', True);
    (*
    Result := AESSHA256(Result, 'SACIROTO', False);
    P := @Result[1];
    aLicense2 := TLicense(JSONToNewObject(P, aValid));
    if aValid then
    begin
      aRecordLicense.ID := aLicense.ID;
      aRecordLicense.UserLimit := aLicense.UserLimit;
      aRecordLicense.DueDate := aLicense.DueDate;
      aRecordLicense.Date := aLicense.Date;
      aRecordLicense.Person := aLicense.Person.ID;
      aRecordLicense.Date := aLicense.Date;

      Result := RecordSaveJSON(aRecordLicense, TypeInfo(TDTOLicense));
      aRecordLicense.ID := 0;
      aRecordLicense.UserLimit := 0;
      aRecordLicense.DueDate := Now;
      aRecordLicense.Date := Now;
      aRecordLicense.Person := 0;

      P := @Result[1];
      RecordLoadJSON(aRecordLicense,P,TypeInfo(TDTOLicense));
      Result := RecordSaveJSON(aRecordLicense, TypeInfo(TDTOLicense));
    end;
    *)
  end;
end;

function TCustomRestMethods.GetMethodCustomResult(): TServiceCustomAnswer;
begin
  Result.Header := 'Content-type: UTF-8';
  Result.Content := 'I am custom result, no "result:[]" used.';
  Result.Status := 200;
end;

end.
