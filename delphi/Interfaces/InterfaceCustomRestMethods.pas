unit InterfaceCustomRestMethods;

interface

uses
  mORMot, PersonModel, SynCommons;

type
  rCustomRecord = record
    ResultCode: integer;
    ResultStr: string;
    ResultArray: array of string;
    ResultTimeStamp: TDateTime;
  end;

  rCustomComplicatedRecord = record
    SimpleString: string;
    SimpleInteger: integer;
    AnotherRecord: rCustomRecord;
  end;

  ICustomRestMethods = interface(IInvokable)
    ['{4EB49814-A4A9-40D2-B85A-137DDF43C72C}']
    function HelloWorld(): string;
    function Sum(val1, val2: Double): Double;
    function GetCustomRecord(): rCustomRecord;
    function SendCustomRecord(const CustomResult: rCustomRecord): Boolean;
    function SendMultipleCustomRecords(const CustomResult: rCustomRecord; const CustomComplicatedRecord: rCustomComplicatedRecord): Boolean;
    function GetMethodCustomResult(): TServiceCustomAnswer;
    function GetLicense(ADocument: RawUTF8): RawUTF8;
  end;

const
  SERVICE_INSTANCE_IMPLEMENTATION = TServiceInstanceImplementation.sicSingle;

implementation

initialization

TInterfaceFactory.RegisterInterfaces([TypeInfo(ICustomRestMethods)]); // to use directly IRestMethods instead of TypeInfo(IRestMethods)

end.
