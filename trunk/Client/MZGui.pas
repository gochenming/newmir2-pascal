unit MZGui;

interface
uses
  MondoZenGL, Classes,Texture,GfxFont,Windows;
type
  TKeyState = (kAlt, kShift, kCtrl, mLeft, mMiddle, mRight);
  TKeyStates = set of TKeyState;
  TOnClick = procedure (key: TKeyStates; X, Y: integer) of object;
  TOnMouseMove = procedure(key: TKeyStates;X, Y: integer) of object;
  TOnMouseDown = procedure(key: TKeyStates;Button:TMZMouseButton; X, Y: integer) of object;
  TOnMouseUp = procedure(key: TKeyStates;Button:TMZMouseButton;X, Y: Integer) of object;
  TOnEnterLeave =procedure of object;
  TKeyEvent=Procedure(Key:TKeyStates;Button:TMZKeyCode);

  TGuiRect = record
    X, Y, W, H: Integer;
  end;

  TGuiObject = class
  protected
  MovingDownX,MovingDownY:Integer; //为移动控件做处理
  public
    SubGuiObjects: TList;
    Parent: TGuiObject;
    Rect: TGuiRect;
    Caption: string;
    Visable: Boolean;
    CanMove:Boolean;
    ProcessObject:TGuiObject;//上次处理的对象用来实现enter leave事件
    MoveObject:TGuiObject;
    OnClick: TOnClick;
    OnMouseMove: TOnMouseMove;
    OnMouseDown: TOnMouseDown;
    OnMouseUp: TOnMouseUp;
    OnEnter:TOnEnterLeave;
    OnLeave:TOnEnterLeave;
    OnkeyUp:TKeyEvent;
    OnkeyDown:TKeyEvent;
    procedure Add(GuiObject: TGuiObject);virtual;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Draw(S:TMZScene); virtual;
    procedure ConvertLocalToScene(Lx, ly: Integer; var sX, sY: Integer);
    procedure ConvertCoordinateToLocal(var lx,ly:Integer;sX,sY:integer); //转换父坐标到子坐标
    procedure ConvertCoordinateToParent(var Dx,Dy:integer;Lx,ly:integer);//转换子坐标到父坐标
    function InRange(x, y: integer): Boolean;
    procedure RegMoveingObject(G:TGuiobject;x,y:integer);
    procedure Update(dt:Double);virtual;
    function MouseMove(key: TKeyStates; X, Y: integer): Boolean; virtual;
    function MouseDown(key: TKeyStates;Button:TMZMouseButton; X, Y: integer): Boolean; virtual;
    function MouseUp(key: TKeyStates;Button:TMZMouseButton; X, Y: integer): Boolean; virtual;
    function Click(key: TKeyStates;X, Y: integer): Boolean; virtual;
    Function KeyUp(Key:TKeyStates;Button:TMZKeyCode):Boolean;virtual;
    Function KeyDown(Key:TKeyStates;Button:TMZKeyCode):Boolean;virtual;
    Function Enter:Boolean;virtual;
    Function Leave:Boolean;virtual;
  end;
  TGuiForm = class(TGuiObject)
  public
    BackgroundTexture:TTexture;
    constructor Create(Texture:TTexture);
    destructor Destroy; override;
    procedure Draw(S:TMZScene);override;
  end;
  TGuiButton = class(TGuiObject)
  protected
    Texture: TTexture;
  public
    TextureNormal: TTexture;
    TexturePressed: TTexture;
    TextureHit: TTexture;
    ClickSound: TMZStaticSound;
    function Click(key: TKeyStates; X: Integer; Y: Integer): Boolean; override;
    constructor Create; override;
    destructor Destroy; override;
    procedure Draw(S:TMZScene); override;
    function MouseDown(key: TKeyStates;Button:TMZMouseButton; X: Integer; Y: Integer): Boolean;
      override;
    function MouseUp(key: TKeyStates;Button:TMZMouseButton; X: Integer; Y: Integer): Boolean;
      override;
    function MouseMove(key: TKeyStates; X: Integer; Y: Integer): Boolean;
      override;
    Function Enter:Boolean;override;
    Function leave:Boolean;override;
  end;
    TGuiEdit=class(TGuiObject)
    Private
     CursorLineAlpha:Byte;
     public
     Text:string;
     Font:TGfxFont;
     CursorPos:Integer;//光标所在的位置。
     DrawText:string;//会显示出来的文字；
     DrawTextLength:Integer;//会显示出来文字的长度
     MaxLength:integer;
     IsDrawRectLine:Boolean;
     RectLineColor:Cardinal;
     PassWordChar:Char;
     isInPutPassWord:Boolean;
     procedure Draw(S:TMZScene);override;
     procedure Update(dt:double);override;
     constructor Create;
     function Click(key: TKeyStates; X: Integer; Y: Integer): Boolean; override;
     function KeyUp(Key: TKeyStates; Button: TMZKeyCode): Boolean; override;
     function KeyDown(Key: TKeyStates; Button: TMZKeyCode): Boolean; override;
    end;



    TGuiManager=class(TGuiObject)
    private
      Scene:TMZScene;
      FCount:Integer;
      class var FInstance:TGuiManager;
      constructor Create; override;
    Protected
      Procedure Add(GuiObject:TGuiObject);override;
    public
      Class var FoucsGui:TGuiObject;
      procedure Draw;
      procedure ResetToScene(S:TMZScene);
      destructor Destroy; override;
      class Function GetInstance:TGuimanager;
      property Count:integer Read Fcount;

  end;
implementation
uses
  sysutils, DrawEx,zgl_main;

{ TGuiObject }

procedure TGuiObject.Add(GuiObject: TGuiObject);
begin
  SubGuiObjects.Add(GuiObject);
  GuiObject.Parent := Self;
end;

function TGuiObject.Click(key: TKeyStates; X, Y: integer): Boolean;
var
nX,nY,I:Integer;
GuiObject:TGuiObject;
begin
  Result := False;
  if not Visable then  Exit;
  ConvertCoordinateToLocal(nX,nY,x,y);
  //向子控件派发点击消息
  for i :=0 to SubGuiObjects.Count-1 do
  begin
   GuiObject:=SubGuiObjects[i];
   if GuiObject.Click(key,nx,ny) then
   begin
   //如果子控件处理了。则退出。
     Result:=True;
     Exit;
   end;
   end;
  if InRange(X, Y) then
  begin
    Result:=True;
    if Assigned(OnClick) then OnClick(key,nx,ny);
  end;
end;

procedure TGuiObject.ConvertLocalToScene(Lx, ly: Integer; var sX, sY: Integer);
begin
  if Assigned(Parent) then
    Parent.ConvertLocalToScene(lx + Rect.X, ly + Rect.Y, sX, sY)
  else
  begin
    sX := Lx + Rect.X;
    sY := ly + Rect.Y;
  end;
end;

procedure TGuiObject.ConvertCoordinateToLocal(var lx, ly: Integer; sX, sY: integer);
begin
lx:=sX-Rect.x;
ly:=sy-Rect.y;
end;

procedure TGuiObject.ConvertCoordinateToParent(var Dx, Dy: integer; Lx,
  ly: integer);
begin
  Dx:=Rect.X+Lx;
  Dy:=Rect.y+ly;
end;

constructor TGuiObject.Create;
begin
  OnClick := nil;
  OnMouseMove := nil;
  OnMouseDown := nil;
  OnMouseUp := nil;
  Parent := nil;
  Visable := True;
  SubGuiObjects := TList.Create;
  CanMove:=False;
end;

destructor TGuiObject.Destroy;
begin
  SubGuiObjects.Free;
  inherited;
end;


procedure TGuiObject.Draw(S: TMZScene);
var
i:Integer;
GuiObject:TGuiObject;
begin
for I := 0 to SubGuiObjects.Count-1 do
begin
GuiObject:=SubGuiObjects[i];
GuiObject.Draw(S);
end;

end;

function TGuiObject.Enter: Boolean;
begin
if Assigned(OnEnter) then OnEnter;
end;

function TGuiObject.InRange(x, y: integer): Boolean;
begin
  Result := False;
  if (X > Rect.X) and (X < (Rect.X + Rect.W)) and (Y > Rect.Y) and (Y < (Rect.Y + Rect.H)) then Result:=True;
end;

function TGuiObject.KeyDown(Key: TKeyStates; Button: TMZKeyCode): Boolean;
var
i:Integer;
GuiObject:TGuiObject;
begin
Result:=False;
if not Visable then Exit;
for I := 0 to SubGuiObjects.Count-1 do
  begin
    GuiObject:=SubGuiObjects[i];
    if GuiObject.KeyDown(key,Button) then
    begin
      Result:=True;
      Exit;
    end;
  end;

  if Equals( TGuiManager.FoucsGui) then
  begin
  Result:=True;
   if Assigned(OnkeyDown) then
   begin
    OnkeyDown(key,Button);
   end
  end;
end;

function TGuiObject.KeyUp(Key: TKeyStates; Button: TMZKeyCode): Boolean;
var
i:Integer;
GuiObject:TGuiObject;
begin
Result:=True;
if not Visable then Exit;
for I := 0 to SubGuiObjects.Count-1 do
  begin
    GuiObject:=SubGuiObjects[i];
    if GuiObject.KeyUp(key,Button) then
    begin
      Result:=True;
      Exit;
    end;
  end;
  if Equals( TGuiManager.FoucsGui) then
  begin
   if Assigned(OnkeyUp) then
   begin
     OnkeyUp(key,Button);
     Result:=True;
    end
  end;
end;

function TGuiObject.Leave: Boolean;
begin
if Assigned(OnLeave) then OnLeave;

end;

function TGuiObject.MouseDown(key: TKeyStates;Button:TMZMouseButton; X, Y: integer): Boolean;
var
  i: Integer;
  GuiObject: TGuiObject;
  nX,nY:Integer;
begin
  Result := False;
  if not Visable then
    Exit;
   ConvertCoordinateToLocal(nX,nY,x,y);
   //既然是在范围内，而已又是可视状态。那么说明已经派发到位了
   //如果按下的是左键，则告诉父控件 按下的坐标。
   //以及自身的对象。
   if CanMove then
   begin
    if Button = mbLeft then
    begin
    if Assigned(Parent) then Parent.RegMoveingObject(Self,nx,ny);
    end;
   end;

  for I := 0 to SubGuiObjects.Count - 1 do
  begin
     GuiObject := SubGuiObjects[i];
    if GuiObject.MouseDown(key,Button,nX, nY) then
    begin
      Result:=True;
      Exit;
    end;
  end;

    if InRange(X, Y) then
    begin
     Result:=True;
     TGuiManager.FoucsGui:=Self;
    if Assigned(OnMouseDown) then OnMouseDown(key,Button, nx, ny);
    end;

end;

function TGuiObject.MouseMove(key: TKeyStates; X, Y: integer): Boolean;
var
  i: Integer;
  GuiObject: TGuiObject;
  LocalX,LocalY:Integer;
  SubGuiIsProcessMsg:Boolean;
begin
  Result := False;
  if not Visable then Exit;
    //处理子控件的移动位置事件
  if  Assigned(MoveObject)then
  begin
   if mLeft in key then
   begin
    MoveObject.Rect.X:=x-MovingDownX;
    MoveObject.Rect.Y:=y-MovingDownY;
    //不许移动到左边看不见的地方
    if MoveObject.Rect.X < 0 then MoveObject.Rect.X:=0;
    if MoveObject.Rect.Y <0 then MoveObject.Rect.Y:=0;
    //不许移动到右边看不见的地方
    if MoveObject.Rect.X+MoveObject.Rect.W > Rect.X+Rect.W then
    MoveObject.Rect.X:=Rect.W-MoveObject.Rect.W;
    if MoveObject.Rect.Y+MoveObject.Rect.H > Rect.Y+Rect.H then
    MoveObject.Rect.Y:=Rect.H-MoveObject.Rect.H;
   end;
   Exit;
  end;
   ConvertCoordinateToLocal(LocalX,LocalY,x,y);
  //遍历子控件 如果子控件处理了此事件则退出 不处理
  for I := 0 to SubGuiObjects.Count - 1 do
  begin
    GuiObject := SubGuiObjects[i];
    if GuiObject.MouseMove(key,LocalX,LocalY) then
    begin
    if Assigned(ProcessObject) then
      begin
        if not ProcessObject.Equals(GuiObject) then
        begin
        GuiObject.Enter;
        ProcessObject.Leave;
        ProcessObject:=GuiObject;
        end;
      end else
      begin
       ProcessObject:=GuiObject;
       GuiObject.Enter;
      end;
     Result:=True;
     Exit;
    end;
  end;

  if  InRange(X, Y) then
  begin
  Result:=True;
   if Assigned(OnMouseMove) then OnMouseMove(key, LocalX, LocalY);
  end;

end;

function TGuiObject.MouseUp(key: TKeyStates;Button:TMZMouseButton; X, Y: integer): Boolean;
var
  i: Integer;
  GuiObject: TGuiObject;
  LocalX, LocalY: Integer;
begin
  Result := False;
  if not Visable then
    Exit;
    if Button =mbLeft then
    begin
    MoveObject:=nil;
    MovingDownX:=0;
    MovingDownY:=0;
    end;
    ConvertCoordinateToLocal(LocalX,LocalY,X,y);
  for I := 0 to SubGuiObjects.Count - 1 do
  begin
    GuiObject := SubGuiObjects[i];
    if GuiObject.MouseUp(key,Button, LocalX, LocalY) then
    begin
      Result := True;
      Exit;
    end
  end;

   if InRange(X, Y) then
   begin
   Result:=True;
   if Assigned(OnMouseUp) then OnMouseUp(key,Button, LocalX, LocalY);
   end;

end;

procedure TGuiObject.RegMoveingObject(G: TGuiobject; x, y: integer);
begin
MoveObject:=G;
MovingDownX:=x;
MovingDownY:=y;
end;

procedure TGuiObject.Update(dt: Double);
var
I:Integer;
begin
for i := 0 to SubGuiObjects.Count-1 do
begin
  TGuiObject(SubGuiObjects[i]).Update(dt);
end;

end;

{ TGuiButton }

function TGuiButton.Click(key: TKeyStates; X, Y: Integer): Boolean;
begin
Result:=inherited;
if Result then
 begin
   if Assigned(ClickSound) then
    ClickSound.Play();
  end;

end;

constructor TGuiButton.Create;
begin
  inherited Create;
  TextureNormal := nil;
  TexturePressed := nil;
  TextureHit := nil;
  ClickSound := nil;
end;

destructor TGuiButton.Destroy;
begin
  FreeAndNil(TextureNormal);
  FreeAndNil(TexturePressed);
  FreeAndNil(TextureHit);
  FreeAndNil(ClickSound);
  inherited;
end;

procedure TGuiButton.Draw(S:TMZScene);
var
  nX, nY: Integer;
begin
  inherited;
  nX := 0;
  nY := 0;
  if Assigned(S) then
  begin
    ConvertLocalToScene(0, 0, nX, nY);
    if Assigned(Texture) then
    DrawTexture2Canvas(S.Canvas, Texture.m_Texture, nX, nY);
  end;

end;

Function TGuiButton.Enter:Boolean;
begin
Texture := TextureHit;
inherited;
end;

Function TGuiButton.leave:Boolean;
begin
Texture := TextureNormal;
inherited;
end;

function TGuiButton.MouseDown(key: TKeyStates;Button:TMZMouseButton; X, Y: Integer): Boolean;
begin
  Result:=False;
  if inherited then
  begin
    Texture := TexturePressed;
    Result:=True;
  end;
end;

function TGuiButton.MouseMove(key: TKeyStates; X, Y: Integer): Boolean;
begin
  Result:=False;
  if inherited then
  begin
    Texture := TextureHit;
    Result:=True;
  end;
end;

function TGuiButton.MouseUp(key: TKeyStates;Button:TMZMouseButton; X, Y: Integer): Boolean;
begin
  Result:=False;
  if inherited then
  begin
  Texture :=TextureNormal;
  Result:=True;
  end;

end;

{ TMZForm }

constructor TGuiForm.Create(Texture:TTexture);
begin
  inherited Create;
  BackgroundTexture:=Texture;
  Rect.W:=Texture.m_Texture.Width;
  Rect.H:=Texture.m_Texture.Height;
end;

destructor TGuiForm.Destroy;
begin
  BackgroundTexture.Free;
  inherited;
end;

procedure TGuiForm.Draw(S:TMZScene);
begin
  if not Visable then Exit;

  if Assigned(S) then
  begin
    if Assigned(BackgroundTexture) then DrawTexture2Canvas(S.Canvas,BackgroundTexture.m_Texture,Rect.X,Rect.Y);
  end;
  inherited;
end;



{ TGuiManager }

procedure TGuiManager.Add(GuiObject: TGuiObject);
begin
  inherited;
  FCount:=SubGuiObjects.Count;
end;

constructor TGuiManager.Create;
begin
  inherited;

end;

destructor TGuiManager.Destroy;
begin
  ResetToScene(nil);
  inherited;
end;

procedure TGuiManager.Draw;
var
  GuiObject:TGuiObject;
  I:Integer;
begin
for I := 0 to SubGuiObjects.Count-1 do
begin
   GuiObject:=SubGuiObjects[i];
   GuiObject.Draw(Scene);
end;
end;

class function TGuiManager.GetInstance: TGuimanager;
begin
if not Assigned(Finstance) then FInstance:=TGuiManager.Create;
Result:=Finstance;



end;

procedure TGuiManager.ResetToScene(S: TMZScene);
var
I:Integer;
Gui:TGuiObject;
begin
for i := 0 to SubGuiObjects.Count-1 do
  begin
    Gui:=SubGuiObjects[i];
    FreeAndNil(Gui);
  end;
  SubGuiObjects.Clear;
  Scene:=S;
end;

{ TGuiEdit }

function TGuiEdit.Click(key: TKeyStates; X, Y: Integer): Boolean;
var
isFoucs:Boolean;
begin
isFoucs:=False;
if Equals(TGuiManager.FoucsGui) then isFoucs:=True;

Result:=inherited;
if Result then
begin
  if isFoucs then Exit;
  TMZKeyboard.EndReadText;
  TMZKeyboard.BeginReadText();
end;
end;

constructor TGuiEdit.Create;
begin
inherited;
IsDrawRectLine:=True;
Text:='';
DrawText:='';
DrawTextLength:=0;
CursorPos:=0;
RectLineColor:=$FFFFFF;
isInPutPassWord:=False;
PassWordChar:='*';
end;

procedure TGuiEdit.Draw(S: TMZScene);
var
Tmp:string;
FontWidth,FontHeight:Single;
FontSize:TSize;
DrawX,DrawY:Integer;
i:Integer;
begin
  inherited;
 if Assigned(S) then
 begin
  ConvertLocalToScene(0,0,DrawX,DrawY);
  //画边框
  if IsDrawRectLine then s.Canvas.DrawRect(DrawX,DrawY,Rect.W,Rect.H,RectLineColor,$FF,[]);
  //画文字
  //FontSize:=Font.GetTextSize(PWideChar(Text));
  FontWidth:=Font.TextWidth(Text);
  //FontWidth:=FontSize.cx;
 // FontHeight:=FontSize.cy;



  // if FontHeight <= Rect.H then Exit;//如果编辑框的高度比字体的高度小就不画了字了。

    //判断文字是否能全部画出来
    if FontWidth >Rect.W-3 then //三个像素为了画光标
    begin
      //如果不可以全部画出来。
    end
    else
    begin
    //如果可以全部画出来。
      DrawText:=Text;
      if isInPutPassWord then //如果输入的是密码框
      begin
       for I := 0 to Length(DrawText)-1 do
         begin
           DrawText[i]:=PassWordChar;
         end;
      end;
     Font.TextOut(DrawX+2,DrawY+3,DrawText);
    end;

     //画光标
     if not Equals(TGuiManager.FoucsGui) then Exit;

     if CursorPos > 0 then
      begin
       Tmp:=Copy(DrawText,0,CursorPos);
       //FontSize:=Font.GetTextSize(PWideChar(Tmp));
       FontWidth:=Font.TextWidth(Tmp);
       s.Canvas.FillRect(DrawX+FontWidth+2,DrawY+2,1,Rect.H-4,$FFFFFF,CursorLineAlpha);
      end else
      begin
      s.Canvas.FillRect(DrawX+2,DrawY+2,1,Rect.H-4,$FFFFFF,CursorLineAlpha);
      end;

   end;


end;

function TGuiEdit.KeyDown(Key: TKeyStates; Button: TMZKeyCode): Boolean;
var
Tmp:string;
begin
if inherited then
begin
  if Equals( TGuiManager.FoucsGui) then
  begin
  if Button=kcLeft then
  begin
  Dec(CursorPos);
  //if CursorPos < 0 then CursorPos:=0;
  end;

  if Button=kcRight then
  begin
   Inc(CursorPos);
   //if CursorPos > Length(Text) Then CursorPos:=Length(Text);
  end;


  if Button=kcBackspace then
  begin
    //获取光标所在之前不包含删掉一个的文字。
    Tmp:=Copy(Text,0,CursorPos-1);
    //获取光标后的文字
    Text:=Tmp+Copy(Text,CursorPos+1,Length(Text));
    Dec(CursorPos);
  end;

  Result:=True;
  end;
end;
end;

function TGuiEdit.KeyUp(Key: TKeyStates; Button: TMZKeyCode): Boolean;
begin

end;

procedure TGuiEdit.Update(dt: double);
var
tmp,CurL,CurR:string;
LastLength:Integer;
IncLength:Integer;
begin
   DEC(CursorLineAlpha,30);
  if Equals( TGuiManager.FoucsGui) then //如果自己是焦点控件则获取文本。否则不干
  begin    //判断输入长度。
   LastLength:=Length(Text);
   tmp:=TMZKeyboard.GetText;
   if Tmp <> '' then
   begin
     //获取光标左边的字符
     CurL:=Copy(Text,0,CursorPos);
     //获取光标右边的字符
     CurR:=Copy(Text,CursorPos+1,LastLength);

     tmp:=Curl+tmp+CurR;
   //如果架上原有的字符串 并不会超过最大字符数量,则
   if not (Length(tmp)> MaxLength) then
   begin
   //计算这一次一共输入了几个字符
   Text:=tmp;
   IncLength:=Length(Text)-LastLength;
   //给当前光标添加输入长度个字符的位置
   Inc(CursorPos,IncLength);

   end;
   end;
   if CursorPos < 0 then CursorPos:=0;
   if CursorPos > Length(Text) then CursorPos:=Length(Text);
   TMZKeyboard.EndReadText;
   TMZKeyboard.BeginReadText();
  end;

end;
end.

