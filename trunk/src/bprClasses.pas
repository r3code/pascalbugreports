//todo: Avoid using AnsiString and dynamic arrays to be safe of OutOfMemory exceptions???

unit
  bprClasses;

interface

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

uses
  bprSync, bprUtils;

type
  TFNString = WideString;

type
 TMsgType = (dmsgLog, dmsgWarn, dmsgError);

type
  TBugReportInfoGatherer = class(TObject)
    function GetInfo(const id: AnsiString; const InputData: array of AnsiString; var DataText: AnsiString; var FilesCount: Integer): Boolean; virtual; abstract;
    function GetFileName(const Index: Integer): TFNString; virtual; abstract;
  end;

  TBugReportSender = class(TObject)
    function SendData(const ErrorText, ErrorID: AnsiString;
      const FileNames: array of TFNString; FilesCount: Integer): Boolean; virtual; abstract;
  end;

procedure RegisterSender(elem: TBugReportSender; isFallback: Boolean = False);
procedure RegisterGatherer(gather: TBugReportInfoGatherer; const ErrorID: array of AnsiString);

function CreateBugReport(const Msg: AnsiString; const ErrorID: AnsiString): Boolean;

implementation

var
  globalCS  : TBugReportCriticalSection;
  Senders   : TList;
  Gatherers : TList;

type

  TSenderInfo = class(TObject)
    Sender      : TBugReportSender;
    isFallback  : Boolean;
    constructor Create(ASender: TBugReportSender; AisFallback: Boolean);
    destructor Destroy; override;
    function Send(const ErrorText, ErrorID: AnsiString; const FileNames: array of TFNString; FilesCount: Integer): Boolean;
  end;

  { TGatherInfo }

  TGatherInfo = class(TObject)
    ErrorIDs  : array of AnsiString;
    Gatherer  : TBugReportInfoGatherer;

    InfoText    : AnsiString;
    FilesCount  : Integer;
    FileNames   : array of TFNString;
    constructor Create(AGatherer: TBugReportInfoGatherer; const AIDs: array of AnsiString);
    destructor Destroy; override;
    function Gather(const ID: AnsiString): Boolean;
  end;

{ TGatherInfo }

constructor TGatherInfo.Create(AGatherer: TBugReportInfoGatherer; const AIDs: array of AnsiString);
var
  i : Integer;
begin
  Gatherer:=AGatherer;
  SetLength(ErrorIDs, length(aids));
  for i:=0 to length(aids)-1 do 
    ErrorIDs[i]:=aids[i];
end;

destructor TGatherInfo.Destroy;
begin
  Gatherer.Free;
  inherited;
end;

function TGatherInfo.Gather(const ID: AnsiString): Boolean;
var
  i,j : Integer;
begin
  try
    InfoText:='';
    FilesCount:=0;
    Result:=Gatherer.GetInfo(ID, [], InfoText, FilesCount);
    for i:=0 to FilesCount-1 do
      FileNames[i]:= Gatherer.GetFileName(i);

    // pack file names to avoid FileNames[i]<>'' in future
    j:=0;
    for i:=0 to FilesCount-1 do begin
      if FileNames[i]<>'' then inc(j)
      else if i<>j then FileNames[j]:=FileNames[i];
    end;
    FilesCount:=j;

  except
    FilesCount:=0;
    Result:=false;
  end;
end;

procedure InitGlobals;
begin
  globalCS := CreateCS;
  Senders := TList.Create;
  Gatherers := TList.Create;
end;

procedure ReleaseGlobals;
begin
  senders.Clear(True);
  senders.Free;
  gatherers.Clear(True);
  gatherers.Free;
  globalCS.Free;
end;

procedure RegisterSender(elem: TBugReportSender; isFallback: Boolean = False);
var
  i : Integer;
begin
  if not Assigned(elem) then Exit;
  globalCS.Lock;
  try
    if isFallback then begin
      if (Senders.Count>0) and TSenderInfo(Senders[Senders.Count-1]).isFallback then begin
        i:=Senders.Count-1;
        try
          TSenderInfo(Senders[i]).Sender.Free;
        except
        end;
        TSenderInfo(Senders[i]).Sender:=elem;
      end else
        Senders.Insert( TSenderInfo.Create(elem, True), Senders.Count);
    end else
      senders.Insert(TSenderInfo.Create(elem, False), 0);
  finally
    globalCS.Unlock;
  end;
end;

procedure RegisterGatherer(gather: TBugReportInfoGatherer; const ErrorID: array of AnsiString);
begin
  gatherers.Add( TGatherInfo.Create(gather, ErrorID));
end;


function DoCreateBugReport(const Msg: AnsiString; const ErrorID: AnsiString): Boolean;
var
  i,j     : Integer;
  txt     : AnsiString;
  files   : array of TFNString;
  ginfo   : TGatherInfo;
  fcnt    : Integer;
  sender  : TSenderInfo;
const
  LineEnd = #10;
begin
  Result:=False;
  try
    txt:=Msg;

    fcnt:=0;    
    for i:=0 to Gatherers.Count-1 do begin
      ginfo:=TGatherInfo(Gatherers[i]);
      if ginfo.Gather(ErrorID) then begin
        if ginfo.InfoText<>'' then
          txt:=txt+LineEnd+ginfo.InfoText;

        for j:=0 to ginfo.FilesCount - 1 do begin
          if fcnt=length(files) then begin
            if fcnt=0 then SetLength(files, 4)
            else SetLength(files, fcnt*2);
          end;
          files[fcnt]:=ginfo.FileNames[j];
          inc(fcnt);
        end;
      end;
    end;

    for i:=0 to senders.count-1 do begin
      sender:=TSenderInfo(senders[i]);
      Result:=sender.Send(Msg, ErrorID, files, fcnt);
      if Result then Exit;
    end;

  except
  end;
end;

function CreateBugReport(const Msg: AnsiString; const ErrorID: AnsiString): Boolean;
begin
  //todo: CHECK! It should be done from the MainThread ONLY!!!
  globalCS.Lock;
  try
    Result:=DoCreateBugReport(Msg, ErrorID);
  finally
    globalCS.Unlock;
  end;
end;

{ TSenderInfo }

constructor TSenderInfo.Create(ASender: TBugReportSender; AisFallback: Boolean);
begin
  Sender:=ASender;
  isFallback:=AisFallback;
end;

destructor TSenderInfo.Destroy;
begin
  Sender.Free;
  inherited;
end;

function TSenderInfo.Send(const ErrorText, ErrorID: AnsiString;
  const FileNames: array of TFNString; FilesCount: Integer): Boolean;
begin
  try
    Result:=Sender.SendData(ErrorText, ErrorID, FileNames, FilesCount);
  except
    Result:=False;
  end;
end;

initialization
  InitGlobals;

finalization
  ReleaseGlobals;

end.
