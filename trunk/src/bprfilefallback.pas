{$i-}
unit
  bprFileFallback;

// WARNING: Thread unsafe!

interface

uses
  bprClasses, bprUtils,

  //todo: replace SysUtils by file enumeration util functions!
  SysUtils;

type
  TUnsentReport = record
    Descr : WideString;
    Date  : TBugReportDate;
    //more?
  end;

procedure SetFallbackDir(const ADir: WideString);
function GetUnsentReportsCount: Integer;
procedure ResendReports;

type
  TUnsentReportEnumProc = procedure (const Unsent: TUnsentReport; UserData: Pointer);
  TUnsentReportEnumEvent = procedure (const Unsent: TUnsentReport) of object;

procedure GetUnsentReportInfo(enumproc: TUnsentReportEnumProc; UserData: Pointer); overload;
procedure GetUnsentReportInfo(enumeven: TUnsentReportEnumEvent); overload;

implementation

var
  fFallbackDir : WideString;
const
  fFallbackExt = '.brp';
  fFallbackName = 'bugreports'+fFallbackExt;

type
  TFileFallbackSender = class(TBugReportSender)
    function SendData(const ErrorText, ErrorID: AnsiString;
      const FileNames: array of TFNString; FilesCount: Integer): Boolean; override;
  end;

procedure SetFallbackDir(const ADir: WideString);
begin
  fFallbackDir:=ADir;
end;

function GetUnsentReportsCount: Integer;
begin
  //todo!
  Result:=0;
end;

procedure ResendReports;
begin

end;

procedure GetUnsentReportInfo(enumproc: TUnsentReportEnumProc; UserData: Pointer);
begin

end;

procedure GetUnsentReportInfo(enumeven: TUnsentReportEnumEvent);
begin

end;


{ TFileFallbackSender }

function TFileFallbackSender.SendData(const ErrorText, ErrorID: AnsiString;
  const FileNames: array of TFNString; FilesCount: Integer): Boolean;
var
  f       : Text;
  dstname : String;
  date    : TBugReportDate;
begin
  dstname:=IncludeTrailingPathDelimiter(fFallbackDir)+fFallbackName;
  Assign(f, dstName);
  if FileExists(dstName) then Append(f)
  else Rewrite(f);

  bprUtils.GetTime(date);
  with date do
    writeln(f, 'Report: ',year,'-',month,'-', day, ' ', hour,':',min,':',mls);
  writeln(f, 'ID: '+ErrorID);
  writeln(f, 'Text: --- ');
  writeln(f, ErrorText);
  writeln(f, 'Infos: --- ');
  writeln(f, 'End of Report');
  writeln(f);
  Close(f);
  Result:=True;
end;

initialization
  RegisterSender( TFileFallbackSender.Create, True);

end.
