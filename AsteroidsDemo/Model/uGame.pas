unit uGame;

interface

uses
  uClasses, uSoTypes, uEngine2DClasses, uWorldManager, uUnitManager, uMapPainter, uUnitCreator, uTemplateManager,
  uUtils, uModel, uSoManager;

type
  TGame = class
  private
    FShip: TShip;
    FAsteroids: TList<TBigAsteroid>;
    FDecorations: TList<TLtlAsteroid>;
    FMapPainter: TMapPainter; // Some object to draw parallax or map or etc
    FUnitCreator: TUnitCreator;
    FManager: TSoManager;
    FMouseDowned: Boolean;
    procedure StartGame;
    procedure OnResize(ASender: TObject);
    procedure OnMouseDown(Sender: TObject; AEventArgs: TMouseEventArgs);
    procedure OnMouseUp(Sender: TObject; AEventArgs: TMouseEventArgs);
    procedure OnMouseMove(Sender: TObject; AEventArgs: TMouseMoveEventArgs);
  public
    constructor Create(const AManager: TSoManager);
    destructor Destroy; override;
  end;

implementation

{ TGame }

constructor TGame.Create(const AManager: TSoManager);
begin
  FManager := AManager;

  with FManager do begin
    FMapPainter := TMapPainter.Create(WorldManager, ResourcePath('Back.jpg'));
    FUnitCreator := TUnitCreator.Create(UnitManager);

    TemplateManager.LoadSeJson(ResourcePath('Asteroids.sejson'));
    TemplateManager.LoadSeCss( ResourcePath('Formatters.secss'));

    FAsteroids := TList<TBigAsteroid>.Create;
    FDecorations := TList<TLtlAsteroid>.Create;

    WorldManager.OnResize.Add(OnResize);
    WorldManager.OnMouseDown.Add(OnMouseDown);
    WorldManager.OnMouseUp.Add(OnMouseUp);
    WorldManager.OnMouseMove.Add(OnMouseMove);

    StartGame;
  end;
end;

destructor TGame.Destroy;
begin
  FDecorations.Free;
  FAsteroids.Free;
  inherited;
end;

procedure TGame.OnMouseDown(Sender: TObject; AEventArgs: TMouseEventArgs);
begin
  FMouseDowned := True;
  FShip.AddDestination(TPointF.Create(AEventArgs.X, AEventArgs.Y));
end;

procedure TGame.OnMouseMove(Sender: TObject; AEventArgs: TMouseMoveEventArgs);
begin
  if FMouseDowned then
    FShip.AddDestination(TPointF.Create(AEventArgs.X, AEventArgs.Y));
end;

procedure TGame.OnMouseUp(Sender: TObject; AEventArgs: TMouseEventArgs);
begin
  FMouseDowned := False;
end;

procedure TGame.OnResize(ASender: TObject);
begin

end;

procedure TGame.StartGame;
var
  i: Integer;
begin
  FShip := FUnitCreator.NewShip;

  for i := 0 to 4 do
    FAsteroids.Add(FUnitCreator.NewSpaceDebris(Random(3)));

  for i:= 0 to 29 do
    FDecorations.Add(FUnitCreator.NewSpaceDust);
end;

end.
