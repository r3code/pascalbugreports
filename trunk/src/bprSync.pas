unit bprSync;

interface
{$ifndef FPC}
uses
  Windows;
{$else}
  {$mode delphi}{$h+}
{$endif}

type
  TBugReportCriticalSection = class(TObject)
  public
    constructor Create; virtual; abstract;
    procedure Lock; virtual; abstract;
    procedure Unlock; virtual; abstract;
  end;
  TBugReportCriticalSectionClass = class of TBugReportCriticalSection;

procedure RegisterCSClass(AClass: TBugReportCriticalSectionClass);
function CreateCS: TBugReportCriticalSection;

//todo:
//function GetCurrentThread: TThreadID;

implementation

var
  CSClass: TBugReportCriticalSectionClass = nil;
  
type
  
  { TDefaultCriticalSection }

  TDefaultCriticalSection = class(TBugReportCriticalSection)
  private
    fcs : TRTLCriticalSection;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Lock; override;
    procedure Unlock; override;
  end;
  
{$ifndef FPC}
procedure InitCriticalSection(var fcs: TRTLCriticalSection);
begin
  InitializeCriticalSection(fcs);
end;

procedure DoneCriticalSection(var fcs: TRTLCriticalSection);
begin
  DeleteCriticalsection(fcs);
end;
{$endif}

{ TDefaultCriticalSection }

constructor TDefaultCriticalSection.Create;  
begin
  InitCriticalSection(fcs);
end;

destructor TDefaultCriticalSection.Destroy;  
begin
  DoneCriticalsection(fcs);
end;

procedure TDefaultCriticalSection.Lock;
begin
  EnterCriticalsection(fcs);
end;

procedure TDefaultCriticalSection.Unlock;  
begin
  LeaveCriticalsection(fcs);
end;

procedure RegisterCSClass(AClass: TBugReportCriticalSectionClass);
begin
  if Assigned(AClass) then CSClass:=AClass 
  else CSClass:=TDefaultCriticalSection;
end;

function CreateCS: TBugReportCriticalSection;
begin
  Result:=CSClass.Create;
end;

initialization
  CSClass := TDefaultCriticalSection;

end.
  
