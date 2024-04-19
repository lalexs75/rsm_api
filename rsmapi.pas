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
    procedure RefreshToken;

    function SetRemains:TJSONData;
    function GetRemains:TJSONData;
    function GetStores:TJSONData;
    function GetOrders:TJSONData;
    function SetOrders:TJSONData;
    function GetOrdersOutgoing:TJSONData;
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
  published
    property Server;
    property Login;
    property Password;
    property OnHttpStatus;
  end;

implementation
uses rxlogging, jsonparser, jsonscanner;

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
  R: Int64;
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
      R:=FDocument.Size;
      FDocument.Position:=0;
      B:=TJSONParser.Create(FDocument, DefaultOptions);
      J1:=B.Parse;
      FAuthorizationToken:=J1.GetPath('access_token').AsString;
      FRefreshToken:=J1.GetPath('refresh_token').AsString;
      J1.Free;
      B.Free;
    end;
  end;
  M.Free;
end;

procedure TCustomRSMApi.RefreshToken;
begin

end;

function TCustomRSMApi.SetRemains: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.GetRemains: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.GetStores: TJSONData;
var
  P: TJSONParser;
begin
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

function TCustomRSMApi.GetOrders: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.SetOrders: TJSONData;
begin
  Result:=nil;
end;

function TCustomRSMApi.GetOrdersOutgoing: TJSONData;
begin
  Result:=nil;
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
