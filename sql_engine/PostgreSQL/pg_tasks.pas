{ Free DB Manager

  Copyright (C) 2005-2019 Lagunov Aleksey  alexs75 at yandex.ru

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit pg_tasks;

{$I fbmanager_define.inc}

interface

uses
  Classes, SysUtils, SQLEngineAbstractUnit, PostgreSQLEngineUnit, ZDataset,
  sqlObjects, contnrs, SQLEngineInternalToolsUnit, fbmSqlParserUnit,
  SQLEngineCommonTypesUnit;

type
  TPGTask = class;
  TPGTaskStepEnumerator = class;
  TPGTaskSheduleListEnumerator = class;

  { TPGTasksRoot }

  TPGTasksRoot = class(TDBRootObject)
  private
    FJobClassList: TStringList;
  protected
    //
  public
    constructor Create(AOwnerDB : TSQLEngineAbstract; ADBObjectClass:TDBObjectClass; const ACaption:string; AOwnerRoot:TDBRootObject); override;
    destructor Destroy; override;
    function GetObjectType: string;override;
    procedure RefreshGroup; override;
    property JobClassList:TStringList read FJobClassList;
  end;

  { TPGTaskStep }

  TPGTaskStep = class
  private
    FDescription: string;
    FPGTask: TPGTask;
    FID:integer;
    FName:string;
    FBody:string;
    FConnectStr:string; //user=postgres host=192.168.123.4 port=5432 dbname=base_test_analiz
    FDBName:string;
    FEnabled:boolean;
  public
    constructor Create(APGTask:TPGTask);
    procedure Assign(From:TPGTaskStep);
    function IsEqual(From:TPGTaskStep): Boolean;
    function MakeSQL:string;
    property Name:string read FName write FName;
    property Description:string read FDescription write FDescription;
    property Enabled:boolean read FEnabled write FEnabled;
    property Body:string read FBody write FBody;
    property DBName:string read FDBName write FDBName;
    property ConnectStr:string read FConnectStr write FConnectStr;
    property ID:integer read FID write FID;
  end;

  { TPGTaskSteps }

  TPGTaskSteps = class
  private
    FOwner: TPGTask;
    FList:TFPList;
    function GetCount: integer;
    function GetItem(AIndex: integer): TPGTaskStep;
  public
    constructor Create(AOwner:TPGTask);
    destructor Destroy;override;
    procedure Assign(ATaskSteps:TPGTaskSteps);
    function GetEnumerator: TPGTaskStepEnumerator;
    function Add:TPGTaskStep;
    procedure Clear;
    property Item[AIndex:integer]:TPGTaskStep read GetItem; default;
    property Count:integer read GetCount;
  end;

  { TPGTaskStepEnumerator }

  TPGTaskStepEnumerator = class
  private
    FList: TPGTaskSteps;
    FPosition: Integer;
  public
    constructor Create(AList: TPGTaskSteps);
    function GetCurrent: TPGTaskStep;
    function MoveNext: Boolean;
    property Current: TPGTaskStep read GetCurrent;
  end;

  { TPGTaskShedule }
  TMonthArray = array[1..12] of boolean;
  TDayMonthArray = array[1..32] of boolean;
  TDayWeekArray = array[1..7] of boolean;
  THoursArray = array[0..23] of boolean;
  TMinutesArray = array[0..59] of boolean;

  TPGTaskShedule = class
  private
    FDescription: string;
    FPGTask:TPGTask;
    FIndex:integer;
    FID:integer;
    FName:string;
    FEnabled:boolean;
    FDateStart:TDateTime;
    FDateStop:TDateTime;
    procedure DoParse(S:string;var A:array of boolean);
    function DoMakeArray(const A:array of boolean):string;
    procedure SetMonth(S:string);
    procedure SetDayMonth(S:string);
    procedure SetDayWeek(S:string);
    procedure SetHours(S:string);
    procedure SetMinutes(S:string);
    //
    function MakeSQL:string;
  public
    Month:TMonthArray;
    DayMonth:TDayMonthArray;
    DayWeek:TDayWeekArray;
    Hours:THoursArray;
    Minutes:TMinutesArray;
    constructor Create(APGTask:TPGTask);
    procedure Assign(From:TPGTaskShedule);

    function MonthStr:string; inline;
    function DayMonthStr:string; inline;
    function DayWeekStr:string; inline;
    function HoursStr:string; inline;
    function MinutesStr:string; inline;

    property Index:integer read FIndex write FIndex;
    property ID:integer read FID write FID;
    property Name:string read FName write FName;
    property Description:string read FDescription write FDescription;
    property Enabled:boolean read FEnabled write FEnabled;
    property DateStart:TDateTime read FDateStart write FDateStart;
    property DateStop:TDateTime read FDateStop write FDateStop;
  end;

  { TPGTaskSheduleList }

  TPGTaskSheduleList = class
  private
    FOwner:TPGTask;
    FList:TFPList;
    function GetCount: integer;
    function GetItem(AIndex: integer): TPGTaskShedule;
  public
    constructor Create(AOwner:TPGTask);
    destructor Destroy;override;
    procedure Assign(ATaskSteps:TPGTaskSheduleList);
    function GetEnumerator: TPGTaskSheduleListEnumerator;
    function Add:TPGTaskShedule;
    procedure Clear;
    property Item[AIndex:integer]:TPGTaskShedule read GetItem; default;
    property Count:integer read GetCount;
  end;

  { TPGTaskSheduleListEnumerator }

  TPGTaskSheduleListEnumerator = class
  private
    FList: TPGTaskSheduleList;
    FPosition: Integer;
  public
    constructor Create(AList: TPGTaskSheduleList);
    function GetCurrent: TPGTaskShedule;
    function MoveNext: Boolean;
    property Current: TPGTaskShedule read GetCurrent;
  end;

  TPGTask = class(TDBObject)
  private
    FDateCreate: TDateTime;
    FDateModify: TDateTime;
    FDateRunLast: TDateTime;
    FDateRunNext: TDateTime;
    FEnabled: boolean;
    FTaskID: integer;
    FSteps:TPGTaskSteps;
    FShedule:TPGTaskSheduleList;
    FTaskClassID:integer;
    function GetTaskClassName: string;
  protected
    function InternalGetDDLCreate: string; override;
    procedure SetDescription(const AValue: string); override;
    procedure InternalPrepareDropCmd(R: TSQLDropCommandAbstract); override;
  public
    constructor Create(const ADBItem:TDBItem; AOwnerRoot: TDBRootObject);override;
    destructor Destroy; override;
    procedure RefreshObject; override;

    function CreateSQLObject:TSQLCommandDDL; override;
    function CompileSQLObject(ASqlObject:TSQLCommandDDL; ASqlExecParam:TSqlExecParams):boolean; override;

    function CompileTaskShedule(TS:TPGTaskShedule):boolean;
    function DeleteTaskShedule(TS:TPGTaskShedule):boolean;

    function CompileTaskStep(TS:TPGTaskStep):boolean;
    function DeleteTaskStep(TS:TPGTaskStep):boolean;

    class function DBClassTitle:string;override;
    property TaskID:integer read FTaskID;
    property Steps:TPGTaskSteps read FSteps;
    property TaskClassID:integer read FTaskClassID;
    property TaskClassName:string read GetTaskClassName;
    property Shedule:TPGTaskSheduleList read FShedule;
    property Enabled:boolean read FEnabled;
    property DateCreate:TDateTime read FDateCreate;
    property DateModify:TDateTime read FDateModify;
    property DateRunLast:TDateTime read FDateRunLast;
    property DateRunNext:TDateTime read FDateRunNext;
  end;

  { TPGSQLTaskCreate }

  TPGSQLTaskCreate = class(TSQLCommandDDL)
  private
    FTaskClass: string;
    FTaskShedule: TPGTaskSheduleList;
    FTaskSteps:TPGTaskSteps;
  protected
    procedure MakeSQL; override;
  public
    constructor Create(AParent:TSQLCommandAbstract); override;
    destructor Destroy;override;
    procedure Clear;override;
    procedure Assign(ASource:TSQLObjectAbstract);override;
    property TaskSteps:TPGTaskSteps read FTaskSteps;
    property TaskShedule:TPGTaskSheduleList read FTaskShedule;
    property TaskClass:string read FTaskClass write FTaskClass;
  end;

  TPGSQLTaskAlterAction = (pgtaCreateShedule, pgtaCreateTaskItem,
    pgtaAlterShedule, pgtaAlterTaskItem, pgtaDropShedule, pgtaDropTaskItem,
    pgtaAlterTask);

  { TPGSQLTaskAlter }

  TPGSQLTaskAlter = class(TSQLCommandDDL)
  private
  protected
    procedure MakeSQL; override;
  public
    constructor Create(AParent:TSQLCommandAbstract); override;
    destructor Destroy;override;
    procedure Clear;override;
    procedure Assign(ASource:TSQLObjectAbstract);override;
  end;

  { TPGSQLDropTask }

  TPGSQLDropTask = class(TSQLDropCommandAbstract)
  private
    FJobID: Integer;
  protected
    procedure MakeSQL;override;
  public
    property JobID:Integer read FJobID write FJobID;
  end;

implementation
uses pg_sql_lines_unit, pgSqlTextUnit, StrUtils;

{ TPGSQLTaskAlter }

procedure TPGSQLTaskAlter.MakeSQL;
begin
  inherited MakeSQL;
end;

constructor TPGSQLTaskAlter.Create(AParent: TSQLCommandAbstract);
begin
  inherited Create(AParent);
end;

destructor TPGSQLTaskAlter.Destroy;
begin
  inherited Destroy;
end;

procedure TPGSQLTaskAlter.Clear;
begin
  inherited Clear;
end;

procedure TPGSQLTaskAlter.Assign(ASource: TSQLObjectAbstract);
begin
  inherited Assign(ASource);
end;

{ TPGTaskSheduleListEnumerator }

constructor TPGTaskSheduleListEnumerator.Create(AList: TPGTaskSheduleList);
begin
  FList := AList;
  FPosition := -1;
end;

function TPGTaskSheduleListEnumerator.GetCurrent: TPGTaskShedule;
begin
  Result := FList[FPosition];
end;

function TPGTaskSheduleListEnumerator.MoveNext: Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FList.Count;
end;

{ TPGTaskSheduleList }

function TPGTaskSheduleList.GetCount: integer;
begin
  Result:=FList.Count;
end;

function TPGTaskSheduleList.GetItem(AIndex: integer): TPGTaskShedule;
begin
  Result:=TPGTaskShedule(FList[AIndex]);
end;

constructor TPGTaskSheduleList.Create(AOwner: TPGTask);
begin
  inherited Create;
  FOwner:=AOwner;
  FList:=TFPList.Create;
end;

destructor TPGTaskSheduleList.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TPGTaskSheduleList.Assign(ATaskSteps: TPGTaskSheduleList);
var
  P: TPGTaskShedule;
begin
  Clear;
  if not Assigned(ATaskSteps) then Exit;
  for P in ATaskSteps do
    Add.Assign(P);
end;

function TPGTaskSheduleList.GetEnumerator: TPGTaskSheduleListEnumerator;
begin
  Result:=TPGTaskSheduleListEnumerator.Create(Self);
end;

function TPGTaskSheduleList.Add: TPGTaskShedule;
begin
  Result:=TPGTaskShedule.Create(FOwner);
  FList.Add(Result);
end;

procedure TPGTaskSheduleList.Clear;
var
  i: Integer;
begin
  for i:=0 to FList.Count - 1 do
    TPGTaskShedule(FList[i]).Free;
  FList.Clear;
end;

{ TPGSQLDropTask }

procedure TPGSQLDropTask.MakeSQL;
begin
  AddSQLCommand(Format('delete from pgagent.pga_job where pga_job.jobid = %d', [FJobID]));
end;

{ TPGTaskStepEnumerator }

constructor TPGTaskStepEnumerator.Create(AList: TPGTaskSteps);
begin
  FList := AList;
  FPosition := -1;
end;

function TPGTaskStepEnumerator.GetCurrent: TPGTaskStep;
begin
  Result := FList[FPosition];
end;

function TPGTaskStepEnumerator.MoveNext: Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FList.Count;
end;

{ TPGTaskSteps }

function TPGTaskSteps.GetCount: integer;
begin
  Result:=FList.Count;
end;

function TPGTaskSteps.GetItem(AIndex: integer): TPGTaskStep;
begin
  Result:=TPGTaskStep(FList[AIndex]);
end;

constructor TPGTaskSteps.Create(AOwner: TPGTask);
begin
  inherited Create;
  FOwner:=AOwner;
  FList:=TFPList.Create;
end;

destructor TPGTaskSteps.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TPGTaskSteps.Assign(ATaskSteps: TPGTaskSteps);
var
  T: TPGTaskStep;
begin
  Clear;
  if not Assigned(ATaskSteps) then Exit;
  for T in ATaskSteps do
    Add.Assign(T);
end;

function TPGTaskSteps.GetEnumerator: TPGTaskStepEnumerator;
begin
  Result:=TPGTaskStepEnumerator.Create(Self);
end;

function TPGTaskSteps.Add: TPGTaskStep;
begin
  Result:=TPGTaskStep.Create(FOwner);
  FList.Add(Result);
end;

procedure TPGTaskSteps.Clear;
var
  i: Integer;
begin
  for i:=0 to FList.Count-1 do
    TPGTaskStep(FList[i]).Free;
  FList.Clear;
end;

{ TPGSQLTaskCreate }

procedure TPGSQLTaskCreate.MakeSQL;
var
  S, S1: String;
  T: TPGTaskStep;
  TL: TPGTaskShedule;
begin
  S:='do'+LineEnding+'$tasks$'+LineEnding +
  'declare'+LineEnding +
  '  f_JobId integer;'+LineEnding +
  'begin'+LineEnding +
  '  INSERT INTO pgagent.pga_job (jobjclid, jobname, jobdesc, jobenabled, jobhostagent)'+LineEnding +
  '  SELECT'+LineEnding +
  '    pga_jobclass.jclid,'+LineEnding +
  '    '''+name+''','+LineEnding +
  '    '''+Description+''','+LineEnding +
  '    true,'+LineEnding +
  '    '''''+LineEnding +
  '  FROM'+LineEnding +
  '    pgagent.pga_jobclass'+LineEnding +
  '    WHERE pga_jobclass.jclname='''+TaskClass+''''+LineEnding +
  '  RETURNING'+LineEnding +
  '    jobid'+LineEnding +
  '  into'+LineEnding +
  '    f_JobId;'+LineEnding+LineEnding;

  if FTaskSteps.Count > 0 then
  begin
    S:=S + '  /*------------- JOB STEPS -----------*/' + LineEnding;
    for T in FTaskSteps do
    begin
      S1:='  INSERT INTO pgagent.pga_jobstep' + LineEnding +
          '    (jstjobid, jstname, jstdesc, jstenabled, jstkind, jstonerror, jstcode, jstdbname, jstconnstr)' + LineEnding +
          '  values ' + LineEnding +
          '    (f_JobId, '+AnsiQuotedStr(T.Name, '''')+', ' + AnsiQuotedStr(T.Description, '''') + ', '+
                   BoolToStr(T.Enabled, true)+', ''s'', ''f'', '+AnsiQuotedStr(T.Body, '''')+', '''+T.DBName+''', '''');' +LineEnding;
      S:=S + S1;
    end;
    S:=S + LineEnding + LineEnding;
  end;


  if FTaskShedule.Count > 0 then
  begin
    S:=S + '  /*------------- JOB SHEDULE -----------*/' + LineEnding;
    for TL in FTaskShedule do
    begin
      S1:='  INSERT INTO pgagent.pga_schedule (jscjobid, jscname, jscdesc, '+
              'jscminutes, jschours, jscweekdays, jscmonthdays, '+
              'jscmonths, jscenabled, jscstart, jscend)' + LineEnding +
          '  VALUES(f_JobId, ' + AnsiQuotedStr(TL.Name, '''') + ', ' +
              AnsiQuotedStr(TL.Description, '''') + ', '+
              AnsiQuotedStr(TL.MinutesStr, '''') + ', '+
              AnsiQuotedStr(TL.HoursStr, '''') +  ', ' +
              AnsiQuotedStr(TL.DayWeekStr, '''') +  ', ' +
              AnsiQuotedStr(TL.DayMonthStr, '''') +  ','+
              AnsiQuotedStr(TL.MonthStr, '''') + ', ' + BoolToStr(TL.Enabled, true) + ',' +
              ''''+DateTimeToStr(TL.DateStart)+''','''  + DateTimeToStr(TL.DateStop) + ''');' + LineEnding;
      S:=S + S1;
    end;
    S:=S + LineEnding + LineEnding;
  end;

   S:=S +
  'end;'+LineEnding +
  '$tasks$';
  AddSQLCommand(S);
end;

constructor TPGSQLTaskCreate.Create(AParent: TSQLCommandAbstract);
begin
  inherited Create(AParent);
  FTaskSteps:=TPGTaskSteps.Create(nil);
  FTaskShedule:=TPGTaskSheduleList.Create(nil);
end;

destructor TPGSQLTaskCreate.Destroy;
begin
  FreeAndNil(FTaskShedule);
  FreeAndNil(FTaskSteps);
  inherited Destroy;
end;

procedure TPGSQLTaskCreate.Clear;
begin
  FTaskSteps.Clear;
  inherited Clear;
end;

procedure TPGSQLTaskCreate.Assign(ASource: TSQLObjectAbstract);
begin
  if ASource is TPGSQLTaskCreate then
  begin
    FTaskSteps.Assign(TPGSQLTaskCreate(ASource).TaskSteps);
    FTaskShedule.Assign(TPGSQLTaskCreate(ASource).TaskShedule);
  end;
  inherited Assign(ASource);
end;

{ TPGTaskShedule }

procedure TPGTaskShedule.DoParse(S: string; var A: array of boolean);
var
  i: Integer;
  j: Integer;
begin
  i:=Low(A);
  j:=1;
  while (i<=High(A)) and (j <= Length(S)) do
  begin
    while (j<=Length(S)) and (S[j] = ',') do inc (j);
    if j<=Length(S) then
    begin
      A[i]:=S[j] in ['t','T'];
      Inc(i);
      Inc(j);
    end
    else
      break;
  end;
end;

function TPGTaskShedule.DoMakeArray(const A: array of boolean): string;
var
  i: Integer;
begin
  Result:='';
  for i:=Low(A) to High(A) do Result:=Result + BoolToStr(A[i], 't', 'f')+',';
  Result:='{'+Copy(Result, 1, Length(Result) - 1) + '}';
end;

procedure TPGTaskShedule.SetMonth(S: string);
begin
  if S = '' then
    FillChar(Month, SizeOf(Month), false)
  else
    DoParse(Copy(S, 2, Length(S)-2), Month);
end;

procedure TPGTaskShedule.SetDayMonth(S: string);
begin
  if S = '' then
    FillChar(DayMonth, SizeOf(DayMonth), false)
  else
    DoParse(Copy(S, 2, Length(S)-2), DayMonth);
end;

procedure TPGTaskShedule.SetDayWeek(S: string);
begin
  if S = '' then
    FillChar(DayWeek, SizeOf(DayWeek), false)
  else
    DoParse(Copy(S, 2, Length(S)-2), DayWeek);
end;

procedure TPGTaskShedule.SetHours(S: string);
begin
  if S = '' then
    FillChar(Hours, SizeOf(Hours), false)
  else
    DoParse(Copy(S, 2, Length(S)-2), Hours);
end;

procedure TPGTaskShedule.SetMinutes(S: string);
begin
  if S = '' then
    FillChar(Minutes, SizeOf(Minutes), false)
  else
    DoParse(Copy(S, 2, Length(S)-2), Minutes);
end;

function TPGTaskShedule.MakeSQL: string;
begin
  if FID > -1 then
  begin
    Result:='UPDATE pgagent.pga_schedule SET '+
      'jscname = '''+FName + ''',' +
      'jscdesc = '''+Description + ''',' +
      'jscenabled = ' +BoolToStr(FEnabled, 'true', 'false') + ', '+
      'jscweekdays = ''{' + DoMakeArray(DayWeek) + '}'', '+
      'jscmonthdays = ''{' + DoMakeArray(DayMonth)+'}'', '+
      'jscmonths = ''{' + DoMakeArray(Month)+'}'', '+
      'jscminutes = ''{' + DoMakeArray(Minutes)+'}'', '+
      'jschours = ''{' + DoMakeArray(Hours)+'}'', '+
      'jscstart = ''' + DateTimeToStr(FDateStart) + ''', ' +
      'jscend = ''' + DateTimeToStr(FDateStop) + ''' ' +
      'WHERE jscid='+IntToStr(FID)+';';
  end
  else
  begin
    Result:='INSERT INTO pgagent.pga_schedule ' +
            '(jscid, ' +
             'jscjobid, jscname, jscdesc, '+
             'jscminutes, jschours, '+
             'jscweekdays, jscmonthdays, jscmonths, '+
             'jscenabled, jscstart, jscend) ' +
            'VALUES( NEXTVAL(''pgagent.pga_schedule_jscid_seq''), ' +
            IntToStr(FPGTask.FTaskID) + ', '+
            '''' + FName + ''', '+
            '''' + Description +''','+
            '''{' + DoMakeArray(Minutes)+'}'', '+
            '''{' + DoMakeArray(Hours)+'}'', '+

            '''{' + DoMakeArray(DayWeek)+'}'', '+
            '''{' + DoMakeArray(DayMonth)+'}'', '+
            '''{' + DoMakeArray(Month)+'}'', '+
            BoolToStr(FEnabled, 'true', 'false') + ', '+
            '''' + DateTimeToStr(FDateStart) + ''',' +
            '''' + DateTimeToStr(FDateStop) + ''')';
  end;
end;

constructor TPGTaskShedule.Create(APGTask: TPGTask);
begin
  inherited Create;
  FID:=-1;
  FIndex:=-1;
  FPGTask:=APGTask;
end;

procedure TPGTaskShedule.Assign(From: TPGTaskShedule);
begin
  FID:=From.FID;
  FName:=From.FName;
  Description:=From.Description;
  FEnabled:=From.FEnabled;
  FDateStart:=From.FDateStart;
  FDateStop:=From.FDateStop;

  Month:=From.Month;
  DayMonth:=From.DayMonth;
  DayWeek:=From.DayWeek;
  Hours:=From.Hours;
  Minutes:=From.Minutes;
end;

function TPGTaskShedule.MonthStr: string; inline;
begin
  Result:=DoMakeArray(Month);
end;

function TPGTaskShedule.DayMonthStr: string; inline;
begin
  Result:=DoMakeArray(DayMonth);
end;

function TPGTaskShedule.DayWeekStr: string; inline;
begin
  Result:=DoMakeArray(DayWeek);
end;

function TPGTaskShedule.HoursStr: string; inline;
begin
  Result:=DoMakeArray(Hours);
end;

function TPGTaskShedule.MinutesStr: string; inline;
begin
  Result:=DoMakeArray(Minutes);
end;

{ TPGTaskStep }

constructor TPGTaskStep.Create(APGTask: TPGTask);
begin
  inherited Create;
  FID:=-1;
//  FIndex:=-1;
  FPGTask:=APGTask;
end;

procedure TPGTaskStep.Assign(From: TPGTaskStep);
begin
  FID:=From.FID;
  FName:=From.FName;
  FBody:=From.FBody;
  FDescription:=From.FDescription;
  FDBName:=From.FDBName;
  FConnectStr:=From.FConnectStr;
  FEnabled:=From.FEnabled;
end;

function TPGTaskStep.IsEqual(From: TPGTaskStep): Boolean;
begin
  Result:=
    (FID = From.FID) and
    (FName = From.FName) and
    (FBody = From.FBody) and
    (FDescription = From.FDescription) and
    (FDBName = From.FDBName) and
    (FConnectStr = From.FConnectStr) and
    (FEnabled = From.FEnabled);
end;

function TPGTaskStep.MakeSQL: string;
var
  S: String;
begin
  Result:='';
  if FID > -1 then
    Result:=
      'UPDATE '+
      '  pgagent.pga_jobstep '+
      'SET '+
      '  jstname = '''+FName + ''', '+
      '  jstconnstr = '''+ FConnectStr + ''', '+
      '  jstdbname='''+FDBName+''', '+
      '  jstenabled = '+BoolToStr(FEnabled, 'true', 'false') + ', '+
//      '  jstkind='s',
      '  jstdesc=''' + FDescription + ''' '+
      'WHERE '+
      '  jstid='+IntToStr(FID)
  else
    Result:=
      'INSERT INTO pgagent.pga_jobstep '+
        '(jstid, '+
        'jstjobid, '+
        'jstname, '+
        'jstdesc, '+
        'jstenabled, '+
        'jstkind, '+
        'jstonerror, '+
        'jstcode, '+
        'jstdbname, '+
        'jstconnstr)'+
      'values '+
        '(NEXTVAL(''pgagent.pga_schedule_jscid_seq''), ' +//!!
        IntToStr(FPGTask.FTaskID) + ', '+
        '''' +FName + ''', '+
        '''' + FDescription + ''', '+
        BoolToStr(FEnabled, 'true', 'false') + ', '+
        '''s'', '+
        '''f'', ' + //jstonerror,
        '''' + FBody + ''', ' +
        '''' + FDBName + ''', '+
        '''' + FConnectStr + ''')';
end;

{ TPGTask }

function TPGTask.GetTaskClassName: string;
var
  i: Integer;
begin
  Result:='';
  for i:=0 to TPGTasksRoot(OwnerRoot).JobClassList.Count-1 do
    if PtrInt(TPGTasksRoot(OwnerRoot).JobClassList.Objects[i]) = TaskClassID then
    begin
      Result:=TPGTasksRoot(OwnerRoot).JobClassList[i];
      //ComboBox1.ItemIndex:=i;
      break;
    end;
end;

function TPGTask.InternalGetDDLCreate: string;
var
  FCmd: TPGSQLTaskCreate;
begin
  FCmd:=TPGSQLTaskCreate.Create(nil);
  FCmd.Name:=Caption;
  FCmd.Description:=Description;
  FCmd.TaskClass:=TaskClassName;
  FCmd.TaskSteps.Assign(FSteps);
  FCmd.TaskShedule.Assign(FShedule);
  Result:=FCmd.AsSQL;
  FCmd.Free;
end;

procedure TPGTask.SetDescription(const AValue: string);
begin
  if FDescription <> AValue then
  begin
    TSQLEnginePostgre(OwnerDB).ExecSysSQL(Format('UPDATE pgagent.pga_job SET jobdesc = %s WHERE jobid=%d', [AnsiQuotedStr(AValue, ''''), FTaskID]));
    FDescription:=AValue;
  end;
end;

procedure TPGTask.InternalPrepareDropCmd(R: TSQLDropCommandAbstract);
begin
  inherited InternalPrepareDropCmd(R);
  (R as TPGSQLDropTask).FJobID:=TaskID;
end;


constructor TPGTask.Create(const ADBItem: TDBItem; AOwnerRoot: TDBRootObject);
begin
  { TODO : Необходимо реализовать отображение в дереве запрещённых задач }
  inherited Create(ADBItem, AOwnerRoot);
  FSteps:=TPGTaskSteps.Create(Self);
  FShedule:=TPGTaskSheduleList.Create(Self);
end;

destructor TPGTask.Destroy;
begin
  FreeAndNil(FShedule);
  FreeAndNil(FSteps);
  inherited Destroy;
end;

procedure TPGTask.RefreshObject;
var
  Q:TZQuery;
  U:TPGTaskStep;
  Sh:TPGTaskShedule;
begin
  if State <> sdboEdit then exit;
  inherited RefreshObject;


  Q:=TSQLEnginePostgre(OwnerDB).GetSQLSysQuery(pgSqlTextModule.sqlTasks['pgTasksJobData']);
  Q.ParamByName('jobid').AsInteger:=FTaskID;
  try
    Q.Open;
    if not Q.Eof then
    begin
      Caption:=Q.FieldByName('jobname').AsString;
      FDescription:=Q.FieldByName('jobdesc').AsString;
      FTaskClassID:=Q.FieldByName('jobjclid').AsInteger;
      FEnabled:=Q.FieldByName('jobenabled').AsBoolean;

      FDateCreate:=Q.FieldByName('jobcreated').AsDateTime;
      FDateModify:=Q.FieldByName('jobchanged').AsDateTime;

      FDateRunLast:=Q.FieldByName('joblastrun').AsDateTime;
      FDateRunNext:=Q.FieldByName('jobnextrun').AsDateTime;

//      '  pga_job.jobagentid, '+
{      U.FBody:=Q.FieldByName('jstcode').AsString;
      U.FConnectStr:=Q.FieldByName('jstconnstr').AsString;
      U.FDBName:=Q.FieldByName('jstdbname').AsString;
      }
    end;
    Q.Close;
  finally
    Q.Free;
  end;


  FSteps.Clear;
  FShedule.Clear;

  //Load step list
  Q:=TSQLEnginePostgre(OwnerDB).GetSQLSysQuery(pgSqlTextModule.sqlTasks['pgTaskStepList']);
  Q.ParamByName('jstjobid').AsInteger:=FTaskID;
  try
    Q.Open;
    while not Q.Eof do
    begin
      U:=FSteps.Add;
      U.FID:=Q.FieldByName('jstid').AsInteger;
      U.FName:=Q.FieldByName('jstname').AsString;
      U.FDescription:=Q.FieldByName('jstdesc').AsString;
      U.FBody:=Q.FieldByName('jstcode').AsString;
      U.FConnectStr:=Q.FieldByName('jstconnstr').AsString;
      U.FDBName:=Q.FieldByName('jstdbname').AsString;
      U.FEnabled:=Q.FieldByName('jstenabled').AsBoolean;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;

  //Load Shedule list
  Q:=TSQLEnginePostgre(OwnerDB).GetSQLSysQuery(pgSqlTextModule.sqlTasks['pgTaskSheduleList']);
  Q.ParamByName('jscjobid').AsInteger:=FTaskID;
  try
    Q.Open;
    while not Q.Eof do
    begin
      Sh:=FShedule.Add;
      Sh.FID:=Q.FieldByName('jscid').AsInteger;
      Sh.FName:=Q.FieldByName('jscname').AsString;
      Sh.Description:=Q.FieldByName('jscdesc').AsString;
      Sh.FEnabled:=Q.FieldByName('jscenabled').AsBoolean;
      Sh.FDateStart:=Q.FieldByName('jscstart').AsDateTime;
      Sh.FDateStop:=Q.FieldByName('jscend').AsDateTime;
      Sh.SetMonth(Trim(Q.FieldByName('jscmonths').AsString));
      Sh.SetDayMonth(Trim(Q.FieldByName('jscmonthdays').AsString));
      Sh.SetDayWeek(Trim(Q.FieldByName('jscweekdays').AsString));

      Sh.SetMinutes(Trim(Q.FieldByName('jscminutes').AsString));
      Sh.SetHours(Trim(Q.FieldByName('jschours').AsString));

      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TPGTask.CreateSQLObject: TSQLCommandDDL;
begin
  if State = sdboCreate then
    Result:=TPGSQLTaskCreate.Create(nil)
  else
    Result:=TPGSQLTaskAlter.Create(nil);
end;

function TPGTask.CompileSQLObject(ASqlObject: TSQLCommandDDL;
  ASqlExecParam: TSqlExecParams): boolean;
begin
  Result:=inherited CompileSQLObject(ASqlObject, ASqlExecParam + [sepSystemExec]);
end;

function TPGTask.CompileTaskShedule(TS: TPGTaskShedule): boolean;
var
  sSQL:string;
begin
  Result:=false;
  sSQL:=TS.MakeSQL;
  if sSQL <> '' then
  begin
    TSQLEnginePostgre(OwnerDB).ExecSysSQL(TS.MakeSQL);
    RefreshObject;
    Result:=true;
  end;
end;

function TPGTask.DeleteTaskShedule(TS: TPGTaskShedule): boolean;
begin
  if Assigned(TS) and (TS.FID>-1) then
  begin
    TSQLEnginePostgre(OwnerDB).ExecSysSQL('DELETE FROM pgagent.pga_schedule WHERE jscid='+IntToStr(TS.FID));
    RefreshObject;
  end;
end;

function TPGTask.CompileTaskStep(TS: TPGTaskStep): boolean;
var
  sSQL:string;
begin
  Result:=false;
  sSQL:=TS.MakeSQL;
  if sSQL <> '' then
  begin
    TSQLEnginePostgre(OwnerDB).ExecSysSQL(sSQL);
    RefreshObject;
    Result:=true;
  end;
end;

function TPGTask.DeleteTaskStep(TS: TPGTaskStep): boolean;
begin
  Result:=false;
end;

class function TPGTask.DBClassTitle: string;
begin
  Result:='Task';
end;


{ TPGTasksRoot }

function TPGTasksRoot.GetObjectType: string;
begin
 Result:='Tasks';
end;

procedure TPGTasksRoot.RefreshGroup;
var
  Q:TZQuery;
  U:TPGTask;
begin
  FObjects.Clear;
  FJobClassList.Clear;
  Q:=TSQLEnginePostgre(OwnerDB).GetSQLSysQuery(pgSqlTextModule.sqlTasks['pgTaskClassList']);
  try
    Q.Open;
    while not Q.Eof do
    begin
      FJobClassList.AddObject(Q.FieldByName('jclname').AsString, TObject(Pointer(Q.FieldByName('jclid').AsInteger)));
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  Q:=TSQLEnginePostgre(OwnerDB).GetSQLSysQuery(pgSqlTextModule.sPGTasks.Strings.Text);
  try
    Q.Open;
    while not Q.Eof do
    begin
      U:=TPGTask.Create(nil, Self);
      U.Caption:=Q.FieldByName('jobname').AsString;
      U.FTaskID:=Q.FieldByName('jobid').AsInteger;
      U.FDescription:=Q.FieldByName('jobdesc').AsString;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

constructor TPGTasksRoot.Create(AOwnerDB: TSQLEngineAbstract;
  ADBObjectClass: TDBObjectClass; const ACaption: string;
  AOwnerRoot: TDBRootObject);
begin
  inherited Create(AOwnerDB, ADBObjectClass, ACaption, AOwnerRoot);
  FDBObjectKind:=okTasks;
  FDropCommandClass:=TPGSQLDropTask;
  FJobClassList:=TStringList.Create;
end;

destructor TPGTasksRoot.Destroy;
begin
  FreeAndNil(FJobClassList);
  inherited Destroy;
end;

end.

