unit config;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, ComCtrls, StdCtrls, Buttons, IniFiles, ExtCtrls,
    ImgList, ADODB, jpeg, CoreString, Spin;

type
    TConfigWeb = class(TForm)
        configpallete: TPageControl;
        setting: TTabSheet;
        essagemod: TTabSheet;
        UinverseConfig: TTabSheet;
        DBGroupBox: TGroupBox;
        GlobalGroupBox: TGroupBox;
        SearchTypeLabel: TLabel;
        DiscardTmp: TRadioButton;
        KeepTmp: TRadioButton;
        spideragent: TComboBox;
        UAlabel: TLabel;
        GroupBox5: TGroupBox;
        CshowFindLink: TCheckBox;
        Cfreshui: TCheckBox;
        OutputSystemDebug: TCheckBox;
        GroupBox6: TGroupBox;
        GroupBox7: TGroupBox;
        IgnoreEmbedJs: TCheckBox;
        GroupBox8: TGroupBox;
        Label15: TLabel;
        Label16: TLabel;
        Label17: TLabel;
        OpenDialog1: TOpenDialog;
        Label2: TLabel;
        DefaultRecordPageNum: TLabel;
        MaxIndexPage: TEdit;
        AllowErrorNumLabel: TLabel;
        DefaultErrorMax: TEdit;
        CheckBadWord: TCheckBox;
        SkipBadPage: TCheckBox;
        UseComplexAlgr: TCheckBox;
        SiteAllOpen: TCheckBox;
        Image1: TImage;
        ApplyConfig: TBitBtn;
        discard: TBitBtn;
        UrlLenMax: TSpinEdit;
        PageProcessMax: TSpinEdit;
        ClipBufferMax: TSpinEdit;
        PageMaxLen: TSpinEdit;
        SiteInnerOpen: TCheckBox;
        StaticText1: TStaticText;
        SubDomainDeepth: TSpinEdit;
        SubDomainDeepth_Ticket: TLabel;
        PageMaxLen_Ticket: TLabel;
        ClipBufferMax_Ticket: TLabel;
        PageProcessMax_Ticket: TLabel;
        UrlLenMax_Ticket: TLabel;
        DeepthLabel: TLabel;
        NeedNoCount: TCheckBox;
        ConfigConnCmd: TButton;
        procedure ApplyConfigClick(Sender: TObject);
        procedure discardClick(Sender: TObject);
        procedure MaxIndexPageKeyPress(Sender: TObject; var Key: Char);
        procedure SiteAllOpenClick(Sender: TObject);
        procedure SkipBadPageClick(Sender: TObject);
        procedure FormResize(Sender: TObject);
        procedure ConfigConnCmdClick(Sender: TObject);
        procedure OutputSystemDebugClick(Sender: TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    ConfigWeb       : TConfigWeb;
    NewConStr       : string;

implementation

uses main;

{$R *.dfm}

procedure TConfigWeb.ApplyConfigClick(Sender: TObject);
var
    Config          : TIniFile;
begin
    if (not FileExists(GetDBFileFromConnStr(GlobalDataBase))) and
        (NCPos('Microsoft.Jet.OLEDB.4.0', GlobalDataBase) > 0) then
    begin
        //如果填写的数据库地址不正确
        if OpenDialog1.Execute then
        begin
            GlobalDataBase := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=' +
                OpenDialog1.FileName + ';Persist Security Info=False';
        end;
    end;

    //-------------------------------------------------------------------------
    // 将新的设置写入配置文件
    //-------------------------------------------------------------------------
    Config := TIniFile.Create(config_file);
    Config.WriteString('UindexWeb', 'MaxIndexPage', MaxIndexPage.Text);
    Config.WriteString('UindexWeb', 'ClipBufferMax', ClipBufferMax.Text);
    Config.WriteBool('UindexWeb', 'SiteAllOpen', SiteAllOpen.Checked);
    if NewConStr <> '' then
        Config.WriteString('UindexWeb', 'ConnStr', NewConStr)
    else
        Config.WriteString('UindexWeb', 'ConnStr', GlobalDataBase);
    Config.WriteString('UindexWeb', 'SpiderNum', IntToStr(ThreadNum));
    Config.WriteString('UindexWeb', 'spideragent', spideragent.Text);
    Config.WriteString('UindexWeb', 'DefaultErrorMax', DefaultErrorMax.Text);
    Config.WriteString('UindexWeb', 'UrlLenMax', UrlLenMax.Text);
    Config.WriteString('UindexWeb', 'PageProcessMax', PageProcessMax.Text);
    Config.WriteString('UindexWeb', 'PageMaxLen', PageMaxLen.Text);
    //-------------------------------------------------------------------------
    //  布尔型变量写入
    //-------------------------------------------------------------------------
    Config.WriteBool('UindexWeb', 'shutdownwhencomplete',
        somain.m_autoshutdown.Checked);
    Config.WriteBool('UindexWeb', 'LimitCPURate', somain.LimitCPURate.Checked);
    Config.WriteBool('UindexWeb', 'AutoClearMessage',
        somain.AutoClearMessage.Checked);
    Config.WriteBool('UindexWeb', 'SiteInnerOpen', SiteInnerOpen.Checked);
    Config.WriteBool('UindexWeb', 'KeepTemp', KeepTmp.Checked);
    Config.WriteBool('UindexWeb', 'DiscardTmp', DiscardTmp.Checked);
    Config.WriteInteger('UindexWeb', 'SubDomainDeepth', SubDomainDeepth.Value);
    Config.WriteBool('UindexWeb', 'IgnoreEmbedJs', IgnoreEmbedJs.Checked);
    Config.WriteBool('UindexWeb', 'Cfreshui', Cfreshui.Checked);
    Config.WriteBool('UindexWeb', 'CshowFindLink', CshowFindLink.Checked);
    Config.WriteBool('UindexWeb', 'OutputSystemDebug',
        OutputSystemDebug.Checked);
    Config.WriteBool('UindexWeb', 'CheckBadWord', CheckBadWord.Checked);
    Config.WriteBool('UindexWeb', 'UseComplexAlgr', UseComplexAlgr.Checked);
    Config.WriteBool('UindexWeb', 'SkipBadPage', SkipBadPage.Checked);
    Config.WriteBool('UindexWeb', 'NeedNoCount', NeedNoCount.Checked);
    //写入完成,保存配置文件
    Config.UpdateFile;
    Config.Free;
    Application.MessageBox(PChar('系统参数修改完成并保存在配置文件中.'),
        PChar('设置完成'), MB_ICONINFORMATION or MB_OK);
    close;
end;

procedure TConfigWeb.discardClick(Sender: TObject);
begin
    close;
end;

procedure TConfigWeb.MaxIndexPageKeyPress(Sender: TObject;
    var Key: Char);
begin
    if not (Key in ['0'..'9', #8]) then
    begin
        Key := #0;
        beep();
    end;
end;

procedure TConfigWeb.SiteAllOpenClick(Sender: TObject);
begin
    SiteInnerOpen.Enabled := not SiteAllOpen.Checked;
end;

procedure TConfigWeb.SkipBadPageClick(Sender: TObject);
begin
    CheckBadWord.Enabled := not SkipBadPage.Checked;
end;

procedure TConfigWeb.FormResize(Sender: TObject);
begin
    StaticText1.Width := Self.ClientWidth;
    StaticText1.Left := 0;
    StaticText1.Height := 2;

    configpallete.Width := Self.ClientWidth;
end;

procedure TConfigWeb.ConfigConnCmdClick(Sender: TObject);
begin
    //-------------------------------------------------------------------------
    //  用户修改连接参数
    //-------------------------------------------------------------------------
    NewConStr := PromptDataSource(handle, GlobalDataBase);
    if (NewConStr <> GlobalDataBase) then
    begin
        Application.MessageBox(PChar('新的数据库连接参数: ' + #13 + NewConStr),
            PChar('参数改变'), MB_ICONINFORMATION or MB_OK);
        GlobalDataBase := NewConStr;
    end;
end;

procedure TConfigWeb.OutputSystemDebugClick(Sender: TObject);
begin
    OutPutDebug := OutputSystemDebug.Checked;
end;

end.
