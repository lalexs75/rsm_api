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

unit rsmtestMainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, RSMApi;

type

  { TRSMAPIMainForm }

  TRSMAPIMainForm = class(TForm)
    Button1: TButton;
    edtUserLogin: TEdit;
    edtUserPassword: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    TreeView1: TTreeView;
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure RSMApi1HttpStatus(Sender: TCustomRSMApi);
    procedure TreeView1Click(Sender: TObject);
  private
    FCurNode:TTreeNode;

    procedure SaveConfig;
    procedure LoadConfig;
    procedure AddControlFrame(ARoot, ACaption:string; AFrame:TFrame);
    procedure MakeOperationTree;
  public

  end;

var
  RSMAPIMainForm: TRSMAPIMainForm;

implementation
uses IniFiles, rxlogging, rxAppUtils, rsmtstStoresListUnit,
  rsmtstRemainsListUnit, rsmtstAbstractFrameUnit, rsmtstOrdersListUnit,
  rsmtestMainDataUnit;

{$R *.lfm}

{ TRSMAPIMainForm }

procedure TRSMAPIMainForm.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
  LoadConfig;
end;

procedure TRSMAPIMainForm.RSMApi1HttpStatus(Sender: TCustomRSMApi);
begin
  RxWriteLog(etDebug, '%d : %s', [Sender.ResultCode, Sender.ResultString]);
end;

procedure TRSMAPIMainForm.TreeView1Click(Sender: TObject);
var
  F: TrsmtstAbstractFrame;
begin
//  if FCurNode = TreeView1.Selected then Exit;
  if Assigned(FCurNode) then
  begin
    if Assigned(FCurNode.Data) then
    begin
      F:=TrsmtstAbstractFrame(FCurNode.Data);
      F.Visible:=false;
    end;
  end;

  if Assigned(TreeView1.Selected) and Assigned(TreeView1.Selected.Data) then
  begin
    FCurNode:=TreeView1.Selected;
    F:=TrsmtstAbstractFrame(FCurNode.Data);
    F.Visible:=true;
    F.BringToFront;
    F.ActivateFrame;
  end;
end;

procedure TRSMAPIMainForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  SaveConfig;
end;

procedure TRSMAPIMainForm.Button1Click(Sender: TObject);
begin
  MainData.RSMApi1.Login:=edtUserLogin.Text;
  MainData.RSMApi1.Password:=edtUserPassword.Text;
  MainData.RSMApi1.DoLogin;
  if MainData.RSMApi1.AuthorizationToken<>'' then
  begin
    edtUserLogin.Enabled:=false;
    edtUserPassword.Enabled:=false;
    Button1.Enabled:=false;
    MakeOperationTree;
  end;
end;

procedure TRSMAPIMainForm.Button3Click(Sender: TObject);
begin
  //RSMApi1.RefreshToken;
end;

procedure TRSMAPIMainForm.SaveConfig;
var
  Cfg: TIniFile;
begin
  Cfg:=TIniFile.Create(GetDefaultIniName);
  Cfg.WriteString('login', 'username', edtUserLogin.Text);
  Cfg.WriteString('login', 'password', edtUserPassword.Text);
  Cfg.Free;
end;

procedure TRSMAPIMainForm.LoadConfig;
var
  Cfg: TIniFile;
begin
  Cfg:=TIniFile.Create(GetDefaultIniName);
  edtUserLogin.Text:=Cfg.ReadString('login', 'username', '');
  edtUserPassword.Text:=Cfg.ReadString('login', 'password', '');
  Cfg.Free;
end;

procedure TRSMAPIMainForm.AddControlFrame(ARoot, ACaption: string;
  AFrame: TFrame);
function GetRoot(AName:string):TTreeNode;
var
  N: TTreeNode;
begin
  for N in TreeView1.Items do
    if N.Text = AName then
      Exit(N);
  Result:=TreeView1.Items.Add(nil, AName);
end;

var
  N: TTreeNode;
begin
  N:=TreeView1.Items.AddChild(GetRoot(ARoot), ACaption);
  N.Data:=AFrame;
  AFrame.Parent:=Panel2;
  AFrame.Align:=alClient;
  AFrame.Visible:=false;
  N.Parent.Expanded:=true;
  if not Assigned(FCurNode) then
    FCurNode:=N;
end;

procedure TRSMAPIMainForm.MakeOperationTree;
begin
  AddControlFrame('Справочники', 'Склады', TrsmtstStoresListFrame.Create(Self));
  AddControlFrame('Справочники', 'Остатки', TrsmtstRemainsListFrame.Create(Self));

  AddControlFrame('Заказы', 'Список', TrsmtstOrdersListFrame.Create(Self));


end;


end.

