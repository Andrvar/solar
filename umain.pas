unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  OpenGLContext, GL, GLU, GLUT, FGL;

type

  { TfMain }

  TfMain = class(TForm)
    cbSpeed: TCheckBox;
    OpenGLControl: TOpenGLControl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OpenGLControlPaint(Sender: TObject);
    procedure IdleFunc(Sender: TObject; var Done: Boolean);
  private

  public

  end;

var
  fMain: TfMain;
  timer: integer;
  lo: TStringList;

implementation

{$R *.lfm}

{ TfMain }
type
  TArr = array of GLfloat;

  TBody = class
    x: GLfloat; // это "поле"
    y: GLfloat;
    r: GLfloat;
    m: GLfloat;
    vx: GLfloat;
    vy: GLfloat;
   // property MyIntProperty: Integer read MyInt write MyInt; 
    procedure Solve(var x1: TArr; var y1: TArr; var m1: TArr; var r1: TArr); 
  end;

  TBodyList = specialize TFPGObjectList<TBody>;   // коллекция объектов

var
  List: TBodyList;
  B: TBody;
  xa, ya, ma, ra: TArr;
  bt: array of array[1..6] of GLfloat;


procedure TBody.Solve(var x1: TArr; var y1: TArr; var m1: TArr; var r1: TArr);
var
  fx, fy: GLfloat;
  fxi, fyi: GLfloat;
  xx, yy: GLfloat;
  f: GLfloat;
  i: integer;

begin

  //fx = f/sqrt(1+sqr(y/x))
  //fy = sqrt(sqr(f) - sqr(fx))

  fxi := 0;
  fyi := 0;

  for i := 0 to length(x1) - 1 do
    if (b.x <> x1[i]) and (b.y <> y1[i]) then
    begin

      xx := x1[i] - b.x;
      yy := y1[i] - b.y;
      f := 6.67e-11 * b.m * m1[i]/(sqr(xx) + sqr(yy));

      fx := f / sqrt(1 + sqr(yy/xx));
      fy := sqrt(sqr(f) - sqr(fx));

      if xx < 0 then fx := -fx;
      if yy < 0 then fy := -fy;

      fxi := fxi + fx;
      fyi := fyi + fy;

    end;

  vx := vx + fxi/b.m;
  vy := vy + fyi/b.m;

  b.x := b.x + b.vx;
  b.y := b.y + b.vy;

end;

procedure myCircle(x, y, r: real);
var
  i: integer;
  a: real;

begin
  glBegin( GL_TRIANGLE_FAN );
    glColor3f( 1.0, 1.0, 0.0);
    glVertex2f( x, y ); // вершина в центре круга
    for i := 0 to 40 do
    begin
      a := i / 40.0 * pi * 2.0;
      glVertex2f( cos( a ) * r + x, sin( a ) * r + y );
    end;
  glEnd();
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  i, j, n: integer;
  s: string;

begin

  lo := TStringList.Create;

  // парсим текстовик с объектами
  try

    lo.LoadFromFile('body.txt');
    DecimalSeparator := '.';
    i := 0;
    j := 0;
    for s in lo do
    begin
      if pos('#', s)>0 then
      begin
        j := 0;
        i := i + 1;
        SetLength(bt, i);
        continue;
      end;
      j := j + 1;
      bt[i-1][j] := StrToFloat(copy(s, pos('=', s) + 1));
    end;

  except
    ShowMessage('Ошибка при загрузке файла body.txt');
    Application.Terminate;
  end;

  timer := 0;
  n := i; // количество тел

  List := TBodyList.Create(true);

  for i := 0 to n - 1 do
  begin
    b := TBody.Create;
    List.Add(b);

    List.Items[i].x  := bt[i][1];
    List.Items[i].y  := bt[i][2];
    List.Items[i].vx := bt[i][3];
    List.Items[i].vy := bt[i][4];
    List.Items[i].r  := bt[i][5];
    List.Items[i].m  := bt[i][6];
  end;

  SetLength(xa, n);
  SetLength(ya, n);
  SetLength(ma, n);
  SetLength(ra, n);

  i := 0;
  for b in List do
  begin
    xa[i] := b.x;
    ya[i] := b.y;
    ma[i] := b.m;
    ra[i] := b.r;
    i := i + 1;
  end;

  Application.OnIdle := @IdleFunc;

end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  SetLength(xa, 0);
  SetLength(ya, 0);
  SetLength(ma, 0);
  SetLength(ra, 0);
  FreeAndNil(List);
  FreeAndNil(lo);
  SetLength(bt, 0);
end;

procedure TfMain.OpenGLControlPaint(Sender: TObject);

begin

  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  for b in List do myCircle(b.x, b.y, b.r);

  OpenGLControl.SwapBuffers;

  fMain.Caption := IntToStr(timer);

end;

procedure TfMain.IdleFunc(Sender: TObject; var Done: Boolean);
var
  i: integer;

begin

  timer := timer + 1;

  i := 0;
  for b in List do
  begin

    xa[i] := b.x;
    ya[i] := b.y;
    ma[i] := b.m;
    ra[i] := b.r;
    i := i + 1;

  end;

  for b in List do
  begin
    b.Solve(xa, ya, ma, ra);
  end;

  if not cbSpeed.Checked then sleep(10);

  OpenGLControl.Invalidate;

end;

end.

