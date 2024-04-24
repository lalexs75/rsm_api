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

unit rsmtstRemainsListUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, DB, fpjson, rxmemds, rsmtstAbstractFrameUnit,
  RxDBGrid, rxlookup;

type

  { TrsmtstRemainsListFrame }

  TrsmtstRemainsListFrame = class(TrsmtstAbstractFrame)
    Button1: TButton;
    dsData: TDataSource;
    dsRemainsList: TDataSource;
    dsStores: TDataSource;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    rxDataSTORE_ID: TStringField;
    RxDBGrid1: TRxDBGrid;
    RxDBLookupCombo1: TRxDBLookupCombo;
    rxData: TRxMemoryData;
    rxRemainsList: TRxMemoryData;
    rxRemainsListquantity: TFloatField;
    rxRemainsListrsm_id: TStringField;
    rxStores: TRxMemoryData;
    rxStoresADDRESS: TStringField;
    rxStoresID: TStringField;
    rxStoresIS_MAIN_STORE: TBooleanField;
    rxStoresRSM_CODE: TStringField;
    procedure Button1Click(Sender: TObject);
  private

  public
    constructor Create(TheOwner: TComponent); override;
    procedure ActivateFrame; override;
  end;

implementation

uses rsmtestMainDataUnit, rxlogging;

{$R *.lfm}

{ TrsmtstRemainsListFrame }

procedure TrsmtstRemainsListFrame.Button1Click(Sender: TObject);
var
  J, JI: TJSONData;
  i: Integer;
  S: String;
  J1: TJSONObject;
begin
  rxRemainsList.CloseOpen;
  J:=MainData.RSMApi1.GetRemains(rxDataSTORE_ID.AsString, StrToIntDef(Edit1.Text, 1));
  if Assigned(J) then
  begin
    RxWriteLog(etDebug, J.FormatJSON);
    JI:=J.FindPath('items');
    if Assigned(JI) then
    begin
      for i:=0 to JI.Count-1 do
      begin
        J1:=JI.Items[i] as TJSONObject;
        rxRemainsList.Append;
        rxRemainsListrsm_id.AsString:=JSNodeValueStr(J1, 'rsm_id');
        rxRemainsListquantity.AsFloat:=JSNodeValueFloat(J1, 'quantity');
        rxRemainsList.Post;
      end;
    end;
    J.Free;
  end;
end;

constructor TrsmtstRemainsListFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  rxData.Open;
  rxData.Append;
end;

procedure TrsmtstRemainsListFrame.ActivateFrame;
begin
  inherited ActivateFrame;
  if (not rxStores.Active) or (rxStores.RecordCount = 0) then
  begin
    rxStores.CloseOpen;
    rxStores.LoadFromDataSet(MainData.rxStores, -1, lmAppend);
    rxStores.Open;
  end;
  Button1.Enabled:=rxStores.Active and (rxStores.RecordCount > 0);
  if not Button1.Enabled then
    Label3.Caption:='Необходимо получить список складов'
  else
    Label3.Caption:=' ';
end;

end.

