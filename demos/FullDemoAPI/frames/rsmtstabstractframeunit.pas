unit rsmtstAbstractFrameUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls;

type

  { TrsmtstAbstractFrame }

  TrsmtstAbstractFrame = class(TFrame)
  private

  public
    procedure ActivateFrame; virtual;
  end;

implementation

{$R *.lfm}

{ TrsmtstAbstractFrame }

procedure TrsmtstAbstractFrame.ActivateFrame;
begin

end;

end.

