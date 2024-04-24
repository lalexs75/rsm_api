program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  rxlogging,
  rsmtestMainUnit,
  rsmtstStoresListUnit,
  rsmtestMainDataUnit,
  rsmtstRemainsListUnit,
  rsmtstAbstractFrameUnit,
  rsmtstOrdersListUnit;

{$R *.res}

begin
  OnRxLoggerEvent:=@testDefaultWriteLog;
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.{%H-}UpdateFormatSettings:=false;
   InitLocale;
  Application.CreateForm(TMainData, MainData);
  Application.CreateForm(TRSMAPIMainForm, RSMAPIMainForm);
  Application.Run;
end.

