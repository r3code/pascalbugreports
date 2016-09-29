// The unit is VCL/LCL dependant!

unit bprScreenshot;

interface

uses
  bprClasses,
  {$ifndef FPC}
  Windows,
  {$else}
  LCLType, LCLIntf,
  {$endif}
  Graphics, Forms;

type
  TScreenShot = clasS(TBugReportInfoGatherer)
  public
    ScreenshotName  : TFNString;
    function GetInfo(const id: AnsiString; const InputData: array of AnsiString; var DataText: AnsiString; var FilesCount: Integer): Boolean; override;
    function GetFileName(const Index: Integer): TFNString; override;
  end;

implementation


{ TScreenShot }

function TScreenShot.GetFileName(const Index: Integer): TFNString;
begin
  Result:=ScreenshotName;
end;

procedure DoCaptureScreen(Dst: TBitmap);
var
  ScreenDC: HDC;
begin
  {$ifdef FPC}
  Dst := TBitmap.Create;
  ScreenDC := GetDC(0);
  Dst.LoadFromDevice(ScreenDC);
  ReleaseDC(ScreenDC);
  {$else}
  ScreenDC := GetDC(0);
  with Dst do
    BitBlt(Canvas.Handle, 0, 0, Width, Height, ScreenDC, 0, 0, SRCCOPY);
  ReleaseDC(0, ScreenDC);
  {$endif}
end;

function TScreenShot.GetInfo(const id: AnsiString;
  const InputData: array of AnsiString; var DataText: AnsiString;
  var FilesCount: Integer): Boolean;
var
  Capture: TBitmap;
begin
  try
    Capture := TBitmap.Create;
    try
      Capture.Width:=Screen.Width;
      Capture.Height:=Screen.Height;
      Capture.PixelFormat:=pf24bit;
      DoCaptureScreen(Capture);
      //todo: random name!
      ScreenshotName:='screenshot.bmp';
      Capture.SaveToFile(ScreenshotName);
      Result:=True;
    finally
      Capture.Free;
    end;
  except
    Result:=False;
  end;
end;

initialization
  RegisterGatherer(TScreenShot.Create, []);

end.