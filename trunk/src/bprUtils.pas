unit bprUtils;

interface

{$ifdef fpc}{$mode delphi}{$h+}{$endif}

{$ifdef MSWindows}
uses Windows;
{$endif}

type
  { TList }
  TList=class(TObject)
  private
    fCount  : Integer;
    fData   : array of TObject;
    function GetItem(i: Integer): TObject;
  public
    procedure Clear(FreeItems: Boolean=false);
    procedure Add(AItem: TObject);
    procedure Insert(AItem: TObject; Index: Integer);
    procedure Remove(AItem: TObject);
    procedure Delete(idx: Integer);
    function IndexOf(AItem: TObject): Integer;
    property Item[i: Integer]: TObject read GetItem; default;
    property Count: Integer read fCount; 
  end;


// time utils
type
  TBugReportDate = record
    year, month, day  : Word;
    hour, min, sec, mls : Word;
  end;

procedure GetTime(var rp: TBugReportDate);
function GetMlsTicks: LongWord;

implementation

{$ifdef MSWindows}
procedure GetTime(var rp: TBugReportDate);
var
  st : TSystemTime;
begin
  GetSystemTime(st);
  rp.year:=st.wYear;
  rp.month:=st.wMonth;
  rp.day:=st.wDay;
  rp.hour:=st.wHour;
  rp.min:=st.wMinute;
  rp.sec:=st.wSecond;
  rp.mls:=st.wMilliseconds;
end;

function GetMlsTicks: LongWord;
begin
  Result:=Windows.GetTickCount;
end;
{$endif}


{ TList }

function TList.GetItem(i: Integer): TObject;
begin
  if (i<0) or (i>=fCount) then Result:=nil
  else Result:=fData[i];
end;

procedure TList.Clear(FreeItems: Boolean); 
var
  i : Integer;
begin
  if FreeItems then 
    for i:=0 to fCount-1 do
      fData[i].Free;
  fCount:=0;        
end;

procedure TList.Add(AItem: TObject); 
begin
  Insert(AItem, fCount);
end;

procedure TList.Remove(AItem: TObject); 
var
  i : Integer;
begin
  i := IndexOf(AItem);
  if i>=0 then Delete(i);
end;

procedure TList.Delete(idx: Integer); 
var
  i : Integer;
begin
  if (idx<0) or (idx>fCount) then Exit;
  for i:=idx to fCount-1 do fData[i]:=fData[i+1];
  dec(fCount);
end;

function TList.IndexOf(AItem: TObject): Integer; 
var
  i : Integer;
begin
  for i:=0 to fCount-1 do 
    if fData[i]=AItem then begin 
      Result:=i; 
      Exit; 
    end;
  Result:=-1;
end;

procedure TList.Insert(AItem: TObject; Index: Integer);
var
  i : Integer;
begin
  if (Index<0) then Exit;
  if fCount=length(fData) then begin
    if fCount=0 then SetLength(fData, 4)
    else SetLength(fData, fCount*2)
  end;
  for i:=fCount+1 downto Index do
    fData[i]:=fData[i-1];
  fData[Index]:=AItem;
  inc(fCount);
end;

end.
