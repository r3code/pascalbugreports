program sdktest1;

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

{$ifdef MSWindows}
{$APPTYPE CONSOLE}
{$endif}


uses
  SysUtils,
  bprClasses, bprFileFallback;

var
  repdir  : String;
begin
  repdir:=ExtractFileDir(ParamStr(0))+PathDelim+'rep';
  ForceDirectories(repdir);
  SetFallbackDir(repdir);


  writeln('unsent reports: ', GetUnsentReportsCount);

  writeln('creating bug report...');
  CreateBugReport('Text report message', 'TestBugID');
  writeln('test done.');
end.

