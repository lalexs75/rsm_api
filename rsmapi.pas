{ RSM API interface library for FPC and Lazarus

  Copyright (C) 2024 Lagunov Aleksey alexs75@yandex.ru

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit RSMApi;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, fphttpclient, fpJSON;

const
  sRSMApiURL = 'http://rsm-parts.digitalwf.ru/';

type
  THttpMethod = (hmGET, hmPOST);
  TCustomRSMApi = class;
  TOnHttpStatusEnevent = procedure (Sender:TCustomRSMApi) of object;

  { TCustomRSMApi }

  TCustomRSMApi = class(TComponent)
  private
    FAuthorizationToken: string;
    FRefreshToken: string;
    FAuthorizationTokenTimeStamp:TDateTime;
    FDocument: TMemoryStream;
    FErrorText: TStrings;
    FLogin: string;
    FOnHttpStatus: TOnHttpStatusEnevent;
    FHTTP:TFPHTTPClient;
    FPassword: string;
    FResultCode: integer;
    FResultString: string;
    FResultText: TStrings;
    FServer: string;
    procedure SetServer(AValue: string);
    function SendCommand(AMethod:THttpMethod; ACommand:string; AParams:string; AData:TStream; const AllowedResponseCodes : array of integer; AMimeType:string = ''; ANeedSign:Boolean = false):Boolean;
    procedure SaveHttpData(ACmdName: string);
  protected
    property AuthorizationToken:string read FAuthorizationToken write FAuthorizationToken;
    property Server:string read FServer write SetServer;
    property Login:string read FLogin write FLogin;
    property Password:string read FPassword write FPassword;
    property OnHttpStatus:TOnHttpStatusEnevent read FOnHttpStatus write FOnHttpStatus;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function DoLogin:Boolean;
    function RefreshToken:Boolean;

    function SetRemains:TJSONData;
    function GetRemains(AStoreId:string; APage:Integer = 1):TJSONData;
    function GetStores:TJSONData;
    function GetOrders(ADatetimeFrom:TDateTime; ASkip:Integer = 0; ALimit:Integer = 100):TJSONData;
    function SetOrders:TJSONData;
    function GetOrdersOutgoing(ADatetimeFrom:TDateTime; ASkip:Integer = 0; ALimit:Integer = 100):TJSONData;
    function GetBills:TJSONData;
    function SetBills:TJSONData;
    function GetSpecifications:TJSONData;
    function SetSpecifications:TJSONData;

    property Document:TMemoryStream read FDocument;
    property ResultText:TStrings read FResultText;
    property ErrorText: TStrings read FErrorText;
    property ResultCode : integer read FResultCode;
    property ResultString : string read FResultString;
  published

  end;

  TRSMApi = class(TCustomRSMApi)
  public
    property AuthorizationToken;
  published
    property Server;
    property Login;
    property Password;
    property OnHttpStatus;
  end;

procedure AddURLParam(var S:string; AParam, AValue:string); overload;
procedure AddURLParam(var S: string; AParam:string; AValue: Integer); inline; overload;
procedure AddURLParam(var S:string; AParam:string); overload;

function rsmOrderStatusToStr(AStatus:string):string;
implementation
uses rxlogging, jsonparser, jsonscanner;

function HTTPEncode(const AStr: String): String;
const
  HTTPAllowed = ['A'..'Z','a'..'z', '*','@','.','_','-', '0'..'9', '$','!','''','(',')'];
var
  SS,S,R: PChar;
  H : String[2];
  L : Integer;
begin
  L:=Length(AStr);
  SetLength(Result,L*3); // Worst case scenario
  if (L=0) then
    exit;
  R:=PChar(Result);
  S:=PChar(AStr);
  SS:=S; // Avoid #0 limit !!
  while ((S-SS)<L) do
  begin
    if S^ in HTTPAllowed then
      R^:=S^
    else
    if (S^=' ') then
      R^:='+'
    else
    begin
      R^:='%';
      H:=HexStr(Ord(S^),2);
      Inc(R);
      R^:=H[1];
      Inc(R);
      R^:=H[2];
    end;
    Inc(R);
    Inc(S);
  end;
  SetLength(Result,R-PChar(Result));
end;

procedure AddURLParam(var S: string; AParam, AValue: string);
begin
  if S<>'' then S:=S + '&';
  if AValue <>'' then
  begin
    //AValue:=StringReplace(AValue, '#', '%23', [rfReplaceAll]);
    AValue:=StringReplace(AValue, '%', '%25', [rfReplaceAll]);
    S:=S + AParam + '=' + HTTPEncode(AValue)
  end
  else
    S:=S + AParam
end;

procedure AddURLParam(var S: string; AParam:string; AValue: Integer); inline;
begin
  AddURLParam(S, AParam, IntToStr(AValue));
end;

procedure AddURLParam(var S: string; AParam: string); inline;
begin
  AddURLParam(S, AParam, '');
end;

function rsmOrderStatusToStr(AStatus: string): string;
begin
  case AStatus of
    'NEW':Result:='Ожидает обработки';
    'RESERV':Result:='Зарезервирован';
    'TRANSIT':Result:='В транзите';
    'DELIVERED':Result:='Готов к выдаче';
    'REJECTED':Result:='Отменён';
    'ISSUED':Result:='Выдан';
  else
    Result:='Ошибка - статус не определён ('+AStatus+')';
  end;
end;

{ TCustomRSMApi }

procedure TCustomRSMApi.SetServer(AValue: string);
begin
  if FServer=AValue then Exit;
  if AValue <> '' then
  begin
    if AValue[Length(AValue)]<>'/' then
      AValue:=AValue + '/';
  end;
  FServer:=AValue;
end;

function TCustomRSMApi.SendCommand(AMethod: THttpMethod; ACommand: string;
  AParams: string; AData: TStream;
  const AllowedResponseCodes: array of integer; AMimeType: string;
  ANeedSign: Boolean): Boolean;
var
  FSrv: String;
  P: Int64;
begin
  Clear;
  if AParams <> '' then
    AParams:='?' + AParams;

  FHTTP.KeepConnection:=true;

  if FAuthorizationToken <> '' then
  begin
    FHTTP.AddHeader('Authorization', 'Bearer ' + FAuthorizationToken);
    FHTTP.AddHeader('accept', '*/*');
  end;

  FSrv:=FServer;

  if AMethod = hmGET then
  begin
    RxWriteLog(etDebug, 'GET: %s', [FSrv + ACommand + AParams]);
    FHTTP.HTTPMethod('GET',FSrv + ACommand + AParams,FDocument, AllowedResponseCodes);
  end
  else
  begin
   if AMimeType<>'' then
      FHTTP.AddHeader('Content-Type',AMimeType)
    else
      FHTTP.AddHeader('Content-Type','application/x-www-form-urlencoded');

//    if ANeedSign and Assigned(FOnSignData) then
//      DoSignRequestData(AData);

{    if (not Assigned(AData)) or (AData.Size = 0) then
      FHTTP.AddHeader('Content-Length', '0'); }

    FHTTP.RequestBody:=AData;
    RxWriteLog(etDebug, 'POST: %s', [FSrv + ACommand + AParams]);
    FHTTP.Post(FSrv + ACommand + AParams, FDocument);
  end;

  FResultCode := FHTTP.ResponseStatusCode;
  FResultString := FHTTP.ResponseStatusText;
  Result:=(FResultCode = 200) or (FResultCode = 201) or (FResultCode = 202);

  if (not Result) and (FDocument.Size > 0) then
  begin
    P:=FDocument.Position;
    FDocument.Position:=0;
    FErrorText.LoadFromStream(FDocument);
    FDocument.Position:=P;
  end;

  if Assigned(FOnHttpStatus) then
    FOnHttpStatus(Self);
end;

function TCustomRSMApi.DoLogin: Boolean;
var
  B: TJSONParser;
  FDATA, FUID, S: TJSONStringType;
  M: TStringStream;
  J: TJSONObject;
  J1: TJSONData;
begin
  if (FAuthorizationToken <> '') and (FAuthorizationTokenTimeStamp > (Now - (1 / 20) * 10)) then Exit;
  FAuthorizationToken:='';
  Result:=false;

  J:=TJSONObject.Create;
  J.Add('login', FLogin);
  J.Add('password', FPassword);
  M:=TStringStream.Create(J.FormatJSON);
  M.Position:=0;
  J.Free;

  if SendCommand(hmPOST, 'api/token/get/', '', M, [200], 'application/json') then
  begin
    SaveHttpData('api_token_get');
    if FResultCode = 200 then
    begin
      FDocument.Position:=0;
      B:=TJSONParser.Create(FDocument, DefaultOptions);
      J1:=B.Parse;

      if Assigned(J1.FindPath('error')) then
        FResultString:=J1.GetPath('Error').AsString
      else
      begin
        FAuthorizationToken:=J1.GetPath('access_token').AsString;
        FRefreshToken:=J1.GetPath('refresh_token').AsString;
        Result:=true;
      end;
      J1.Free;
      B.Free;
    end;
  end;
  M.Free;
end;

function TCustomRSMApi.RefreshToken: Boolean;
var
  B: TJSONParser;
  J1: TJSONData;
begin
  Result:=false;
  if SendCommand(hmPOST, 'api/token/refresh/', '', nil, [200, 400, 404], '') then
  begin
    FDocument.Position:=0;
    B:=TJSONParser.Create(FDocument, DefaultOptions);
    J1:=B.Parse;

    if Assigned(J1.FindPath('error')) then
      FResultString:=J1.GetPath('error').AsString
    else
    begin
      FAuthorizationToken:=J1.GetPath('access_token').AsString;
      FRefreshToken:=J1.GetPath('refresh_token').AsString;
      Result:=true;
    end;
    J1.Free;
    B.Free;
  end;
  SaveHttpData('api_token_refresh');
end;

function TCustomRSMApi.SetRemains: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.GetRemains(AStoreId: string; APage: Integer): TJSONData;
var
  S: String;
  P: TJSONParser;
begin
  DoLogin;
  Result:=nil;
  S:='';
  AddURLParam(S, 'store_id', AStoreId);
  AddURLParam(S, 'page', APage);
  if SendCommand(hmGET, 'api/remains/', S, nil, [200, 400, 404], 'application/json') then
  begin
    FDocument.Position:=0;
    P:=TJSONParser.Create(FDocument, DefaultOptions);
    Result:=P.Parse as TJSONData;
    P.Free;
  end;
  SaveHttpData('api_remains');
end;

function TCustomRSMApi.GetStores: TJSONData;
var
  P: TJSONParser;
begin
  DoLogin;
  Result:=nil;
  if SendCommand(hmGET, 'api/remains/stores/', '', nil, [200, 400, 404], 'application/json') then
  begin
    FDocument.Position:=0;
    P:=TJSONParser.Create(FDocument, DefaultOptions);
    Result:=P.Parse as TJSONData;
    P.Free;
  end;
  SaveHttpData('api_remains_stores');
end;

function TCustomRSMApi.GetOrders(ADatetimeFrom: TDateTime; ASkip:Integer; ALimit:Integer): TJSONData;
var
  S: String;
  P: TJSONParser;
begin
  DoLogin;
  Result:=nil;
  S:='';
  AddURLParam(S, 'datetimeFrom', FormatDateTime('YYYY-MM-DD''T''HH:NN:SS''Z''', ADatetimeFrom));
  //datetimeFrom (в формате 2023-06-01T09:12:33) — дату, начиная с которой нужно получить заказы,
  //skip (целое число) — количество заказов, которые нужно пропустить (по умолчанию — 0),
  if ASkip<>0 then;
    AddURLParam(S, 'skip', IntToStr(ASkip));
  //limit (целое число) — ограничение на количество заказов (по умолчанию — 100),
  if (ALimit>0) and (ALimit<>100) then;
    AddURLParam(S, 'limit', IntToStr(ALimit));
  //skip и limit можно использовать для постраничной навигации, т. к. за раз сервер может вернуть не более 100 заказов.
  // Все query-параметры не обязательны, если их не указывать то будут возвращены последние 100 заказов.

  if SendCommand(hmGET, 'api/orders/', S, nil, [200, 400, 404], 'application/json') then
  begin
    FDocument.Position:=0;
    P:=TJSONParser.Create(FDocument, DefaultOptions);
    Result:=P.Parse as TJSONData;
    P.Free;
  end;
  SaveHttpData('api_orders');
end;

function TCustomRSMApi.SetOrders: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.GetOrdersOutgoing(ADatetimeFrom: TDateTime;
  ASkip: Integer; ALimit: Integer): TJSONData;
var
  S: String;
  P: TJSONParser;
begin
  DoLogin;
  Result:=nil;
  S:='';
  AddURLParam(S, 'datetimeFrom', FormatDateTime('YYYY-MM-DD''T''HH:NN:SS''Z''', ADatetimeFrom));
  //datetimeFrom (в формате 2023-06-01T09:12:33) — дату, начиная с которой нужно получить заказы,
  //skip (целое число) — количество заказов, которые нужно пропустить (по умолчанию — 0),
  if ASkip<>0 then;
    AddURLParam(S, 'skip', IntToStr(ASkip));
  //limit (целое число) — ограничение на количество заказов (по умолчанию — 100),
  if (ALimit>0) and (ALimit<>100) then;
    AddURLParam(S, 'limit', IntToStr(ALimit));
  //skip и limit можно использовать для постраничной навигации, т. к. за раз сервер может вернуть не более 100 заказов.
  // Все query-параметры не обязательны, если их не указывать то будут возвращены последние 100 заказов.

  if SendCommand(hmGET, 'api/orders/outgoing/', S, nil, [200, 400, 404], 'application/json') then
  begin
    FDocument.Position:=0;
    P:=TJSONParser.Create(FDocument, DefaultOptions);
    Result:=P.Parse as TJSONData;
    P.Free;
  end;
  SaveHttpData('api_orders_outgoing');
end;

function TCustomRSMApi.GetBills: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.SetBills: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.GetSpecifications: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.SetSpecifications: TJSONData;
begin
  Result:=nil;
end;

procedure TCustomRSMApi.SaveHttpData(ACmdName: string);
var
  P: Int64;
begin
  if ExtractFileExt(ACmdName) = '' then
    ACmdName := ACmdName + '.bin';
  P:=FDocument.Position;
  FDocument.Position:=0;
  FDocument.SaveToFile(GetTempDir(false) + PathDelim + ACmdName);
  FDocument.Position:=P;
end;

constructor TCustomRSMApi.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FServer:=sRSMApiURL;
  FDocument:=TMemoryStream.Create;
  FResultText:=TStringList.Create;
  FErrorText:=TStringList.Create;
  FHTTP:=TFPHTTPClient.Create(nil);
  FHTTP.HTTPversion:='1.1';
//  FHTTP.OnVerifySSLCertificate:=@DoVerifyCertificate;
//  FHTTP.AfterSocketHandlerCreate:=@DoHaveSocketHandler;
  FHTTP.VerifySSlCertificate:=false;
end;

destructor TCustomRSMApi.Destroy;
begin
  FreeAndNil(FResultText);
  FreeAndNil(FDocument);
  FreeAndNil(FHTTP);
  FreeAndNil(FErrorText);
  inherited Destroy;
end;

procedure TCustomRSMApi.Clear;
begin
  FHTTP.Cookies.Clear;
  FHTTP.RequestHeaders.Clear;
  FHTTP.RequestBody:=nil;
  FResultText.Clear;
  FDocument.Clear;
  FErrorText.Clear;
end;

end.
