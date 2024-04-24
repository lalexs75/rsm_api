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

unit rsmtstOrdersListUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, DB,
  fpjson, rxmemds, RxDBGrid, rxtooledit,
  rsmtstAbstractFrameUnit;

type

  { TrsmtstOrdersListFrame }

  TrsmtstOrdersListFrame = class(TrsmtstAbstractFrame)
    BufDataset1id: TStringField;
    Button1: TButton;
    Button2: TButton;
    dsItems: TDataSource;
    dsOrdersList: TDataSource;
    Label1: TLabel;
    Panel1: TPanel;
    RxDateEdit1: TRxDateEdit;
    RxDBGrid1: TRxDBGrid;
    RxDBGrid2: TRxDBGrid;
    rxItems: TRxMemoryData;
    rxItemsDOC_ID: TStringField;
    rxItemsprice: TFloatField;
    rxItemsquantity: TFloatField;
    rxItemsquantity_from_home: TFloatField;
    rxItemsquantity_from_other_dealer: TFloatField;
    rxItemsrsm_id: TStringField;
    rxItemsstatus: TStringField;
    rxItemstarget_dealer: TStringField;
    rxItemstotal_price: TFloatField;
    rxOrdersList: TRxMemoryData;
    rxOrdersListbill_requested: TBooleanField;
    rxOrdersListclient_inn: TStringField;
    rxOrdersListdealer_inn: TStringField;
    rxOrdersListdealer_inn_from: TStringField;
    rxOrdersListdelivery_address: TStringField;
    rxOrdersListdelivery_type: TStringField;
    rxOrdersListid: TStringField;
    rxOrdersListis_bid: TBooleanField;
    rxOrdersListis_order: TBooleanField;
    rxOrdersListis_paid: TBooleanField;
    rxOrdersListservice_text: TStringField;
    rxOrdersListspecification_requested: TBooleanField;
    rxOrdersListstatus: TStringField;
    rxOrdersListtotal_price: TFloatField;
    rxOrdersListtype: TStringField;
    Splitter1: TSplitter;
    procedure Button1Click(Sender: TObject);
    procedure rxItemsFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure rxOrdersListAfterScroll(DataSet: TDataSet);
  private

  public

  end;

implementation

uses rsmtestMainDataUnit, rxlogging;

{$R *.lfm}

{ TrsmtstOrdersListFrame }

procedure TrsmtstOrdersListFrame.Button1Click(Sender: TObject);
var
  J: TJSONData;
  i, it: Integer;
  J1, JI: TJSONObject;
  J2: TJSONArray;
begin
  rxOrdersList.DisableControls;
  rxItems.DisableControls;

  rxItems.Filtered:=false;
  rxOrdersList.CloseOpen;
  rxItems.CloseOpen;
  if (Sender as TComponent).Tag = 0 then
    J:=MainData.RSMApi1.GetOrders(RxDateEdit1.Date)
  else
    J:=MainData.RSMApi1.GetOrdersOutgoing(RxDateEdit1.Date);

  if Assigned(J) then
  begin
    RxWriteLog(etDebug, J.FormatJSON);
    for i:=0 to J.Count-1 do
    begin
      J1:=J.Items[i] as TJSONObject;
      rxOrdersList.Append;
      rxOrdersListid.AsString:=JSNodeValueStr(J1, 'id');

      rxOrdersListbill_requested.AsBoolean:=JSNodeValueBool(J1, 'bill_requested');
      rxOrdersListclient_inn.AsString:=JSNodeValueStr(J1, 'client_inn');
      rxOrdersListdelivery_address.AsString:=JSNodeValueStr(J1, 'delivery_address');
      rxOrdersListdelivery_type.AsString:=JSNodeValueStr(J1, 'delivery_type');

      rxOrdersListis_bid.AsBoolean:=JSNodeValueBool(J1, 'is_bid');
      rxOrdersListis_order.AsBoolean:=JSNodeValueBool(J1, 'is_order');
      rxOrdersListis_paid.AsBoolean:=JSNodeValueBool(J1, 'is_paid');

      rxOrdersListservice_text.AsString:=JSNodeValueStr(J1, 'service_text');
      rxOrdersListspecification_requested.AsBoolean:=JSNodeValueBool(J1, 'specification_requested');
      rxOrdersListstatus.AsString:=JSNodeValueStr(J1, 'status');
      rxOrdersListtotal_price.AsFloat:=JSNodeValueFloat(J1, 'total_price');
      rxOrdersListtype.AsString:=JSNodeValueStr(J1, 'type');
      rxOrdersListdealer_inn_from.AsString:=JSNodeValueStr(J1, 'dealer_inn_from');
      rxOrdersListdealer_inn.AsString:=JSNodeValueStr(J1, 'dealer_inn');
      rxOrdersList.Post;

      J2:=J1.Find('items') as TJSONArray;
      if Assigned(J2) then
      begin
        for it:=0 to J2.Count-1 do
        begin
          JI:=J2.Items[it] as TJSONObject;
          rxItems.Append;
          rxItemsDOC_ID.AsString:=rxOrdersListid.AsString;
          rxItemsrsm_id.AsString:=JSNodeValueStr(JI, 'rsm_id');
          rxItemsquantity.AsFloat:=JSNodeValueFloat(JI, 'quantity');
          rxItemsquantity_from_home.AsFloat:=JSNodeValueFloat(JI, 'quantity_from_home');
          rxItemsquantity_from_other_dealer.AsFloat:=JSNodeValueFloat(JI, 'quantity_from_other_dealer');
          rxItemstarget_dealer.AsString:=JSNodeValueStr(JI, 'target_dealer');
          rxItemsprice.AsFloat:=JSNodeValueFloat(JI, 'price');
          rxItemstotal_price.AsFloat:=JSNodeValueFloat(JI, 'total_price');
          rxItemsstatus.AsString:=JSNodeValueStr(JI, 'status');
          rxItems.Post;
        end;
      end;

    end;
    J.Free;
  end;
  rxOrdersList.First;
  rxItems.Filtered:=true;

  rxOrdersList.EnableControls;
  rxItems.EnableControls;
end;

procedure TrsmtstOrdersListFrame.rxItemsFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
  Accept:=rxItemsDOC_ID.AsString = rxOrdersListid.AsString;
end;

procedure TrsmtstOrdersListFrame.rxOrdersListAfterScroll(DataSet: TDataSet);
begin
  rxItems.First;
end;

end.

