unit PingPong;

interface

uses
  Classes, Controls, ExtCtrls, Forms, Ikaria, StdCtrls;

type
  TPingPongDemo = class(TForm)
    Panel1: TPanel;
    Go: TButton;
    Log: TMemo;
    procedure GoClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TPingActor = class(TActor)
  private
    Ponger: TProcessID;

    function  FindPong(Msg: TActorMessage): Boolean;
    procedure Ping(PID: TProcessID);
    procedure ReactToPong(Msg: TActorMessage);
  protected
    procedure RegisterActions(Table: TActorMessageTable); override;
    procedure Run; override;
  end;

  TPongActor = class(TActor)
  private
    Pinger: TProcessID;

    function  FindPing(Msg: TActorMessage): Boolean;
    procedure Pong(PID: TProcessID);
    procedure ReactToPing(Msg: TActorMessage);
  protected
    procedure RegisterActions(Table: TActorMessageTable); override;
  end;

var
  PingPongDemo: TPingPongDemo;

implementation

{$R *.dfm}

uses
  PluggableLogging, SyncObjs, SysUtils;

const
  PingName = 'ping';
  PongName = 'pong';

var
  Lock: TCriticalSection;

//******************************************************************************
//* Unit private functions/procedures                                          *
//******************************************************************************

procedure LogToDemo(LogName: String;
                    Description: String;
                    SourceRef: Cardinal;
                    SourceDesc: String;
                    Severity: TSeverityLevel;
                    EventRef: Cardinal;
                    DebugInfo: String);
begin
  Lock.Acquire;
  try
    if (Severity > slDebug) then
      PingPongDemo.Log.Lines.Add(Description);
  finally
    Lock.Release;
  end;
end;

//******************************************************************************
//* TPingPongDemo                                                              *
//******************************************************************************
//* TPingPongDemo Public methods ***********************************************

constructor TPingPongDemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  PluggableLogging.Logger := LogToDemo;
end;

//* TPingPongDemo Published methods ********************************************

procedure TPingPongDemo.GoClick(Sender: TObject);
var
  P: TActor;
begin
  P := TPingActor.Create('');
  P.Resume;
end;

//******************************************************************************
//* TPingActor                                                                 *
//******************************************************************************
//* TPingActor Protected methods ***********************************************

procedure TPingActor.RegisterActions(Table: TActorMessageTable);
begin
  inherited RegisterActions(Table);

  Table.Add(Self.FindPong, Self.ReactToPong);
end;

//* TPingActor Private methods *************************************************

function TPingActor.FindPong(Msg: TActorMessage): Boolean;
begin
  Result := (Msg.Data.Count > 1)
        and (Msg.Data[0] is TProcessIDElement)
        and (Msg.Data[1] is TStringElement)
        and (TStringElement(Msg.Data[1]).Value = PongName);
end;

procedure TPingActor.Ping(PID: TProcessID);
var
  P: TTuple;
begin
  P := TTuple.Create;
  try
    P.AddProcessID(Self.PID);
    P.AddString(PingName);
    Self.Send(PID, P);
  finally
    P.Free;
  end;
end;

procedure TPingActor.ReactToPong(Msg: TActorMessage);
begin
  LogEntry('', PongName, 0, 'PingPongDemo', slInfo, 0, Self.PID);
  Sleep(1000);
  Self.Ping(Self.Ponger);
end;

procedure TPingActor.Run;
begin
  Self.Ponger := Self.Spawn(TPongActor);
  Self.Ping(Self.Ponger);

  inherited Run;
end;

//******************************************************************************
//* TPongActor                                                                 *
//******************************************************************************
//* TPongActor Protected methods ***********************************************

procedure TPongActor.RegisterActions(Table: TActorMessageTable);
begin
  inherited RegisterActions(Table);

  Table.Add(Self.FindPing, Self.ReactToPing);
end;

//* TPongActor Private methods *************************************************

function TPongActor.FindPing(Msg: TActorMessage): Boolean;
begin
  Result := (Msg.Data.Count > 1)
        and (Msg.Data[0] is TProcessIDElement)
        and (Msg.Data[1] is TStringElement)
        and (TStringElement(Msg.Data[1]).Value = PingName);
end;

procedure TPongActor.Pong(PID: TProcessID);
var
  P: TTuple;
begin
  P := TTuple.Create;
  try
    P.AddProcessID(Self.PID);
    P.AddString(PongName);
    Self.Send(PID, P);
  finally
    P.Free;
  end;
end;

procedure TPongActor.ReactToPing(Msg: TActorMessage);
begin
  LogEntry('', PingName, 0, 'PingPongDemo', slInfo, 0, Self.PID);
  Sleep(1000);
  Self.Pong(Self.ParentID);
end;

initialization
  Lock := TCriticalSection.Create;
end.