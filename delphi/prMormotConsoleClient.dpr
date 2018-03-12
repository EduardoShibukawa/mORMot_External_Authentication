program prMormotConsoleClient;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  Classes,
  SynCommons,
  mORMot,
  mORMotHttpClient,
  System.SysUtils,
  PersonModel in 'Model\PersonModel.pas',
  Windows,
  AuthenticatedModel in 'Model\AuthenticatedModel.pas',
  LicenseModel in 'Model\LicenseModel.pas';

var
  aSemaforo: THandle;
  aSection: TRTLCriticalSection;

  procedure AddPerson(AHTTPServer: TSQLHttpClient);
  var
    aPerson: TPerson;
    aID: integer;
  begin

      //writeln('Add a new TPerson');
      aPerson := TPerson.Create;
      try
        Randomize;
        aPerson.Name := 'Name'+Int32ToUtf8(Random(10000));
        aID := aHTTPServer.Add(aPerson,true);
      finally
        aPerson.Free;
      end;
      writeln('Added TPerson.ID=',aID);
      aPerson := TPerson.Create(aHTTPServer,aID);
      try
        writeln('Name read for ID=',aPerson.ID,' from DB = "',aPerson.Name,'"');
      finally
        aPerson.Free;
      end;
  end;

  function Login(AHTTPServer: TSQLHttpClient; UserName, Password: String):Boolean;
  var
    CheckLicense: RawUTF8;
  begin
    Result := AHTTPServer.Model.Root = 'root_non_authenticaded';
    if not Result then
      if AHTTPServer.SetUser(UserName ,Password) then
      begin
        CheckLicense := AHTTPServer.CallBackGetResult(
          'Authentication',
          ['Admin',StringtoUTF8(UserName), 'CompanyID', '1']
        );
        Result := not (UTF8ToString(CheckLicense).ToInteger < 0);
      end;
  end;


  function AddPersonThread(Parameter: Pointer): Integer;
  var
    aHTTPServer: TSQLHttpClient;
    i,z: Integer;
  begin
    // Thread function must return result.
    Result := 0;
    // Wait for the semaphore, which limits us to 10 threads.
    aHTTPServer := TSQLHttpClientWinHTTP.Create('localhost', SERVER_PORT, TSQLModel(Parameter));
    try
      if (WaitForSingleObject(aSemaforo, INFINITE) = WAIT_OBJECT_0) then
      begin
        try
          EnterCriticalSection(aSection);
          try
            if Login(aHTTPServer, 'Admin', 'synopse') then
            begin
              for z := 0 to 1000 do
                AddPerson(aHTTPServer);
            end;
          finally
            LeaveCriticalSection(aSection);
          end;
          Sleep(100);
        finally
          ReleaseSemaphore(aSemaforo, 1, nil);
        end;
      end;
    finally
      aHTTPServer.Free;
    end;
  end;

var
  aModel: TSQLModel;
  i: Integer;
  Threads: array[1..50] of THandle;
  ThreadID: Cardinal;
begin
  try
    aModel := CreateAuthenticadedModel;
    try
      aSemaforo := CreateSemaphore(nil, 10, 10, nil);
      // Critical section for thread-0safe access to console.
      InitializeCriticalSection(aSection);
      // Just starting 50 threads.
      for I := Low(Threads) to High(Threads) do
      begin
        Threads[I] := BeginThread(nil, 0, AddPersonThread
          , Pointer(aModel), 0, ThreadID);
        // Let the thread do some actions now.
        Sleep(0)
      end;
      // Now wait for all threads to finish.
      WaitForMultipleObjects(Length(Threads), @Threads, True, INFINITE);
      // End of critical section.
      DeleteCriticalSection(aSection);
      // Close the semaphore.
      CloseHandle(aSemaforo);
      // All done.
      WriteLn('All done.');
      write(#10'Press [Enter] to quit');
      readln;
    finally
      aModel.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      readln;
    end
  end;
end.
