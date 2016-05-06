unit uItemObjecterPresenter;

interface

uses
  System.Types, System.Generics.Collections, uIntersectorClasses, FMX.Graphics,
  System.UITypes, FMX.Types, System.SysUtils, {$I 'Utils\DelphiCompatability.inc'}
  System.Math, uItemBasePresenter, uItemShaperPresenter, uIItemView, uSSBModels;

type
  TItemShaperPresenterFriend = class(TItemShaperPresenter);

  TCaptureType = (ctNone, ctFigure, ctKeyPoint);

  TItemObjecterPresenter = class(TItemBasePresenter)
  private
    FItemObjectModel: TResourceModel;
    FParams: TDictionary<string,string>;
    FBmp: TBitmap; // Picture of object with Shapes
    FShapes: TList<TItemShaperPresenterFriend>;
    FIsShapeVisible: Boolean;
    FCaptureType: TCaptureType;
    FStartCapturePoint: TPointF;
    FLastTranslate: TPointF;
    FCapturedShape: TItemShaperPresenterFriend;
    FSelectedShape: TItemShaperPresenterFriend;
    function GetHeight: Integer;
    function GetPosition: TPoint;
    function GetWidth: Integer;
    procedure SetHeight(const Value: Integer);
    procedure SetPosition(const Value: TPoint);
    procedure SetWidth(const Value: Integer);
    procedure OnModelUpdate(ASender: TObject);
    function Bitmap: TBitmap;
    procedure RepaintShapes;
    function GetParams: TDictionary<string,string>;
  protected
    function GetRect: TRectF; override;
    procedure SetRect(const Value: TRectF); override;
  public
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property Position: TPoint read GetPosition write SetPosition;
    property Rect: TRectF read GetRect write SetRect;
    property Model: TResourceModel read FItemObjectModel;
    property Params: TDictionary<string,string> read GetParams;
    procedure ShowShapes;
    procedure HideShapes;
    procedure AddPoly;
    procedure AddCircle;
    procedure AddPoint;
    procedure DelPoint;
    procedure Repaint;
    procedure MouseDown; override;
    procedure MouseUp; override;
    procedure MouseMove; override;
    procedure Delete; override;
    procedure ShowOptions; override;
    constructor Create(const AItemView: IItemView; const AItemObjectModel: TResourceModel);
    destructor Destroy; override;
  end;

implementation

{ TObjecterItemPresenter }

procedure TItemObjecterPresenter.AddCircle;
var
  vShape: TItemShaperPresenterFriend;
  vShapeModel: TItemShapeModel;
  vCircle: TCircle;
begin
  vShapeModel := TItemShapeModel.CreateCircle(OnModelUpdate);

  vCircle.X := 0;
  vCircle.Y := 0;
  vCircle.Radius := FItemObjectModel.Width / 4;
  vShapeModel.SetData(vCircle);

  vShape := TItemShaperPresenterFriend.Create(FView, vShapeModel);
  FItemObjectModel.AddShape(vShapeModel);
  FShapes.Add(vShape);
  RepaintShapes;
end;

procedure TItemObjecterPresenter.AddPoint;
begin
  if FSelectedShape <> nil then
  begin
    FSelectedShape.AddPoint;
    FSelectedShape := nil;
  end;
end;

procedure TItemObjecterPresenter.AddPoly;
var
  vShape: TItemShaperPresenterFriend;
  vShapeModel: TItemShapeModel;
  vPoly: TPolygon;
begin
  vShapeModel := TItemShapeModel.CreatePoly(OnModelUpdate);

  SetLength(vPoly, 3);
  vPoly[0] := PointF(0, -FItemObjectModel.Height / 4);
  vPoly[1] := PointF(-FItemObjectModel.Width / 4, FItemObjectModel.Height / 4);
  vPoly[2] := PointF(FItemObjectModel.Width / 4, FItemObjectModel.Height / 4);

  vShapeModel.SetData(vPoly);

  vShape := TItemShaperPresenterFriend.Create(FView, vShapeModel);
  FItemObjectModel.AddShape(vShapeModel);
  FShapes.Add(vShape);
  RepaintShapes;
end;

function TItemObjecterPresenter.Bitmap: TBitmap;
begin
  FBmp.Width := Width;
  FBmp.Height := Height;
  FBmp.ClearRect(RectF(0, 0, Width, Height));
  FBmp.Canvas.BeginScene;
  FBmp.Canvas.StrokeThickness := 1;
  FBmp.Canvas.Stroke.Color := TAlphaColorRec.Red;
  FBmp.Canvas.Fill.Color := $339999ff;
  FBmp.Canvas.FillRect(
      RectF(0, 0, Width, Height), 0, 0, [], 1, FMX.Types.TCornerType.ctBevel);
  FBmp.Canvas.DrawRect(
      RectF(0, 0, Width, Height), 0, 0, [], 1, FMX.Types.TCornerType.ctBevel);
  FBmp.Canvas.EndScene;

  Result := FBmp;
end;

constructor TItemObjecterPresenter.Create(const AItemView: IItemView; const AItemObjectModel: TResourceModel);
begin
  inherited Create(AItemView);

  FCaptureType := ctNone;
  FBmp := TBitmap.Create;
  FParams := TDictionary<string, string>.Create;
  FItemObjectModel := AItemObjectModel;
  FItemObjectModel.UpdateHander := OnModelUpdate;
  FShapes := TList<TItemShaperPresenterFriend>.Create;
end;

procedure TItemObjecterPresenter.Delete;
begin
  if FSelectedShape <> nil then
  begin
    FShapes.Remove(FSelectedShape);
    Model.DelShape(FSelectedShape.Model);
    FSelectedShape := nil;
  end;
end;

procedure TItemObjecterPresenter.DelPoint;
begin
  if FSelectedShape <> nil then
  begin
    FSelectedShape.DelPoint;
    FSelectedShape := nil;
  end;
end;

destructor TItemObjecterPresenter.Destroy;
var
  i: Integer;
begin
  for i := 0 to FShapes.Count - 1 do
    FShapes[i].Free;
  FShapes.Free;
  FParams.Free;
  inherited;
end;

function TItemObjecterPresenter.GetHeight: Integer;
begin
  Result := FItemObjectModel.Height;
end;

function TItemObjecterPresenter.GetParams: TDictionary<string,string>;
begin
  FParams.Clear;
  FParams.Add('Name', Model.Name);
  FParams.Add('X', IntToStr(Model.Position.X));
  FParams.Add('Y', IntToStr(Model.Position.Y));
  FParams.Add('Width', IntToStr(Model.Width));
  FParams.Add('Height', IntToStr(Model.Height));
  Result := FParams;
end;

function TItemObjecterPresenter.GetPosition: TPoint;
begin
  Result := FItemObjectModel.Position;
end;

function TItemObjecterPresenter.GetRect: TRectF;
begin
  Result := System.Types.RectF(
    FItemObjectModel.Position.X,
    FItemObjectModel.Position.Y,
    FItemObjectModel.Position.X + FItemObjectModel.Width,
    FItemObjectModel.Position.Y + FItemObjectModel.Height);
end;

function TItemObjecterPresenter.GetWidth: Integer;
begin
  Result := FItemObjectModel.Width;
end;

procedure TItemObjecterPresenter.HideShapes;
begin
  FIsShapeVisible := False;
end;

procedure TItemObjecterPresenter.MouseDown;
var
  i: Integer;
  vPoint: TPointF;
  vKeyPoint: TPointF;
begin
  inherited;

  vPoint := FView.MousePos - PointF(FView.Width / 2, FView.Height / 2);
  if FIsShapeVisible then
  begin
    // Test on capturing KeyPoints of figures
    for i := 0 to FShapes.Count - 1 do
      if FShapes[i].KeyPointLocal(vPoint, vKeyPoint, 5, True) then
      begin
        FSelectedShape := FShapes[i];
        FShapes[i].MouseDown;
        FCapturedShape := FShapes[i];
        FCaptureType := ctKeyPoint;
        FStartCapturePoint := vPoint;

        RepaintShapes;
        Exit;
      end;

    // Test on capturing Figure
    for i := 0 to FShapes.Count - 1 do
      if FShapes[i].IsPointIn(vPoint) then
      begin
        FSelectedShape := FShapes[i];
        FShapes[i].MouseDown;
        FCapturedShape := FShapes[i];
        FCaptureType := ctFigure;
        FStartCapturePoint := vPoint;

        RepaintShapes;
        Exit;
      end;

      FLastTranslate := TPointF.Zero;
      FStartCapturePoint := TPointF.Zero;
  end;

  FCapturedShape := nil;
  FSelectedShape := nil;
  FCaptureType := ctNone;
  if Assigned(FOnMouseDown) then
    FOnMouseDown(Self);
end;

procedure TItemObjecterPresenter.MouseMove;
var
  i: Integer;
  vPoint, vKeyPoint: TPointF;
  vNeedRepaint: Boolean;
begin
  inherited;

  vNeedRepaint := False;
  vPoint := FView.MousePos - PointF(FView.Width / 2, FView.Height / 2);

  case FCaptureType of
    ctNone:
    begin
      for i := 0 to FShapes.Count - 1 do
        //if FShapes[i].IsPointIn(vPoint) then
        if FShapes[i].KeyPointLocal(vPoint, vKeyPoint, 5, True) then
        begin
          vNeedRepaint := True;
          FShapes[i].MouseMove;
        end;
    end;
    ctFigure:
    begin
      FCapturedShape.TranslateFigure(- FLastTranslate + vPoint - FStartCapturePoint );
      FLastTranslate := vPoint - FStartCapturePoint;
      vNeedRepaint := True;
    end;
    ctKeyPoint:
    begin
      FCapturedShape.ChangeLockedPoint(vPoint);
      vNeedRepaint := True;
    end;
  end;

  if vNeedRepaint then
     RepaintShapes;

  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self);
end;

procedure TItemObjecterPresenter.MouseUp;
var
  i: Integer;
begin
  inherited;

  if FIsShapeVisible then
    for i := 0 to FShapes.Count - 1 do
      if FShapes[i].IsPointIn(FView.MousePos) then
        FShapes[i].MouseUp;

  FCapturedShape := nil;
  FCaptureType := ctNone;
  FLastTranslate := TPointF.Zero;

  RepaintShapes;

  if Assigned(FOnMouseUp) then
    FOnMouseUp(Self)
end;

procedure TItemObjecterPresenter.OnModelUpdate(ASender: TObject);
var
  vModel: TResourceModel;
  vShape: TItemShaperPresenterFriend;
  i: Integer;
begin
  FView.Width := FItemObjectModel.Width;
  FView.Height:= FItemObjectModel.Height;
  FView.Left := FItemObjectModel.Position.X;
  FView.Top := FItemObjectModel.Position.Y;


  if ASender = nil then
    Exit;

  vModel := FItemObjectModel;

  for i := 0 to FShapes.Count - 1 do
    FShapes[i].Free;

  FShapes.Clear;

  for i := 0 to vModel.ShapesList.Count - 1 do
  begin
    vShape := TItemShaperPresenterFriend.Create(FView, vModel.ShapesList[i]);
    FShapes.Add(vShape);
  end;

  RepaintShapes;
end;

procedure TItemObjecterPresenter.Repaint;
begin
  OnModelUpdate(nil);
  RepaintShapes;
end;

procedure TItemObjecterPresenter.RepaintShapes;
var
  i: Integer;
begin
  FBmp := Bitmap;
  for i := 0 to FShapes.Count - 1 do
  if FShapes[i] = FSelectedShape then
    FShapes[i].Repaint(FBmp, TAlphaColorRec.Aqua)
  else
    FShapes[i].Repaint(FBmp);

  FView.AssignBitmap(FBmp);
end;

procedure TItemObjecterPresenter.SetHeight(const Value: Integer);
begin
  FItemObjectModel.Height := Value;
end;

procedure TItemObjecterPresenter.SetPosition(const Value: TPoint);
begin
  FItemObjectModel.Position := Value;
end;

procedure TItemObjecterPresenter.SetRect(const Value: TRectF);
begin
  Position := Value.TopLeft.Round;
  Width := Round(Value.Width);
  Height := Round(Value.Height);
end;

procedure TItemObjecterPresenter.SetWidth(const Value: Integer);
begin
  FItemObjectModel.Width:= Value;
end;

procedure TItemObjecterPresenter.ShowOptions;
begin
  if Assigned(FOnOptionsShow) then
    FOnOptionsShow(Self)
end;

procedure TItemObjecterPresenter.ShowShapes;
begin
  FIsShapeVisible := True;
  RepaintShapes;
end;

end.
