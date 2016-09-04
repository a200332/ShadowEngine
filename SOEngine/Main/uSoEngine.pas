unit uSoEngine;

interface

uses
  System.SyncObjs, FMX.Objects, FMX.Graphics, System.UITypes, System.Classes,
  uClasses, uEngine2DClasses, uEngine2DThread, uSoModel, uEngine2DOptions,
  uEngine2DManager, uEngine2DStatus, uSoManager, uSoContainer;

type
  TSoEngine = class
  strict private
    FEngineThread: TEngineThread; // Thread that paint all sprites (But there are possibility to use not one thread)  // ����� � ������� ���������� ���������
    FCritical: TCriticalSection; // The critical section for multithread operation, to protect model on changind in paint time // ����������� ������ ������
    FModel: TSoModel; // All main lists are in It.
    FOptions: TEngine2DOptions; // All Engine options. If you add some feature to manage engine, it shoulb be here// ��������� ������
    FObjectCreator: TEngine2DManager; // This object work with Model items. It's controller/
    FStatus: TEngine2DStatus; // All Engine status you can get from herem like width-height,speed and etc.
    FIsMouseDowned: Boolean; // True if Mouse is Downed  // ������ ��������� ��������� ����
    FImage: TImage; // It's the Image the Engine Paint in. // �����, � ������� ���������� ���������
    FBackGround: TBitmap; // Background of Engine that paints on every tick. Not sure if it should be here // ���������. ������ �������� � Repaint �� ���� fImage
    FWidth, FHeight: Single; // ������ ���� ������ � ������
//    FDebug: Boolean; // There are some troubles to debug multithread app, so it for it // �� ����� �����, �� �������� ���������� �� �����, ����� ��������� ����� ���������� ������
    FBackgroundBehavior: TProcedure; // Procedure to Paint Background. It can be default or Parallax(like in Asteroids example) or any type you want
    FInBeginPaintBehavior: TProcedure; // Method is called before Paint
    FInEndPaintBehavior: TProcedure; // Method is called after Paint
    FManager: TSoManager;
    procedure OnImageResize(ASender: TObject);
    procedure setBackGround(ABmp: TBitmap);
    procedure BackgroundDefaultBehavior;
    procedure InBeginPaintDefaultBehavior;
    procedure InEndPaintDefaultBehavior;
    procedure SetBackgroundBehavior(const Value: TProcedure);
    function IsHor: Boolean;
    procedure SetImage(const Value: TImage);
  protected
    property EngineThread: TEngineThread read FEngineThread;
  public
    // Main properties of Engine. �������� �������� ������
    property Image: TImage read FImage write SetImage;
    property BackgroundBehavior: TProcedure read FBackgroundBehavior write SetBackgroundBehavior;
    property InBeginPaintBehavior: TProcedure read FInBeginPaintBehavior write FInBeginPaintBehavior;
    property InEndPaintBehavior: TProcedure read FInBeginPaintBehavior write FInBeginPaintBehavior;
    property Critical: TCriticalSection read FCritical;

    property Width: Single read FWidth;
    property Height: Single read FHeight;

    property Background: TBitmap read FBackGround write setBackGround;
    property Options: TEngine2dOptions read FOptions;
    procedure Click(const ACount: Integer = -1); virtual; // It must be Called after MouseUp if in MouseUp was AClickObjects = False;

    procedure Init(AImage: TImage); // Initialization of SO Engine // ������������� ������, ����� ������� �� �����, �� �������� ������������ fImage
    procedure WorkProcedure; virtual; // The main Paint procedure.
    procedure Start; virtual; // �������� ������
    procedure Stop; virtual;// ��������� ������

    constructor Create; virtual;
    destructor Destroy; override;

    function Manage(const AContainer: TSoContainer): TSoManager;
    // You should use Manager to Work with Engine
//    property Manager: TSoManager read FManager; // It helps to create object faster // ��������� ������� � ����� ��������� �������
    property Status: TEngine2DStatus read FStatus;
    const
      CGameStarted = 1;
      CGameStopped = 255;
  end;

implementation

{ TSoEngine }

procedure TSoEngine.BackgroundDefaultBehavior;
begin

end;

procedure TSoEngine.Click(const ACount: Integer);
begin

end;

constructor TSoEngine.Create;
begin
  FOptions := TEngine2DOptions.Create;

  FCritical := TCriticalSection.Create;
  FEngineThread := tEngineThread.Create;
  FEngineThread.WorkProcedure := WorkProcedure;

//  FStatus := TEngine2DStatus.Create(FEngineThread, @FWidth, @FHeight, @FIsMouseDowned, @FMouseDowned, @FMouseUpped, @FClicked);
  FModel := TSoModel.Create(TAnonImage(FImage), FCritical, IsHor);

  FOptions.Up([EAnimateForever, EUseCollider]);
  FOptions.Down([EClickOnlyTop]);

  FBackgroundBehavior := BackgroundDefaultBehavior;
  FInBeginPaintBehavior := InBeginPaintDefaultBehavior;
  FInEndPaintBehavior := InEndPaintDefaultBehavior;

  FBackGround := TBitmap.Create;
end;

destructor TSoEngine.Destroy;
begin
  FModel.Free;
  FEngineThread.Free;
  FCritical.Free;

  inherited;
end;

procedure TSoEngine.InBeginPaintDefaultBehavior;
begin

end;

procedure TSoEngine.InEndPaintDefaultBehavior;
begin

end;

procedure TSoEngine.Init(AImage: TImage);
begin
  Image := AImage;
end;

function TSoEngine.IsHor: Boolean;
begin
  Result := FWidth > FHeight;
end;

function TSoEngine.Manage(const AContainer: TSoContainer): TSoManager;
begin
  FManager.Activate(AContainer);
  Result := FManager; // /oManager.Create(AContainer);
end;

{rocedure TSoEngine.OnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: single);
begin
  FModel.ExecuteMouseDown()
end;

procedure TSoEngine.OnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: single);
begin

end;  }

procedure TSoEngine.OnImageResize(ASender: TObject);
begin
  FWidth := TImage(ASender).Width;
  FHeight := TImage(ASender).Height;
end;

procedure TSoEngine.setBackGround(ABmp: TBitmap);
begin

end;

procedure TSoEngine.SetBackgroundBehavior(const Value: TProcedure);
begin

end;


procedure TSoEngine.SetImage(const Value: TImage);
begin
  if Assigned(FImage) then
  begin
    FImage.OnResize := nil;
    FImage.OnMouseDown := nil;
    FImage.OnMouseUp := nil;
  end;

  FImage := Value;

  FImage.OnResize := OnImageResize;
  FImage.OnMouseDown := FModel.ExecuteMouseDown;
  FImage.OnMouseUp := FModel.ExecuteMouseUp;
end;

procedure TSoEngine.Start;
begin

end;

procedure TSoEngine.Stop;
begin

end;

procedure TSoEngine.WorkProcedure;
begin
  FModel.ExecuteOnTick;
end;

end.