unit copyright;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, ComCtrls, StdCtrls, Buttons, ExtCtrls;

type
    TUindexcopyright = class(TForm)
        ExitBtn: TBitBtn;
        LogWindow: TMemo;
        LogoAndVersion: TPanel;
        LogoImage: TImage;
        Label3: TLabel;
        Label4: TLabel;
        Label5: TLabel;
        procedure Label5Click(Sender: TObject);
        procedure ExitBtnClick(Sender: TObject);
        procedure FormCreate(Sender: TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Uindexcopyright : TUindexcopyright;

implementation

uses main;

{$R *.dfm}

procedure TUindexcopyright.Label5Click(Sender: TObject);
begin
    somain.m_homepageClick(Sender);
end;

procedure TUindexcopyright.ExitBtnClick(Sender: TObject);
begin
    Self.close();
end;

procedure TUindexcopyright.FormCreate(Sender: TObject);
begin
    if FileExists('UindexWeb.txt') then
    begin
        LogWindow.Lines.LoadFromFile('UindexWeb.txt');
    end else begin
        LogWindow.Lines.Add('程序更新日志文件不存在。');
    end;

    LogoImage.Width := Application.Icon.Width;
    LogoImage.Height := Application.Icon.Height;
    LogoImage.Canvas.Draw(0, 0, Application.Icon);

    LogoAndVersion.Left := 0;
    LogoAndVersion.Width := Self.ClientWidth;

    LogWindow.Top := LogoAndVersion.Top + LogoAndVersion.Height;
    LogWindow.Left := 0;
    LogWindow.Width := Self.ClientWidth;
    LogWindow.Height := Self.ClientHeight - LogoAndVersion.Top -
        LogoAndVersion.Height - ExitBtn.Height - (ExitBtn.Height div 2);

    ExitBtn.Left := Self.ClientWidth - ExitBtn.Width - (ExitBtn.Height div 4);
    ExitBtn.Top := LogWindow.Top + LogWindow.Height + (ExitBtn.Height div 4);
end;

end.
