﻿unit Demo;

{$INCLUDE '../../src/mz_config.cfg'}

interface

procedure RunDemo;

implementation

uses
  SysUtils,
  { You don't necessarily have to use these units. However, Delphi will not
    inline some methods if these units are not in the uses clause. }
  {$IFNDEF FPC}
  {$IFDEF USE_ZENGL_STATIC}
  zgl_textures,
  zgl_render_target,
  zgl_sprite_2d,
  zgl_utils,
  zgl_text,
  zgl_font,
  zgl_keyboard,
  zgl_main,
  {$ELSE}
  zglHeader,
  {$ENDIF}
  {$ENDIF}
  MondoZenGL;


const
  {$IFDEF DARWIN}
  RESOURCE_DIRECTORY = '';
  {$ELSE}
  RESOURCE_DIRECTORY = '../data/';
  {$ENDIF}

type
  TDemoScene = class(TMZScene)
  private
    FFont: TMZFont;
    FTextureTux: TMZTexture;
    FRenderTarget: TMZRenderTarget;
    FAngle: Single;
  protected
    { Summary:
        Is called before the scene is executed. You can override this method
        to initialize scene specific resources. }
    procedure Startup; override;

    { Summary:
        Is called just before the scene is terminated. You can override this
        method to cleanup scene specific resources. }
    procedure Shutdown; override;

    { Summary:
        Is called during each iteration of the main loop to render the current
        frame. }
    procedure RenderFrame; override;

    { Summary:
        Is called during each iteration of the main loop to update the game
        state. The DeltaTimeMs is the number of milliseconds (1/1000th of a
        second) that has passed since the last call to Update.
      Parameters:
        DeltaTimeMs: the number of milliseconds that has passed since the last
        call to Update. }
    procedure Update(const DeltaTimeMs: Double); override;
  end;

procedure RunDemo;
var
  Application: TMZApplication;
begin
  Randomize;
  Application := TMZApplication.Create;
  Application.Options := Application.Options + [aoShowCursor] - [aoAllowPortraitOrientation]-[aoFullScreen];
  Application.Caption := '09 - Render to Texture';
  Application.ScreenWidth := 800;
  Application.ScreenHeight := 600;
  Application.SetScene(TDemoScene.Create);
  { The application and scene will automatically be freed on shutdown }
end;

{ TDemoScene }

procedure TDemoScene.Startup;
begin
  inherited Startup;
  Randomize;
  FTextureTux := TMZTexture.Create(RESOURCE_DIRECTORY + 'tux_stand.png');
  FTextureTux.SetFrameSize(64, 64);
  FFont := TMZFont.Create(RESOURCE_DIRECTORY + 'font.zfi' );

  // RU: Создаем RenderTarget и "цепляем" пустую текстуру. В процессе текстуру можно сменить присвоив
  // rtarget.Surface другую zglPTexture, главное что бы совпадали размеры с теми, что указаны в
  // tex_CreateZero. Таргету также указан флаг RT_FULL_SCREEN, отвечающий за то, что бы в текстуру
  // помещалось все содержимое экрана а не область 512x512(как с флагом RT_DEFAULT).
  //
  // EN: Create a RenderTarget and "bind" empty texture to it. Later texture can be changed by changing
  // rtarget.Surface to another zglPTexture, the only requirement - the same size of textures, that was
  // set in tex_CreateZero. Also target use flag RT_FULL_SCREEN that responsible for rendering whole
  // content of screen to target, not only region 512x512(like with flag RT_DEFAULT).
  FRenderTarget := TMZRenderTarget.Create(TMZTexture.Create(512, 512),
    [rtOwnsTexture]);
end;

procedure TDemoScene.Shutdown;
begin
  FRenderTarget.Free;
  FFont.Free;
  FTextureTux.Free;
  inherited Shutdown;
end;

procedure TDemoScene.RenderFrame;
begin
  inherited RenderFrame;

  // RU: Устанавливаем текущий RenderTarget.
  // EN: Set current RenderTarget.
  Canvas.RenderTarget := FRenderTarget;

  // RU: Рисуем в него
  // EN: Render to it.
  Canvas.DrawSpriteFrame(FTextureTux, Random(9) + 1, Random(1024 - 64),
    Random(768 - 64), 64, 64);

  // RU: Возвращаемся к обычному рендеру.
  // EN: Return to default rendering.
  Canvas.RenderTarget := nil;

  // RU: Теперь рисуем содержимое RenderTarget'а.
  // EN: Render content of RenderTarget.
  Canvas.DrawSprite(FRenderTarget.Texture, (1024 - 512) / 2, (768 - 512) / 2,
    512, 512, FAngle);

  Canvas.DrawText(FFont, 0, 0, 'FPS: ' + TMZUtils.IntToStr(Application.CurrentRenderFrameRate));
end;

procedure TDemoScene.Update(const DeltaTimeMs: Double);
begin
  inherited Update(DeltaTimeMs);

  { Rotate render target 360 degrees in 10 seconds }
  FAngle := FAngle + (DeltaTimeMs * (360 / 10000));

  if TMZKeyboard.IsKeyPressed(kcEscape) then
    Application.Quit;
  TMZKeyboard.ClearState;
end;

end.
