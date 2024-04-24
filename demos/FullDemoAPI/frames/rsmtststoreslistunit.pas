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

unit rsmtstStoresListUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, DB, fpjson, rsmtstAbstractFrameUnit, RxDBGrid,
  rxmemds;

type

  { TrsmtstStoresListFrame }

  TrsmtstStoresListFrame = class(TrsmtstAbstractFrame)
    Button1: TButton;
    dsStores: TDataSource;
    Panel1: TPanel;
    RxDBGrid1: TRxDBGrid;
    rxStores: TRxMemoryData;
    rxStoresADDRESS: TStringField;
    rxStoresID: TStringField;
    rxStoresIS_MAIN_STORE: TBooleanField;
    rxStoresRSM_CODE: TStringField;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

implementation

uses rsmtestMainDataUnit, rxlogging;

{$R *.lfm}

{ TrsmtstStoresListFrame }

procedure TrsmtstStoresListFrame.Button1Click(Sender: TObject);
var
  J: TJSONData;
  S: TJSONStringType;
  i: Integer;
  J1: TJSONObject;
begin
  rxStores.CloseOpen;
  J:=MainData.RSMApi1.GetStores;
  if Assigned(J) then
  begin
    RxWriteLog(etDebug, J.FormatJSON);
    for i:=0 to J.Count-1 do
    begin
      J1:=J.Items[i] as TJSONObject;
      rxStores.Append;
      rxStoresID.AsString:=JSNodeValueStr(J1, 'ID');
      rxStoresADDRESS.AsString:=JSNodeValueStr(J1, 'ADDRESS');
      rxStoresIS_MAIN_STORE.AsBoolean:=JSNodeValueBool(J1, 'IS_MAIN_STORE');
      rxStoresRSM_CODE.AsString:=JSNodeValueStr(J1, 'RSM_CODE');
      rxStores.Post;
    end;
    J.Free;
  end;

  rxStores.First;
  MainData.rxStores.CloseOpen;
  MainData.rxStores.LoadFromDataSet(rxStores, -1, lmAppend);
end;

end.

