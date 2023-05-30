unit BugReport;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, CoreString, Buttons;

type
    TReportBug = class(TForm)
        SaySorry: TGroupBox;
        SorryMessage: TStaticText;
        BugContents: TMemo;
        CopyReport: TBitBtn;
        procedure CopyReportClick(Sender: TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    ReportBug       : TReportBug;

implementation

uses main;

{$R *.dfm}

procedure TReportBug.CopyReportClick(Sender: TObject);
begin
    BugContents.SelectAll;
    BugContents.CopyToClipboard;

    Application.MessageBox(PChar('错误报告和配置信息已复制到剪贴板！'),
        PChar('复制完成'), MB_ICONINFORMATION or MB_OK);

    somain.m_homepageClick(Sender);
end;

end.
