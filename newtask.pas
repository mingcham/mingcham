unit newtask;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ComCtrls, ImgList, ExtCtrls, CoreString, jpeg;

type
    TTaskNew = class(TForm)
        mStatus: TStatusBar;
        SiteSelectPage: TPageControl;
        TabSheet1: TTabSheet;
        UserDefineSite: TTabSheet;
        ListView1: TListView;
        ServerList: TListBox;
        StartSearch: TBitBtn;
        ExitWinzard: TBitBtn;
        Image1: TImage;
        procedure StartSearchClick(Sender: TObject);
        procedure ExitWinzardClick(Sender: TObject);
        procedure CallNewTask(GroupID: integer);
        procedure UserDefineSiteShow(Sender: TObject);
        procedure FormCreate(Sender: TObject);
        procedure TabSheet1Show(Sender: TObject);
    private
        { Private declarations }
    public
        function DuiQi(BianHao: integer): string;
        function GetSiteID(SiteListItem: string): string;
        function freshcheck(): integer;
    end;

var
    TaskNew         : TTaskNew;
    GroupSearch     : boolean;
implementation

uses main;

{$R *.dfm}

procedure TTaskNew.StartSearchClick(Sender: TObject);
var q               : integer;
begin
    if GroupSearch then
    begin
        for q := 0 to ListView1.Items.Count - 1 do
        begin
            if ListView1.Items[q].Selected and
                (StringToIntDef(ListView1.Items[q].SubItems[0], -1) >= 0) then
                CallNewTask(StringToIntDef(ListView1.Items[q].SubItems[0], -1));
        end;
    end else begin
        for q := 0 to ServerList.Items.Count - 1 do
        begin
            if ServerList.Selected[q] then
            begin
                if (GetSiteID(ServerList.Items[q]) <> '0') and
                    (WaitSiteList.IndexOf(GetSiteID(ServerList.Items[q])) < 0)
                    then
                    WaitSiteList.Add(GetSiteID(ServerList.Items[q]));
            end;
        end;
        if WaitSiteList.Count > 0 then
            case
                Application.MessageBox(PChar(Format('准备搜索 %d 个网站,立即开始吗?',
                [WaitSiteList.Count])), PChar('选择搜索'),
                MB_ICONQUESTION or MB_YESNO) of
                IDYES: begin
                        CallNewTask(13);
                        close;
                    end;
                IDNO: ;
            end;
    end;
end;

procedure TTaskNew.ExitWinzardClick(Sender: TObject);
begin
    close;
end;

procedure TTaskNew.CallNewTask(GroupID: integer);
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    if (GroupID < 13) and (GroupID >= 0) then
    begin
        case
            Application.MessageBox(PChar(Format('现在开始搜索第 %d 组网站,立即开始吗?', [GroupID])), PChar('分组搜索'),
            MB_ICONQUESTION or MB_YESNO) of
            IDYES: begin
                    CurrentSiteID := -1;
                    CurrentGroupID := GroupID;
                    somain.FlashTrigger.Enabled := true;
                    somain.ShowRunning;
                    close;
                end;
            IDNO: ;
        end;
    end else begin
        if WaitSiteList.Count < 1 then
            CurrentSiteID := -1;
        CurrentGroupID := 13;
        somain.FlashTrigger.Enabled := true;
        //-----------------------------------------------------------
        // 这里将首先判断 WaitSiteList是否为空
        //-----------------------------------------------------------
        somain.ShowRunning;
        close;
    end;
    SoStartTime := Now;
    AllSearched := 0;
end;

function TTaskNew.DuiQi(BianHao: integer): string;
var tmpStr          : string;
begin
    if BianHao > 0 then
    begin
        if BianHao < 10 then
            tmpStr := Format('   %d', [BianHao])
        else if BianHao < 100 then
            tmpStr := Format('  %d', [BianHao])
        else if BianHao < 1000 then
            tmpStr := Format(' %d', [BianHao])
        else
            tmpStr := IntToStr(BianHao);
    end else
        tmpStr := '    ';
    result := tmpStr;
end;

function TTaskNew.GetSiteID(SiteListItem: string): string;
var rlt             : string;
begin
    result := '0';
    if pos(':', SiteListItem) > 0 then
    begin
        rlt := Trim(Copy(SiteListItem, 0, pos(':', SiteListItem) - 1));
        if (StringToIntDef(rlt, -1) > 0) and (rlt <> '') then
            result := rlt;
    end;
end;

procedure TTaskNew.UserDefineSiteShow(Sender: TObject);
var siteid, i       : integer;
    siteurl         : string;
begin
    // 显示所有站点供用户选择
    GroupSearch := false;
    Screen.Cursor := crSQLWait;
    ServerList.Clear;

    with somain do
    begin
        if (SiteListView.Items.Count <= 0) then
        begin
            somain.ShowRunning(False);
            SitePerPageChange(Sender);
        end;

        for i := 0 to SiteListView.Items.Count - 1 do
        begin
            siteid := StringToIntDef(SiteListView.Items[i].Caption, 0);
            siteurl := SiteListView.Items[i].SubItems[0];

            if (siteurl <> '') then
            begin
                ServerList.Items.Add(Format('%s: 网址 %s', [DuiQi(siteid),
                    siteurl]));
            end;
        end;
    end;

    freshcheck;
    Screen.Cursor := crDefault;
end;

procedure TTaskNew.FormCreate(Sender: TObject);
begin
    GroupSearch := true;
end;

procedure TTaskNew.TabSheet1Show(Sender: TObject);
begin
    GroupSearch := true;
end;

function TTaskNew.freshcheck: integer;
var i, rlt          : integer;
begin
    rlt := 0;
    ServerList.ClearSelection;
    if WaitSiteList.Count > 0 then
    begin
        for i := 0 to ServerList.Count - 1 do
        begin
            if WaitSiteList.IndexOf(GetSiteID(ServerList.Items[i])) >= 0 then
            begin
                ServerList.Selected[i] := true;
                inc(rlt);
            end;
        end;
        result := rlt;
    end else
        result := 0;
end;

end.
