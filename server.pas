unit server;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, StrUtils, CoreString, jpeg,
    Spin;

type
    TWebSite = class(TForm)
        Celue: TPageControl;
        BaseInfo: TTabSheet;
        GroupBox2: TGroupBox;
        Label1: TLabel;
        TabSheet2: TTabSheet;
        GroupBox5: TGroupBox;
        GroupBox6: TGroupBox;
        Label16: TLabel;
        ForbidenPreFix: TMemo;
        Label17: TLabel;
        ContentCheckPage: TTabSheet;
        GroupBox7: TGroupBox;
        Label19: TLabel;
        GroupBox8: TGroupBox;
        ThisForbidenWord: TMemo;
        Label22: TLabel;
        Image1: TImage;
        HelpInfo: TBitBtn;
        SaveInfo: TBitBtn;
        DiscardSave: TBitBtn;
        SiteID: TLabel;
        MaxIndexPage: TSpinEdit;
        AntiDuplicate: TSpinEdit;
        server: TEdit;
        EntryPoint: TEdit;
        SiteGroup: TSpinEdit;
        server_Ticket: TLabel;
        MaxIndexPage_Ticket: TLabel;
        AntiDuplicate_Ticket: TLabel;
        EntryPoint_Ticket: TLabel;
        SiteGroup_Ticket: TLabel;
        procedure DiscardSaveClick(Sender: TObject);
        function DivSiteUrl(): boolean;
        procedure SaveInfoClick(Sender: TObject);
        procedure SiteIDKeyPress(Sender: TObject; var Key: Char);
        procedure HelpInfoClick(Sender: TObject);
        procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    private
        { Private declarations }
    public
        procedure FreshUI();
        function ZhengLiForbiden(list: string): string;
    end;

var
    WebSite         : TWebSite;

implementation

uses main;

{$R *.dfm}

procedure TWebSite.DiscardSaveClick(Sender: TObject);
begin
    close;
end;

procedure TWebSite.FreshUI;
begin
    Server.Font.Color := clWindowtext;
    EntryPoint.Font.Color := clWindowtext;
    SiteID.Caption := Trim(SiteID.Caption);
    if StringToIntDef(SiteID.Caption, -1) > 0 then
    begin
        SemaphoreAcquire(DBtoken);
        adolink.Close;
        adolink.SQL.Clear;
        adolink.SQL.Add('Select SEId,SERoot,SEEntryPoint,SEGroup,SEMaxpage,SEForbiden,SEClipmax,SEBadwords From UindexWeb_Entry Where SEId=' + trim(SiteID.Caption));
        adolink.Open;
        if not adolink.Eof then
        begin
            if IsValidVarString(adolink.Recordset.Fields[1].Value) then
                Server.Text := adolink.Recordset.Fields[1].Value
            else
                Server.Text := '';
            if IsValidVarString(adolink.Recordset.Fields[2].Value) then
                EntryPoint.Text := adolink.Recordset.Fields[2].Value
            else
                EntryPoint.Text := '';
            if VarIsOrdinal(adolink.Recordset.Fields[3].Value) then
            begin
                SiteGroup.Value := adolink.Recordset.Fields[3].Value;
            end else
                SiteGroup.Value := 0;
            if VarIsOrdinal(adolink.Recordset.Fields[4].Value) then
                MaxIndexPage.Value := adolink.Recordset.Fields[4].Value
            else
                MaxIndexPage.Value := 0;
            if IsValidVarString(adolink.Recordset.Fields[5].Value) then
                ForbidenPreFix.Text :=
                    ZhengLiForbiden(adolink.Recordset.Fields[5].Value)
            else
                ForbidenPreFix.Text := '';
            if VarIsOrdinal(adolink.Recordset.Fields[6].Value) then
                AntiDuplicate.Value := adolink.Recordset.Fields[6].Value
            else
                AntiDuplicate.Value := 0;
            if IsValidVarString(adolink.Recordset.Fields[7].Value) then
                ThisForbidenWord.Text :=
                    ZhengLiForbiden(adolink.Recordset.Fields[7].Value)
            else
                ThisForbidenWord.Text := '';
        end;
        adolink.SQL.Clear;
        adolink.Close;
        SemaphoreRelease(DBtoken);
    end else begin
        Server.Text := ' ';
        EntryPoint.Text := ' ';

        SiteGroup.Value := 0;
        ForbidenPreFix.Text := ' ';
        MaxIndexPage.Value := 0;
        AntiDuplicate.Value := 0;
        ThisForbidenWord.Text := ' ';
    end;
end;

procedure TWebSite.SaveInfoClick(Sender: TObject);
begin
    if not DivSiteUrl() then exit;
    server.Text := trim(server.Text);
    EntryPoint.Text := trim(EntryPoint.Text);

    //-------------------------------------------------------------------------
    //  输入单元当填写不完整时的默认值.
    //-------------------------------------------------------------------------
    ThisForbidenWord.Text := ZhengLiForbiden(ThisForbidenWord.Text);
    ForbidenPreFix.Text := ZhengLiForbiden(ForbidenPreFix.Text);
    {为输入单元设置默认值}
    if StringToIntDef(SiteID.Caption, -1) > 0 then
    begin
        //-------------------------------------------------------------------------
        // 更新站点资料
        //-------------------------------------------------------------------------
        SemaphoreAcquire(DBtoken);
        try
            with adolink do
            begin
                Close;
                SQL.Clear;
                SQL.Add('update UindexWeb_Entry set SERoot=:a,SEEntryPoint=:b,SEGroup=:c,SEMaxpage=:d,SEForbiden=:e,SEClipmax=:f,SEBadwords=:g where SEId=' + SiteID.Caption);
                Parameters.ParamByName('a').Value := SqlFitness(Server.Text);
                Parameters.ParamByName('b').Value :=
                    SqlFitness(EntryPoint.Text);
                Parameters.ParamByName('c').Value := SiteGroup.Value;
                Parameters.ParamByName('d').Value := MaxIndexPage.Value;
                Parameters.ParamByName('e').Value :=
                    SqlFitness(ForbidenPreFix.Text);
                Parameters.ParamByName('f').Value := AntiDuplicate.Value;
                Parameters.ParamByName('g').Value :=
                    SqlFitness(ThisForbidenWord.Text);

                ExecSQL;
                Close;
            end;

            SemaphoreRelease(DBtoken);
            Application.MessageBox(PChar('修改网站 ' + server.Text +
                ' 资料完成.'), PChar('修改完成'), MB_ICONINFORMATION or MB_OK);
            close;
        except
            on E: Exception do
            begin
                SemaphoreRelease(DBtoken);
                Application.MessageBox(PChar('修改网站 ' + server.Text +
                    ' 资料时出现错误:' + #13 + #13 + '可能是网站地址重复!' + #13
                    +
                    e.Message), PChar('修改出错'), MB_ICONERROR or MB_OK);
            end;
        end;
    end else begin
        //-------------------------------------------------------------------------
        // 添加
        //-------------------------------------------------------------------------
        SemaphoreAcquire(DBtoken);
        try
            with adolink do
            begin
                Close;
                SQL.Clear;
                SQL.Add('Insert into UindexWeb_Entry(SERoot,SEEntryPoint,SEGroup,SEMaxpage,SEForbiden,SEClipmax,SEBadwords) values(:a,:b,:c,:d,:e,:f,:g)');
                Parameters.ParamByName('a').Value := SqlFitness(Server.Text);
                Parameters.ParamByName('b').Value :=
                    SqlFitness(EntryPoint.Text);
                Parameters.ParamByName('c').Value := SiteGroup.Value;
                Parameters.ParamByName('d').Value := MaxIndexPage.Value;
                Parameters.ParamByName('e').Value :=
                    SqlFitness(ForbidenPreFix.Text);
                Parameters.ParamByName('f').Value := AntiDuplicate.Value;
                Parameters.ParamByName('g').Value :=
                    SqlFitness(ThisForbidenWord.Text);

                ExecSQL;
                Close;
            end;

            SemaphoreRelease(DBtoken);
            Application.MessageBox(PChar('添加网站 ' + server.Text + ' 完成.'),
                PChar('成功添加'), MB_ICONINFORMATION or MB_OK);
            close;
        except
            on E: Exception do
            begin
                SemaphoreRelease(DBtoken);
                Application.MessageBox(PChar('添加网站 ' + server.Text +
                    ' 时出现错误:' + #13 + #13 + '可能网站已经存在!' + #13 +
                    e.Message), PChar('添加出错'), MB_ICONERROR or MB_OK);
            end;
        end;
    end;
end;

procedure TWebSite.SiteIDKeyPress(Sender: TObject; var Key: Char);
begin
    if not (Key in ['0'..'9', #8]) then
    begin
        Key := #0;
        beep();
    end;
end;

function TWebSite.DivSiteUrl(): boolean;
var RootA, RootB    : string;
begin
    //-------------------------------------------------------------------------
    //检查一下地址
    //-------------------------------------------------------------------------
    result := true;
    if (Trim(server.Text) = '') then
    begin
        server.Text := '';
        server.Font.Color := clred;
        result := false;
        exit;
    end else
        server.Font.Color := clWindowText;
    if (Trim(EntryPoint.Text) = '') then
    begin
        EntryPoint.Text := '';
        EntryPoint.Font.Color := clred;
        result := false;
        exit;
    end else
        EntryPoint.Font.Color := clWindowText;
    if (not IsHttpURL(trim(EntryPoint.Text))) then
    begin
        EntryPoint.Font.Color := clred;
        result := false;
        exit;
    end else
        EntryPoint.Font.Color := clWindowText;
    if pos('://', Trim(server.Text)) > 0 then
        server.Text := copy(server.Text, pos('://', server.Text) + 3,
            length(server.Text));
    if (Trim(server.Text) = '') then
    begin
        server.Text := '';
        server.Font.Color := clred;
        result := false;
        exit;
    end else
        server.Font.Color := clWindowText;

    RootA := LowAndTrim(GetDomainRoot(server.Text));
    RootB := LowAndTrim(GetDomainRoot(EntryPoint.Text));
    server.Text := RootA;

    if (RootA = '') or (NCPos(RootA, RootB) <= 0) then
    begin
        Application.MessageBox(PChar('地址不完整,入口必须包含根域:' + #13 + #13
            + '当前根域: "' + server.Text + '"' + #13 + '当前入口: "' +
            EntryPoint.Text + '"'), PChar('警告'), MB_ICONWARNING or MB_OK or
            MB_SYSTEMMODAL);
        result := false;
    end;
end;

function TWebSite.ZhengLiForbiden(list: string): string;
begin
    result := '';
    list := trim(list);
    if list <> '' then
    begin
        StringReplaceEx(list, #13 + #10 + #13 + #10, #13 + #10, [rfReplaceAll]);
        StringReplaceEx(list, #32 + #32, #32, [rfReplaceAll]);

        if list <> '' then
            result := list;
    end;
end;

procedure TWebSite.HelpInfoClick(Sender: TObject);
begin
    somain.m_contentClick(Sender);
end;

procedure TWebSite.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    Screen.Cursor := crHourGlass;
    somain.SiteListView.Clear;
    Screen.Cursor := crArrow;
end;

end.
