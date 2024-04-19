{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit fpcRSMApi;

{$warn 5023 off : no warning about unused units}
interface

uses
  RSMApi, lazRegisterRSM, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('lazRegisterRSM', @lazRegisterRSM.Register);
end;

initialization
  RegisterPackage('fpcRSMApi', @Register);
end.
