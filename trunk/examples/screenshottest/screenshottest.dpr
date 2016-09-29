program screenshottest;

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

{$ifdef MSWindows}
{$APPTYPE CONSOLE}
{$endif}


uses
  SysUtils,
  bprClasses, bprScreenshot;

var
  repdir  : String;
begin
  repdir:=ExtractFileDir(ParamStr(0))+PathDelim+'rep';
  writeln('creating bug report...');
  CreateBugReport('Text report message', 'TestBugID');
  writeln('test done.');
end.

