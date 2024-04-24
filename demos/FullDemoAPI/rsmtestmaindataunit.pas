{ RSM fpc/lazarus component demo application

  Copyright (C) 2024 Lagunov Aleksey alexs75@yandex.ru

  This source is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
  License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later
  version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web at
  <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing to the Free Software Foundation, Inc., 51
  Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.
}

unit rsmtestMainDataUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, RSMApi, rxmemds, DB;

type

  { TMainData }

  TMainData = class(TDataModule)
    RSMApi1: TRSMApi;
    rxStores: TRxMemoryData;
    rxStoresADDRESS: TStringField;
    rxStoresID: TStringField;
    rxStoresIS_MAIN_STORE: TBooleanField;
    rxStoresRSM_CODE: TStringField;
  private

  public

  end;

var
  MainData: TMainData;

function JSNodeValueStr(ANode:TJSONObject; AKey:string):string;
function JSNodeValueFloat(ANode:TJSONObject; AKey:string):Double;
function JSNodeValueBool(ANode:TJSONObject; AKey:string):Boolean;

//

procedure testDefaultWriteLog(ALogType: TEventType; const ALogMessage: string);
procedure InitLocale;
implementation

uses rxlogging, rsmtestMainUnit;

{$R *.lfm}

function JSNodeValueStr(ANode: TJSONObject; AKey: string): string;
var
  J: TJSONData;
begin
  J:=ANode.Find(AKey);
  if Assigned(J) and not J.IsNull then
    Result:=J.AsString
  else
    Result:='';
end;

function JSNodeValueFloat(ANode: TJSONObject; AKey: string): Double;
var
  J: TJSONData;
begin
  J:=ANode.Find(AKey);
  if Assigned(J) and not J.IsNull then
    Result:=J.AsFloat
  else
    Result:=0;
end;

function JSNodeValueBool(ANode:TJSONObject; AKey:string):Boolean;
var
  J: TJSONData;
begin
  J:=ANode.Find(AKey);
  if Assigned(J) and not J.IsNull then
    Result:=J.AsBoolean
  else
    Result:=false;
end;

procedure testDefaultWriteLog(ALogType: TEventType; const ALogMessage: string);
begin
  if Assigned(RSMAPIMainForm) then
    RSMAPIMainForm.Memo1.Lines.Add(ALogMessage);
  RxDefaultWriteLog(ALogType, ALogMessage);
end;

procedure InitLocale;
begin
  DefaultFormatSettings.LongDateFormat:='dd.mm.yyyy';
  DefaultFormatSettings.ShortDateFormat:=DefaultFormatSettings.LongDateFormat;
  DefaultFormatSettings.DateSeparator:='.';
  DefaultFormatSettings.TimeSeparator:=':';
  DefaultFormatSettings.ThousandSeparator:=' ';
  DefaultFormatSettings.CurrencyString:='р.';
end;

end.

