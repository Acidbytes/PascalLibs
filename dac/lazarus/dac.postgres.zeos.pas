// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0.1
unit DAC.Postgres.Zeos;

{$mode ObjFPC}{$H+}

interface

uses
  fpJSON, SysUtils, Classes,
  ZConnection, ZDataset;

type
  TConnection = TZConnection;
  TQuery = TZQuery;

  TDAC = class
  private
    FConnection: TConnection;
    FQuery: TQuery;
    FSchema: string;
    function GetDefaultLibDir: string;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TConnection;
    function getQuery: TQuery;
    function getConnectionStatus: string;
  end;

implementation

{ TDAC }

constructor TDAC.Create(aJSON: TJSONObject);
begin
  FConnection := nil;
  FQuery := nil;
  FSchema := '';
  FConnection := TConnection.Create(nil);
  try
    with FConnection do
    begin
      LoginPrompt := False;
      HostName := aJSON.Get('dbserver', '');
      Port := aJSON.Get('dbport', 5432);
      User := aJSON.Get('dbuser', '');
      Password := aJSON.Get('dbpassword', '');
      Protocol := 'postgresql';
      Database := aJSON.Get('banco', '');
      LibraryLocation := GetDefaultLibDir;
    end;
    FQuery := TQuery.Create(nil);
    FQuery.Connection := FConnection;
    FSchema := aJSON.Get('schema', '');
    FConnection.Connect;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  FQuery.Connection := nil;
  if Assigned(FQuery)      then FreeAndNil(FQuery);
  if Assigned(FConnection) then FreeAndNil(FConnection);
  inherited;
end;

function TDAC.getConnection: TConnection;
begin
  Result := FConnection;
end;

function TDAC.getConnectionStatus: string;
var
  JSONobj: TJSONObject;
  I: integer;
begin
  FQuery.SQL.Clear;
  FQuery.SQL.Add('SELECT ');
  FQuery.SQL.Add('  COUNT(*) AS TOTALCONNECTIONS');
  FQuery.SQL.Add(', (SELECT COUNT(*) FROM pg_stat_activity ' +
    'WHERE state = ''active'') AS TOTALACTIVE');
  FQuery.SQL.Add(', (SELECT COUNT(*) FROM pg_stat_activity ' +
    'WHERE state = ''idle'') AS TOTALIDLE');
  FQuery.SQL.Add('  FROM pg_stat_activity');
  FQuery.Open;
  JSONobj := TJSONObject.Create;
  try
    for I := 0 to pred(FQuery.FieldCount) do
      JSONobj.Add(FQuery.Fields.Fields[I].FieldName,
        FQuery.Fields.Fields[I].AsString);
    Result := JSONobj.AsJSON;
  finally
    JSONobj.Free;
  end;
end;

function TDAC.GetDefaultLibDir: string;
var
  DefaultDir: string;
begin
  Result := '';
  DefaultDir := ExtractFileDir(ParamStr(0));

  if FileExists(DefaultDir + '\lib\libpq.dll') then
    Result := DefaultDir + '\lib\libpq.dll'
  else if FileExists(DefaultDir + '\libpq.dll') then
    Result := DefaultDir + '\libpq.dll'
  else
    raise Exception.Create('libpq.dll' +
      ' precisa estar na raiz do executável ou na pasta \lib\');
end;

function TDAC.getQuery: TQuery;
begin
  Result := FQuery;
  FQuery.Properties.Add('emulate_prepares=true');
end;

end.
