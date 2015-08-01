unit uEngine2DObjectShape;

interface

uses
  System.Types, System.Generics.Collections, System.UITypes, System.Math,
  {$IFDEF VER290} System.Math.Vectors, {$ENDIF}
  uEngine2DClasses, uIntersectorFigure, uIntersectorCircle, uIntersectorPoly,
  uIntersectorMethods, uIntersectorShapeModificator, uIntersectorClasses, uNewFigure;

type
  TObjectShape = class
  private
    FFigures: TArray<TNewFigure>;
    FParent: Pointer;
    FOwner: Pointer;
    FNeedRecalc: Boolean;
    FSize: Single;
    function GetOuterRect: TRectF;
    function GetFigure(Index: Integer): TNewFigure;
    //procedure SetFigure(Index: Integer; const Value: TFigure);
    function GetCount: Integer;
    procedure SetSize(const Value: Single);
    function PointToLocal(const APoint: TPointF): TPointF;
  public
    property NeedRecalc: Boolean read FNeedRecalc write fNeedRecalc; // ����������, ����� �� ������������� ������
    property Parent: Pointer read FParent write FParent; // ������ �� TEngine2D
    property Owner: Pointer read FOwner write FOwner; // ������ ������ TEngine2DObject
    property Figures[Index: Integer]: TNewFigure read GetFigure; default;
//    function ToWorldCoord(const AFigure: TFigure): TFigure;
//    property OriginFigures
//    property OriginFigures: TList<TFigure> read FOriginFigures;
//    property Modificators: TList<TShapeModificator> read FModificators write FModificators;
    property Count: Integer read GetCount;
    property OuterRect: TRectF read GetOuterRect;
    property Size: Single read FSize write SetSize; // ����������� ��� ������� ��������
    procedure Draw; // ������ ����� ������
//    procedure Recalc; // ������������� ������, �������� ��������, �������� � ��������� �������
    function IsPointInFigure(const APoint: TPointF; const AFigure: TNewFigure): Boolean;
    function AddFigure(AFigure: TNewFigure): Integer;
    function RemoveFigure(const AIndex: Integer): TFigure;
    function UnderTheMouse(const MouseX, MouseY: double): boolean; virtual; // �������, ������ �� ���� � ���� �������. ���� � ��������� - ���������� �������������� �������
    function IsIntersectWith(AShape: TObjectShape): Boolean; // ������������ �� � ���������� �������
    function Intersections: TList<TObjectShape>; // ������ ���� ����������� � ������� ��������
    procedure ToGlobal;
    constructor Create;
    destructor Destroy;
  const
    pi180 = 0.01745329251;
  end;

implementation

uses
  uEngine2DObject;

{ TObjectShape }

function TObjectShape.AddFigure(AFigure: TNewFigure): Integer;
begin
//  SetLength(FCalcedFigures, Length(FCalcedFigures) + 1);
  SetLength(FFigures, Length(FFigures) + 1);
  FFigures[High(FFigures)] := AFigure;
//  FCalcedFigures[High(FOriginFigures)] := AFigure.Clone;

  Result := High(FFigures);
end;

constructor TObjectShape.Create;
begin

end;

destructor TObjectShape.Destroy;
var
  i, vN: Integer;
begin
  vN := Length(FFigures)- 1;

  for i := vN downto 0 do
  begin
    FFigures[i].Free;
  end;

  SetLength(FFigures, 0);
end;

procedure TObjectShape.Draw;
var
  vFigure: TNewFigure;
begin
  // it's only for debug, so it is not very fast
  if Length(Self.FFigures) > 0 then
  begin
    for vFigure in FFigures do
    begin
//      vTemp := vFigure.Clone;
      vFigure.TempTranslate(PointF(TEngine2DObject(Owner).x, TEngine2DObject(Owner).y));

      with TEngine2DObject(Owner) do
      begin
        // Maximal radius of Figure to quick select
        Image.Bitmap.Canvas.Fill.Color := TAlphaColorRec.Gray;
        Image.Bitmap.Canvas.FillEllipse(
          RectF(
            X - vFigure.TempMaxRadius, Y - vFigure.TempMaxRadius,
            X + vFigure.TempMaxRadius, Y + vFigure.TempMaxRadius),
          0.15
        );
      end;
    end;
  end
  else begin
    TEngine2DObject(Owner).Image.Bitmap.Canvas.Fill.Color := TAlphaColorRec.Red;
    TEngine2DObject(Owner).Image.Bitmap.Canvas.FillEllipse
      (RectF(
        TEngine2DObject(Owner).X - TEngine2DObject(Owner).w * 0.5,
        TEngine2DObject(Owner).Y - TEngine2DObject(Owner).h * 0.5,
        TEngine2DObject(Owner).X + TEngine2DObject(Owner).w * 0.5,
        TEngine2DObject(Owner).Y + TEngine2DObject(Owner).h * 0.5),
        TEngine2DObject(Owner).opacity * 0.5);

  end;

  // Center of the all figures. Base point of sprite
  with TEngine2DObject(Owner) do
  begin
    Image.Bitmap.Canvas.Fill.Color := TAlphaColorRec.Aliceblue;
    Image.Bitmap.Canvas.FillEllipse(RectF(X - 3, Y - 3, X + 3, Y + 3), 1);
  end;
end;

function TObjectShape.GetCount: Integer;
begin
  Result := Length(FFigures);
end;

function TObjectShape.GetFigure(Index: Integer): TNewFigure;
begin
  Result := FFigures[Index];
end;

function TObjectShape.GetOuterRect: TRectF;
var
  vLeft, vRight: TPointF;
  i, vN: Integer;
begin
  { if FFigures.Count > 0 then
  begin
    vLeft := FFigures[0].FigureRect.TopLeft;
    vRight := FFigures[0].FigureRect.BottomRight;
    vN := FFigures.Count - 1;
    for i := 1 to vN do
    begin
      if vLeft.X > FFigures[i].FigureRect.Left then
        vLeft.X := FFigures[i].FigureRect.Left;
      if vLeft.Y > FFigures[i].FigureRect.Top then
        vLeft.Y := FFigures[i].FigureRect.Top;
      if vRight.X < FFigures[i].FigureRect.Right then
        vRight.X := FFigures[i].FigureRect.Right;
      if vRight.Y < FFigures[i].FigureRect.Bottom then
        vRight.Y := FFigures[i].FigureRect.Bottom;
    end;
    Exit(RectF(vLeft.X,vLeft.Y, vRight.X, vRight.Y));
  end;
  Result := TRectF.Empty;  }
end;

function TObjectShape.Intersections: TList<TObjectShape>;
begin
end;

function TObjectShape.IsIntersectWith(AShape: TObjectShape): Boolean;
var
  i, j, vN, vL: Integer;
  vFigure: TNewFigure;
  vOwner, vShapeOwner: tEngine2DObject;
begin
{  Sqr(FFigures[i].X - FFigures[j].X) + Sqr(FFigures[i].Y - FFigures[j].Y) <=
   Sqr(FFigures[i].MaxRadius+FFigures[j].MaxRadius)}
  vOwner := FParent;
  vShapeOwner := AShape.Owner;
  vN := Self.Count - 1;
  vL := AShape.Count - 1;
  AShape.ToGlobal;
  Self.ToGlobal;
  for i := 0 to vN do
  begin
   // vFigure := FFigures[i];

    for j := 0 to vL do
      if FFigures[i].FastIntersectWith(AShape[j]) then
        if FFigures[i].IsIntersectWith(AShape[j]) then
          Exit(True);
  end;
     { then
        begin
           //���� ���������� � ���������� ���������� ����� ����������
          Exit(True)

      {    if Distance(FFigures[i].Center, FFigures[j].Center) <
            Sqrt(FFigures[i].MaxRadius *  tEngine2DObject(Self.Owner).ScaleX) }
  {  vFigure := FFigures[i];
    if vFigure is TPolyFigure then
      vPoly1 := MatrixTransform(TPolyFigure(vFigure).AsType);
    if vFigure is TPolyFigure then
      vCircle1 := MatrixTransform(TCircleFigure(vFigure).AsType);  }

{         if IsFiguresCollide(
           vFigure,
           AShape.Figures[j].InGlobal(tEngine2DObject(AShape.Owner).ScalePoint, tEngine2DObject(AShape.Owner).Rotate, tEngine2DObject(AShape.Owner).Center)
         ) then
          Exit(True)  }
      //  end;
//  if (FFigures[i]) is TCircleFigure


  Result := False;
end;

function TObjectShape.IsPointInFigure(const APoint: TPointF; const AFigure: TNewFigure): Boolean;
var
  vPoint: TPointF;
begin
//  Result := False;
  vPoint := PointToLocal(APoint);
  Result := AFigure.BelongPointLocal(vPoint);

//  Result := AFigure.BelongPointLocal(APoint.X - TEngine2DObject(Owner).x, APoint.Y - TEngine2DObject(Owner).y)
{  if AFigure is TPolyFigure then
    Result := uIntersectorMethods.IsPointInPolygon(APoint, TPolyFigure(AFigure).AsType);

  if AFigure is TCircleFigure then
    Result := uIntersectorMethods.IsPointInCircle(APoint, TCircleFigure(AFigure).AsType);  }
end;

function TObjectShape.PointToLocal(const APoint: TPointF): TPointF;
var
  vRes: TVector;
  vScale, vRotate, vTranslate: TMatrix;
begin
    vRotate := TMatrix.CreateRotation(-tEngine2DObject(Owner).Rotate * pi180);
    vScale := TMatrix.CreateScaling(1 / tEngine2DObject(Owner).ScaleX, 1 / tEngine2DObject(Owner).ScaleY);
    Result := TVector.Create(APoint.X - tEngine2DObject(Owner).x, APoint.y - tEngine2DObject(Owner).y) * vScale * vRotate;
 // end;


  //vScale :=
//X = x0 + (x - x0) * cos(a) - (y - y0) * sin(a);
//Y = y0 + (y - y0) * cos(a) + (x - x0) * sin(a);
{  with tEngine2DObject(Owner) do
  Result := PointF(
    (AX * ScaleX - x) * Cos(Rotate * pi180)
      -
    (AY * ScaleY - y) * Sin(Rotate * pi180)
      - x
      ,
    (AY * ScaleY - y) * Cos(Rotate * pi180)
      +
    (AX * ScaleX - x) * Sin(Rotate * pi180)
  ); }
end;

function TObjectShape.RemoveFigure(const AIndex: Integer): TFigure;
begin

end;

{procedure TObjectShape.Recalc;
var
  i, vN: Integer;
begin
  vN := FFigures.Count - 1;
  for i := 0 to vN do
    FFigures[i].Position := TEngine2DObject(FOwner).Position;
end;  }

{procedure TObjectShape.SetFigure(Index: Integer; const Value: TFigure);
begin
  FFigures[Index] := Value;
end;}

procedure TObjectShape.SetSize(const Value: Single);
begin
  FSize := Value;
end;

procedure TObjectShape.ToGlobal;
var
  vFigure: TNewFigure;
begin
  for vFigure in FFigures do
  begin
    vFigure.Reset;
    vFigure.TempScale(tEngine2DObject(Owner).ScalePoint);
    vFigure.TempRotate(tEngine2DObject(Owner).Rotate);
    vFigure.TempTranslate(tEngine2DObject(Owner).Center);
  end;
end;

(* function TObjectShape.ToWorldCoord(const AFigure: TFigure): TFigure;
var
  i, vN: Integer;
begin

 { Result := AFigure.Clone.FastMigration(
    PointF(TEngine2DObject(Owner).x,  TEngine2DObject(Owner).y),
    PointF(TEngine2DObject(Owner).ScaleX,  TEngine2DObject(Owner).ScaleY),
    TEngine2DObject(Owner).Rotate
  );  }
  vN := Length(FOriginFigures) - 1;
  for i := 0 to vN do
  begin
    FCalcedFigures[i].Assign(FOriginFigures[i]);
    FCalcedFigures[i].FastMigration(
      PointF(TEngine2DObject(Owner).ScaleX,  TEngine2DObject(Owner).ScaleY),
      TEngine2DObject(Owner).Rotate
    );
{    FFigures[i].Scale(PointF(tEngine2DObject(FOwner).ScaleX, tEngine2DObject(FOwner).ScaleY));
    FFigures[i].Rotate(tEngine2DObject(FOwner).Rotate);
    FFigures[i].Translate(PointF(tEngine2DObject(FOwner).X, tEngine2DObject(FOwner).Y));}
  end;


  {TEngine2DObject(Owner).x -  TEngine2DObject(Owner).w*0.5,
    TEngine2DObject(Owner).y -  TEngine2DObject(Owner).h*0.5,
    TEngine2DObject(Owner).x +  TEngine2DObject(Owner).w*0.5,
    TEngine2DObject(Owner).y +  TEngine2DObject(Owner).h*0.5),   }

end;   *)

function TObjectShape.UnderTheMouse(const MouseX, MouseY: double): boolean;
var
  i: Integer;
begin
  for i := 0 to High(FFigures) do
  begin
    if IsPointInFigure(PointF(MouseX, MouseY), Self.FFigures[i]) then
      Exit(True);
  end;

  Result := False;
end;

end.
