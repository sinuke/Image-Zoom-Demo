unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ExtCtrls, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects;

type
  TfmMain = class(TForm)
    ivImageViewer: TImageViewer;
    loBottomLayout: TLayout;
    sbZoomIn: TSpeedButton;
    sbZoomOut: TSpeedButton;
    lbZoomInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure ivImageViewerDblClick(Sender: TObject);
    procedure ivImageViewerGesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure ivImageViewerMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure ivImageViewerMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure sbZoomInClick(Sender: TObject);
    procedure sbZoomOutClick(Sender: TObject);
  private
    { Private declarations }
    FScalePicture: Single;
    FMousePos: TpointF;
    FFullSize: Boolean;
    FLastScale: Single;
    procedure SetScalePicture(const Value: Single);
    procedure SetMousePos(const Value: TpointF);
    procedure SetFullSize(const Value: Boolean);
    procedure SetLastScale(const Value: Single);
    procedure HelpContenBounds(Sender: TObject; var CBounds: TRectF);
    property ScalePicture: Single read FScalePicture write SetScalePicture;
    property MousePos: TpointF read FMousePos write SetMousePos;
    property FullSize: Boolean read FFullSize write SetFullSize;
    property LastScale: Single read FLastScale write SetLastScale;
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.fmx}

uses FMX.InertialMovement;

type
  THelpImageView = class(TScrollBox);

procedure TfmMain.FormCreate(Sender: TObject);
begin
  FFullSize := False;
  ivImageViewer.OnCalcContentBounds := HelpContenBounds;
  ivImageViewer.AniCalculations.BoundsAnimation := True;
  ivImageViewer.AniCalculations.Animation := True;
  ivImageViewer.AniCalculations.Averaging := True;
  ivImageViewer.AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
end;

procedure TfmMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if Key = vkVolumeUp then
    begin
      Key := 0;
      if FullSize then
        begin
          FullSize := not FullSize;
          ScalePicture := 1.20;
        end
      else
        ScalePicture := ScalePicture + 0.20;
      Exit;
    end;

  if Key = vkVolumeDown then
    begin
      Key := 0;
      if FullSize then
        begin
          FullSize := not FullSize;
          ScalePicture := 0.80;
        end
      else
        ScalePicture := ScalePicture - 0.20;
      Exit;
    end;
end;

procedure TfmMain.FormShow(Sender: TObject);
var
  SH, SW: Single;
begin
  SH := ivImageViewer.Height/ ivImageViewer.Bitmap.Height;
  SW := ivImageViewer.Width/ ivImageViewer.Bitmap.Width;
  if SW > SH then
    FScalePicture := SH
  else
    FScalePicture := SW;
  ScalePicture := FScalePicture;
  FLastScale := FScalePicture;
  lbZoomInfo.Text := 'Zoom: ' + FloatToStrF(FScalePicture * 100, ffFixed, 4, 0) + '%';
end;

procedure TfmMain.HelpContenBounds(Sender: TObject; var CBounds: TRectF);
var
  H: TComponent;
  BR: TRectF;
  I: TImage;
  B: TRectangle;
begin
  for H in ivImageViewer do
    begin
      if H is TImage then
        I := TImage(H);
      if H is TRectangle then
        B := TRectangle(H);
    end;
  I.Position.Point := PointF(0, 0);
  with THelpImageView(ivImageViewer) do
    begin
      I.BoundsRect := RectF(0, 0, ivImageViewer.Bitmap.Width * ScalePicture,
                                  ivImageViewer.Bitmap.Height * ScalePicture);
      if (Content <> nil) and (ContentLayout <> nil) then
        begin
          if I.Width < ContentLayout.Width then
            I.Position.X := (ContentLayout.Width - I.Width) * 0.5;
          if I.Height < ContentLayout.Height then
            I.Position.Y := (ContentLayout.Height - I.Height) * 0.5;
        end;
      CBounds := System.Types.UnionRect(RectF(0, 0, 0, 0), I.ParentedRect);
      if ContentLayout <> nil then
        BR := System.Types.UnionRect(CBounds, ContentLayout.ClipRect)
      else
        BR := I.BoundsRect;
      B.SetBounds(BR.Left, BR.Top, BR.Width, BR.Height);
      if CBounds.IsEmpty then
        CBounds := BR;
    end;
end;

procedure TfmMain.ivImageViewerDblClick(Sender: TObject);
begin
  FullSize := not FullSize;
end;

procedure TfmMain.ivImageViewerGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  LObj: IControl;
  S : Single;
begin
  LObj := Self.ObjectAtPoint(ClientToScreen(EventInfo.Location));
  if not Assigned(LObj) then
    Exit;
  if (LObj is TImageViewer) and (EventInfo.GestureID = igiPan) then
    ivImageViewer.AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
  if (LObj is TImageViewer) and (EventInfo.GestureID = igiZoom) then
    begin
      ivImageViewer.AniCalculations.TouchTracking := [];
      if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
        ivImageViewer.Tag := EventInfo.Distance;
      if (not(TInteractiveGestureFlag.gfBegin in EventInfo.Flags)) and
         (not(TInteractiveGestureFlag.gfEnd in EventInfo.Flags)) then
        begin
          FMousePos := PointF(0.0, 0.0);
          ivImageViewer.AniCalculations.TouchTracking := [];
          S := ((EventInfo.Distance - ivImageViewer.Tag) * ScalePicture) / PointF(Self.Width, Self.Height).Length;
          ivImageViewer.Tag := EventInfo.Distance;
          ScalePicture := ScalePicture + S;
        end;
      if TInteractiveGestureFlag.gfEnd in EventInfo.Flags then
        ivImageViewer.AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
    end;
  if (LObj is TImageViewer) and (EventInfo.GestureID = igiDoubleTap) then
    FullSize := not FullSize;
end;

procedure TfmMain.ivImageViewerMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if ssLeft in Shift then
    MousePos := PointF(X, Y);
end;

procedure TfmMain.ivImageViewerMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  ScalePicture := ScalePicture + ((WheelDelta * ScalePicture) / PointF(Self.Width, Self.Height).Length);
end;

procedure TfmMain.sbZoomInClick(Sender: TObject);
begin
  if FullSize then
    begin
      FullSize := not FullSize;
      ScalePicture := 1.20;
    end
  else
    ScalePicture := ScalePicture + 0.20;
end;

procedure TfmMain.sbZoomOutClick(Sender: TObject);
begin
  if FullSize then
    begin
      FullSize := not FullSize;
      ScalePicture := 0.80;
    end
  else
    ScalePicture := ScalePicture - 0.20;
end;

procedure TfmMain.SetFullSize(const Value: Boolean);
begin
  if Value then
    begin
      LastScale := ScalePicture;
      ScalePicture := 1;
    end
  else
    ScalePicture := LastScale;
  FFullSize := Value;
end;

procedure TfmMain.SetLastScale(const Value: Single);
begin
  FLastScale := Value;
end;

procedure TfmMain.SetMousePos(const Value: TpointF);
begin
  FMousePos := Value;
end;

procedure TfmMain.SetScalePicture(const Value: Single);
var
  R: IAlignRoot;
  S: Single;
  P, E, C: TPointF;
begin
  if Assigned(ivImageViewer) and not ivImageViewer.Bitmap.IsEmpty then
    begin
      if FScalePicture <> Value then
        begin
          S := FScalePicture;
          FScalePicture := Value;
          if FScalePicture < 0.1 then
            FScalePicture := 0.1;
          if FScalePicture > 10 then
            FScalePicture := 10;
          lbZoomInfo.Text := 'Zoom: ' + FloatToStrF(FScalePicture * 100, ffFixed, 4, 0) + '%';
          S := FScalePicture / S;
          ivImageViewer.AniCalculations.Animation := False;
          ivImageViewer.BeginUpdate;
          C := PointF(ivImageViewer.ClientWidth, ivImageViewer.ClientHeight);
          if FMousePos.IsZero then
            P := C * 0.5
          else
            P := FMousePos;
          E := ivImageViewer.ViewportPosition;
          E := E + P;
          ivImageViewer.InvalidateContentSize;
          R := ivImageViewer;
          R.Realign;
          ivImageViewer.ViewportPosition := (E * S) - P;
          ivImageViewer.EndUpdate;
          ivImageViewer.AniCalculations.Animation := True;
          ivImageViewer.Repaint;
        end;
    end;
end;

end.


