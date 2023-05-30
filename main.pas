unit main;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, ImgList, ExtCtrls, ComCtrls, Grids, SyncObjs, ComObj, ActiveX,
    Menus, StdCtrls, GetThread, DB, ADODB, IniFiles, StrUtils,
    Buttons, Registry, TopBuffer, CoreString, DateUtils,
    ToolWin, ShellAPI, JclDebug;

const HomePageUrl   : string = 'http://www.opencpu.com/';
const BbsPageUrl    : string = 'http://bbs.opencpu.com/';
const UpdatePageUrl : string = 'http://download.opencpu.com/';

const DOC_WEB       = 0;
const DOC_TEXT      = 1;
const DOC_BIN       = 2;
const DOC_IMAGE     = 3;
const DOC_MOVIE     = 4;
const DOC_OTHER     = 5;

const FlashTriggerMessage = WM_USER + 101;
const FlashUIMessage = WM_USER + 102;
const ModifyThreadNumMessage = WM_USER + 103;
const CountSecondMessage = WM_USER + 104;

var
    DBtoken         : THandle = 0;      //Database token
    URLtoken        : THandle = 0;      //URLs  token
    FILEtoken       : THandle = 0;      //FILEs token
    CLIPtoken       : THandle = 0;      //CLIPs token
    CSWtoken        : THandle = 0;      //CSWs  token
    adolink         : TADOQuery;        //这是唯一的数据库访问组件.
    GlobalDataBase  : string;           //adolink的连接字符串
    config_file     : string;
    WorkInOpenMode  : boolean;
    PageAccessError : integer;
    PageErrorPermit : integer;
    ThreadNum       : integer;
    MaxThreadNum    : integer;
    ThisSiteMaxPage : integer;
    ProofDuplicate  : integer;
    ThisHaveIndex   : integer;
    CurrentRoot     : string;
    CurrentSubRoot  : string;
    CopyRightStr    : string;
    SiteUrlStr      : string;
    ShortCopyRight  : string;
    SoftVersion     : string;
    CurrentSiteID   : integer;
    CurrentGroupID  : integer;
    binExtList      : TStringList;
    TextExtList     : TStringList;
    ImgExtList      : TStringList;
    MovieExtList    : TStringList;
    PreCSWList      : TStringList;

    SiteUrlList     : CTopCliper;
    EmbedFileList   : CTopCliper;
    ClipList        : CTopCliper;

    SpiderNameList  : TStringList;
    DomainExt       : TStringList;
    SystemBadWordList: TStringList;
    CurrentBadWordList: TStringList;
    SystemForbidenUrlList: TStringList;
    CurrentForbidenUrlList: TStringList;

    WaitSiteList    : TStringList;
    CSpilterList    : TstringList;
    SoStartTime     : TDateTime;
    AllSearched     : integer;
    //主窗口,Tsomain界面
type
    Tsomain = class(TForm)
        GlobalImageList: TImageList;
        MainToolBar: TToolBar;
        MainMenu1: TMainMenu;
        TopMenuSearchTask: TMenuItem;
        Tresume: TToolButton;
        mStatus: TStatusBar;
        logo: TImage;
        tpause: TToolButton;
        StartSearch: TToolButton;
        FlashTrigger: TTimer;
        m_StartSearch: TMenuItem;
        m_Resume: TMenuItem;
        m_pause: TMenuItem;
        N5: TMenuItem;
        SiteManagerMenu: TMenuItem;
        ExportSiteMenu: TMenuItem;
        m_addnew: TMenuItem;
        N9: TMenuItem;
        m_quitengine: TMenuItem;
        TopMenuConfigSearch: TMenuItem;
        Mhelp: TMenuItem;
        m_content: TMenuItem;
        N14: TMenuItem;
        m_homepage: TMenuItem;
        m_bbs: TMenuItem;
        m_faq: TMenuItem;
        N17: TMenuItem;
        m_author: TMenuItem;
        m_resetStatus: TMenuItem;
        m_clean: TMenuItem;
        m_config: TMenuItem;
        m_autoshutdown: TMenuItem;
        N28: TMenuItem;
        BtnSpr1: TToolButton;
        taddsite: TToolButton;
        tconfigspider: TToolButton;
        BtnSpr2: TToolButton;
        Tcontent: TToolButton;
        Tauthor: TToolButton;
        m_one: TMenuItem;
        m_two: TMenuItem;
        m_three: TMenuItem;
        m_four: TMenuItem;
        N51: TMenuItem;
        N52: TMenuItem;
        N71: TMenuItem;
        N81: TMenuItem;
        N91: TMenuItem;
        FlashUI: TTimer;
        N101: TMenuItem;
        SiteListPopup: TPopupMenu;
        popsearchselected: TMenuItem;
        GroupSearch: TMenuItem;
        N3: TMenuItem;
        popaddnew: TMenuItem;
        popeditsite: TMenuItem;
        N7: TMenuItem;
        setready: TMenuItem;
        setrunning: TMenuItem;
        setcomplete: TMenuItem;
        N12: TMenuItem;
        popdelsearch: TMenuItem;
        popdeltemp: TMenuItem;
        popdelsite: TMenuItem;
        N18: TMenuItem;
        N19: TMenuItem;
        popgroupsite: TMenuItem;
        ModifyThreadNum: TTimer;
        N1: TMenuItem;
        N2: TMenuItem;
        N4: TMenuItem;
        VIP1: TMenuItem;
        N6: TMenuItem;
        N8: TMenuItem;
        N10: TMenuItem;
        VIP2: TMenuItem;
        N11: TMenuItem;
        N13: TMenuItem;
        N15: TMenuItem;
        VIP3: TMenuItem;
        N16: TMenuItem;
        N21: TMenuItem;
        N22: TMenuItem;
        SiteManagerBtn: TToolButton;
        TopMenuMode: TMenuItem;
        N23: TMenuItem;
        N25: TMenuItem;
        N26: TMenuItem;
        AutoClearMessage: TMenuItem;
        N111: TMenuItem;
        N112: TMenuItem;
        N29: TMenuItem;
        IndexWeb: TMenuItem;
        N32: TMenuItem;
        TestSearch: TToolButton;
        BuffreProgressBar: TProgressBar;
        N31: TMenuItem;
        m_ExitEngine: TMenuItem;
        CountSecond: TTimer;
        LogOff: TMenuItem;
        PrintBadPage: TMenuItem;
        N34: TMenuItem;
        ImportSiteMenu: TMenuItem;
        IODialog: TOpenDialog;
        LimitCPURate: TMenuItem;
        WaitWindow: TGroupBox;
        WaitIcon: TImage;
        WaitProgress: TProgressBar;
        WaitMessage: TStaticText;
        TotalSiteInfo: TGroupBox;
        TotalSiteGroup: TGroupBox;
        TotalSiteLabel: TLabel;
        TotalSite: TEdit;
        CurrentSitePage_Ticket: TLabel;
        SitePerPage_Ticket: TLabel;
        SitePerPage: TComboBox;
        CurrentSitePage: TComboBox;
        SiteListView: TListView;
        SpiderTabs: TPageControl;
        StatusWin: TMemo;
        SpiderViewBtn: TBitBtn;
        TotalPageLabel: TLabel;
        TotalPageInDB: TEdit;
        procedure FormCreate(Sender: TObject);
        procedure QuitEngineClick(Sender: TObject);
        procedure FlashTriggerTimer(Sender: TObject);
        procedure StartSearchClick(Sender: TObject);
        procedure StatusPrintf(msg: string);
        procedure InsertSiteRoot(SiteID: integer);
        procedure SetThreadNum(ThreadCount: integer);
        procedure CompleteGroup(GroupID: integer);
        procedure m_oneClick(Sender: TObject);
        procedure m_ResumeClick(Sender: TObject);
        procedure m_pauseClick(Sender: TObject);
        procedure FormResize(Sender: TObject);
        procedure FlashUITimer(Sender: TObject);
        procedure m_authorClick(Sender: TObject);
        procedure m_homepageClick(Sender: TObject);
        procedure m_bbsClick(Sender: TObject);
        procedure m_faqClick(Sender: TObject);
        procedure m_contentClick(Sender: TObject);
        procedure m_resetStatusClick(Sender: TObject);
        procedure TprintClick(Sender: TObject);
        procedure m_addnewClick(Sender: TObject);
        procedure SiteManagerMenuClick(Sender: TObject);
        procedure m_configClick(Sender: TObject);
        procedure DrawSiteList();
        procedure setreadyClick(Sender: TObject);
        procedure setsitestatus(idstr: string; status: integer);
        procedure popsearchselectedClick(Sender: TObject);
        procedure GroupSearchClick(Sender: TObject);
        procedure ModifyThreadNumTimer(Sender: TObject);
        procedure popdelsearchClick(Sender: TObject);
        procedure popgroupsiteClick(Sender: TObject);
        procedure SiteListViewDblClick(Sender: TObject);
        procedure FormDestroy(Sender: TObject);
        procedure DiscardSite(siteid: integer);
        procedure IndexWebClick(Sender: TObject);
        procedure m_ExitEngineClick(Sender: TObject);
        procedure tautoshutdownClick(Sender: TObject);
        procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
        procedure CountSecondTimer(Sender: TObject);
        procedure PrintBadPageClick(Sender: TObject);
        procedure ImportSiteMenuClick(Sender: TObject);
        procedure UpdateAntiDuplicat();
        procedure UpdateTotalPageInDB();
        procedure ThreadComplete(Sender: TObject);
        procedure ExitApplication(action: boolean);
        procedure MenuResetClick(Sender: TObject);
        procedure LoadWordCheck();
        procedure m_cleanClick(Sender: TObject);
        procedure SiteListViewKeyDown(Sender: TObject; var Key: Word;
            Shift: TShiftState);
        procedure SitePerPageChange(Sender: TObject);
        procedure CurrentSitePageChange(Sender: TObject);
        procedure FormPaint(Sender: TObject);
        function GetXmlKey(XmlLine, Key: string): string;
        function GetNextUrl(SpiderId: integer): string;
        function GetNextSite(GroupId: integer): string;
        function WorkingSpider(): integer;
        function IsSpiderRunning(): boolean;
    private
        procedure ShutDownPc(logoff: boolean);
        procedure FlashTriggerProc(var Message: TMessage); message
            FlashTriggerMessage;
        procedure FlashUIProc(var Message: TMessage); message FlashUIMessage;
        procedure ModifyThreadNumProc(var Message: TMessage); message
            ModifyThreadNumMessage;
        procedure CountSecondProc(var Message: TMessage); message
            CountSecondMessage;
        procedure ShowModalWindow(Sender: TObject);
    public
        SpiderList: array of CSpider;
        PageUrlId: array of integer;
        PageSizeArray: array of integer;
        divx, divy: integer;
        PageHaveCreated: array of boolean;
        //----------------------------------------------------------------------------
        // 根据线程数，动态创建界面,下面是界面元素
        //----------------------------------------------------------------------------
        SpiderTab: array of TTabSheet;
        CurrentPage: array of TgroupBox;
        UrlHeader: array of Tlabel;
        SpiderUrl: array of TEdit;
        Inprocess: array of TcheckBox;
        HasProcessed: array of TcheckBox;
        StaticsInfo: array of TgroupBox;
        PageLen: array of tlabel;
        PageLenNum: array of tlabel;
        FindLink: array of tlabel;
        FindLinkNum: array of tlabel;
        FindTotalUrls: array of tlabel;
        FindTotalUrlNums: array of tlabel;
        FindEmbeds: array of tlabel;
        FindEmbedNums: array of tlabel;
        FindEvent: array of tlabel;
        FindEventNum: array of tlabel;
        ClipInfo: array of tlabel;
        ClipInfoNum: array of tlabel;

        OfDomain: array of tlabel;
        OfDomainStr: array of tlabel;
        MessagePanel: array of TgroupBox;
        ImportantMsg: array of tlabel;
        ImportantMsgStr: array of tedit;
        SplitInfo: array of tlabel;
        SplitInfobar: array of tprogressbar;
        ParseProgress: array of tlabel;
        ParseProgressBar: array of tprogressbar;
        WriteProgress: array of tlabel;
        WriteProgressBar: array of tprogressbar;
        SpentTime: array of tlabel;
        SpentTimeStr: array of tlabel;
        procedure ShellOpen(obj: string);
        function IsThreadRunning(const i: integer): boolean;
        procedure UindexWebException(Sender: TObject; E: Exception);
        procedure UindexWebThreadException(const MessageString: string);
        procedure ShowExceptionDialog();
        procedure ShowRunning(const Show: Boolean = True);
        procedure EnterUiLock(const Lock: boolean);
        procedure CreateSyncObject();
    end;

var
    somain          : Tsomain;
    TriggerSlow     : Cardinal;
    TriggerInterval : Cardinal;
    ProxyEnable     : Boolean;
    ProxyServer     : string;
    ProxyPort       : string;
    OutPutDebug     : Boolean = False;
    IsNetWorkValid  : Boolean = False;

procedure SemaphoreAcquire(const hd: THandle);
procedure SemaphoreRelease(const hd: THandle);
function ExecuteSQL(SqlStr: string): boolean;
procedure DebugPrintf(output: string);

implementation

uses copyright, newtask, server, config, SearchTest,
    BugReport, NetThread;

{$R *.dfm}

procedure SemaphoreAcquire(const hd: THandle);
var
    ret             : DWORD;
begin
    if (hd = 0) then
        Exit;

    {
        *** WARNING HERE ***
        if some one hold the semaphore more than 120 seconds,below code will
        trig a divide by zero exception,and handle by Default exception handler.
    }
    ret := WaitForSingleObject(hd, 120000);

    if (ret <> WAIT_OBJECT_0) then
    begin
        ret := ret div (ret - ret);

        while (ret <> WAIT_OBJECT_0) do
        begin
        end;
    end;
end;

procedure SemaphoreRelease(const hd: THandle);
var
    pre             : DWORD;
    ret             : BOOL;
begin
    if (hd = 0) then
        Exit;

    ret := ReleaseSemaphore(hd, 1, @pre);

    if (pre <> 0) or (not ret) then
    begin
        pre := pre div (pre - pre);

        while (pre <> 0) do
        begin
        end;
    end;
end;

function ExecuteSQL(SqlStr: string): boolean;
begin
    //返回布尔值的ExecuteSQL
    result := false;
    SemaphoreAcquire(DBtoken);
    with adolink do
    begin
        Close;
        SQL.Clear;
        SQL.Text := SqlStr;

        try
            ExecSQL;
            result := true;
        except
            on E: Exception do
            begin
                DebugPrintf('ExecuteSQL(ENO0002):' + E.Message);
            end;
        end;

        SQL.Clear;
        Close;
    end;
    SemaphoreRelease(DBtoken);
end;

procedure DebugPrintf(output: string);
begin
    if OutPutDebug then
    begin
        OutputDebugString(PChar(output));
    end;
end;

procedure Tsomain.FormCreate(Sender: TObject);
var
    i               : integer;
    r               : TRegistry;
    t               : CNetInfoThread;
begin
    //初始化蜘蛛和线程数目
    Application.HelpFile := ExtractFilePath(application.ExeName) +
        'UindexWeb.PDF';
    Application.OnException := UindexWebException;
    //文件类型定
    DomainExt := TStringList.Create;
    CSpilterList := TStringList.Create;

    binExtList := TStringList.Create;
    TextExtList := TStringList.Create;
    ImgExtList := TStringList.Create;
    MovieExtList := TStringList.Create;
    PreCSWList := TStringList.Create;
    SpiderNameList := TStringList.Create;
    //地址记录
    SiteUrlList := CTopCliper.Create(nil);
    EmbedFileList := CTopCliper.Create(nil);
    ClipList := CTopCliper.Create(nil);
    //静态加载部分
    WaitSiteList := TStringList.Create;
    SystemBadWordList := TStringList.Create;
    SystemForbidenUrlList := TStringList.Create;
    CurrentForbidenUrlList := TStringList.Create;
    CurrentBadWordList := TStringList.Create;
    GlobalImageList.GetBitmap(StartSearch.ImageIndex, SpiderViewBtn.Glyph);

    //初始化设置
    CurrentSiteID := -1;
    CurrentGroupID := 13;
    ThreadNum := 0;
    MaxThreadNum := 12;
    ModifyThreadNum.Tag := 0;
    PageErrorPermit := 0;
    ThisSiteMaxPage := 0;
    ThisHaveIndex := 0;
    ProofDuplicate := 0;
    PageAccessError := 0;
    SoStartTime := Now;
    AllSearched := 0;
    WorkInOpenMode := false;
    WaitWindow.Visible := false;
    setlength(PageHaveCreated, MaxThreadNum);
    setlength(SpiderUrl, MaxThreadNum);

    for i := 0 to MaxThreadNum - 1 do
    begin
        PageHaveCreated[i] := false;
        SpiderUrl[i].Text := '';
    end;

    divx := Width - 648;
    divy := Height - 484;
    GlobalDataBase := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='
        + ExtractFilePath(application.ExeName) +
        'UindexWeb.mdb;Persist Security Info=False';

    adolink := TADOQuery.Create(nil);
    adolink.ConnectionString := GlobalDataBase;

    //获取代理服务器设置
    ProxyEnable := False;
    r := TRegistry.Create;
    try
        r.RootKey := HKEY_CURRENT_USER;
        if
            (r.OpenKey('Software\Microsoft\Windows\CurrentVersion\Internet Settings', False)) then
        begin
            ProxyEnable := r.ReadBool('ProxyEnable');
            ProxyServer := r.ReadString('ProxyServer');
            ProxyPort := ProxyServer;

            i := NCpos(':', ProxyServer);
            if (i > 0) and (i < Length(ProxyServer)) then
            begin
                ProxyPort := Copy(ProxyServer, i + 1, Length(ProxyServer));
                Delete(ProxyServer, i, Length(ProxyServer));

                if (ProxyPort = '') or (ProxyServer = '') then
                begin
                    ProxyEnable := False;
                end;
            end else
            begin
                ProxyEnable := False;
            end;
            r.CloseKey;
        end;
    finally
        r.Free;
    end;

    t := CNetInfoThread.Create(False);
    t.FreeOnTerminate := True;
end;

procedure Tsomain.QuitEngineClick(Sender: TObject);
begin
    if IsSpiderRunning then
    begin
        case Application.MessageBox(PChar(CopyRightStr +
            '正在运行中,确定要立即退出吗?'),
            PChar('是否退出?'), MB_ICONQUESTION or MB_OKCANCEL or MB_DEFBUTTON2)
            of
            IDOK: ExitApplication(true);
            IDCANCEL: ;
        end;
    end else
        ExitApplication(true);
end;

procedure Tsomain.FlashTriggerTimer(Sender: TObject);
begin
    PostMessage(Self.Handle, FlashTriggerMessage, 0, 0);
end;

function Tsomain.IsThreadRunning(const i: integer): boolean;
begin
    result := PageHaveCreated[i] and (Length(Trim(SpiderUrl[i].Text)) > 5)
end;

function Tsomain.WorkingSpider(): integer;
var i               : integer;
begin
    //-------------------------------------------------------------------------
    //正在运行线程的数目,没有加或减一
    //-------------------------------------------------------------------------
    result := 0;
    for i := 0 to ThreadNum - 1 do
    begin
        if IsThreadRunning(i) then
            inc(result);
    end;
end;

procedure Tsomain.StartSearchClick(Sender: TObject);
begin
    if WaitSiteList.Count > 0 then
    begin
        case
            Application.MessageBox(PChar(Format('上次搜索还有 %d 个网站正在等待,点击"是" 开始全新搜索,"否" 将保留上次搜索任务.', [WaitSiteList.Count])), PChar('搜索方式'), MB_ICONQUESTION or MB_YESNO) of
            IDYES: WaitSiteList.Clear;
            IDNO: ;
        end;
    end else if (CurrentGroupID >= 0) and (CurrentGroupID <= 12) then
    begin
        case
            Application.MessageBox(PChar(Format('正在搜索第 %d 组网站,点击"是" 全新搜索,"否" 将保留上次搜索任务.', [CurrentGroupID])), PChar('搜索方式'), MB_ICONQUESTION or MB_YESNO) of
            IDYES: CurrentGroupID := 13;
            IDNO: ;
        end;
    end;

    ShowModalWindow(TaskNew);
end;

function Tsomain.GetNextUrl(SpiderId: integer): string;
var
    HaveLeftUrl     : boolean;
    Exceeded        : boolean;
begin
    HaveLeftUrl := false;
    Exceeded := false;

    if (ThisSiteMaxPage > 0) and (PageErrorPermit > 0) then
        Exceeded := (ThisHaveIndex >= ThisSiteMaxPage) or (PageAccessError >=
            PageErrorPermit)
    else if (ThisSiteMaxPage > 0) then
        Exceeded := (ThisHaveIndex >= ThisSiteMaxPage)
    else if (PageErrorPermit > 0) then
        Exceeded := (PageAccessError >= PageErrorPermit);

    if (not Exceeded) then
    begin
        SemaphoreAcquire(DBtoken);
        with adolink do
        begin
            Close;
            SQL.Clear;
            SQL.Text :=
                Format('Select Top 1 WUId,WUUrl,WUStatus,WUSiteId,WUSize From UindexWeb_WebUrl Where WUSiteId=%d and WUStatus=0 Order By WUId', [CurrentSiteID]);
            Open;
            if (not Eof) then
            begin
                inc(ThisHaveIndex);
                HaveLeftUrl := true;

                if VarIsOrdinal(adolink.Recordset.Fields[0].Value) then
                    PageUrlId[SpiderId] := Recordset.Fields[0].Value
                else
                    PageUrlId[SpiderId] := 0;

                if IsValidVarString(Recordset.Fields[1].Value) then
                    Result := Recordset.Fields[1].Value;

                //获得该网页上次检索时的大小
                if VarIsOrdinal(Recordset.Fields[4].Value) then
                    PageSizeArray[SpiderId] := Recordset.Fields[4].Value
                else
                    PageSizeArray[SpiderId] := 0;
            end;
            SQL.Clear;
            Close;
        end;
        SemaphoreRelease(DBtoken);
    end;

    if Exceeded or (not HaveLeftUrl) then
    begin
        PageUrlId[SpiderId] := 0;
        PageSizeArray[SpiderId] := 0;

        //只有编号为0的线程才能决定是否切换站点.
        if (CurrentSubRoot <> '') and (WorkingSpider = 0) and (SpiderId = 0)
            then
            StatusPrintf(CurrentSubRoot + ' 搜索完成.');
    end;

    if HaveLeftUrl and (Result <> '') then
        ExecuteSQL(Format('Update UindexWeb_WebUrl Set WUStatus=1 where WUId=%d',
            [PageUrlId[SpiderId]]))
    else
        if ((WorkingSpider = 0) and (SpiderId = 0)) then
        begin
            if CurrentSiteID > 0 then
                ExecuteSQL(Format('Update UindexWeb_Entry Set SEStatus=2 where SEId=%d', [CurrentSiteID]));
            GetNextSite(CurrentGroupID);
        end;
end;

function Tsomain.GetNextSite(GroupId: integer): string;
//------------------------------------------------------------------------------
// 该函数只能受有数据库使用权的函数调用
//------------------------------------------------------------------------------
var sql, rlt        : string;
    HaveLeftSite    : boolean;
    i               : integer;
begin
    rlt := '';
    HaveLeftSite := false;

    SemaphoreAcquire(DBtoken);
    adolink.Close;
    adolink.SQL.Clear;
    ThisHaveIndex := 0;
    PageAccessError := 0;
    if WaitSiteList.Count > 0 then
    begin
        sql := 'Select Top 1 SEId,SERoot,SEEntryPoint,SEGroup,SEStatus,SEMaxpage,SEForbiden,SEClipmax,'
            + 'SEBadwords From UindexWeb_Entry Where SEId=' + WaitSiteList[0];
        WaitSiteList.Delete(0);
    end else if (GroupId >= 0) then
        sql :=
            Format('Select Top 1 SEId,SERoot,SEEntryPoint,SEGroup,SEStatus,SEMaxpage,SEForbiden,SEClipmax,SEBadwords From UindexWeb_Entry Where SEStatus=0 and SEGroup=%d Order By SEId', [GroupId])
    else
        sql :=
            'Select Top 1 SEId,SERoot,SEEntryPoint,SEGroup,SEStatus,SEMaxpage,SEForbiden,SEClipmax,SEBadwords From UindexWeb_Entry Where SEStatus=0 Order By SEId';
    adolink.SQL.Text := sql;
    adolink.Open;
    if not adolink.Eof then
    begin
        HaveLeftSite := true;
        if VarIsOrdinal(adolink.Recordset.Fields[0].Value) then
            CurrentSiteID := adolink.Recordset.Fields[0].Value
        else
            CurrentSiteID := 0;

        if IsValidVarString(adolink.Recordset.Fields[2].Value) then
        begin
            CurrentSubRoot :=
                LowAndTrim(GetDomainRoot(adolink.Recordset.Fields[2].Value));
            rlt := adolink.Recordset.Fields[2].Value;
        end else
        begin
            CurrentSubRoot := '';
            rlt := '';
        end;

        if IsValidVarString(adolink.Recordset.Fields[1].Value) then
        begin
            if (CurrentRoot = '') or (NCpos(CurrentRoot,
                LowAndTrim(adolink.Recordset.Fields[1].Value)) <= 0) then
            begin
                DebugPrintf('(获取下一站点时)切换根域至：' +
                    LowAndTrim(adolink.Recordset.Fields[1].Value) + '当前根域：'
                    +
                    CurrentRoot);
                CurrentRoot := LowAndTrim(adolink.Recordset.Fields[1].Value);
            end;
        end else
        begin
            CurrentRoot := CurrentSubRoot;
        end;

        if VarIsOrdinal(adolink.Recordset.Fields[5].Value) and
            (adolink.Recordset.Fields[5].Value > 0) then
            ThisSiteMaxPage := adolink.Recordset.Fields[5].Value
        else
            ThisSiteMaxPage := StringToIntDef(configweb.MaxIndexPage.Text, 256);
        //整理禁用列表
        if IsValidVarString(adolink.Recordset.Fields[6].Value) then
            CurrentForbidenUrlList.Text := adolink.Recordset.Fields[6].Value
        else
            CurrentForbidenUrlList.Text := '';
        if IsValidVarString(adolink.Recordset.Fields[8].Value) then
            CurrentBadWordList.Text := adolink.Recordset.Fields[8].Value
        else
            CurrentBadWordList.Text := '';
        if VarIsOrdinal(adolink.Recordset.Fields[7].Value) and
            (adolink.Recordset.Fields[7].Value > 0) then
            ProofDuplicate := adolink.Recordset.Fields[7].Value
        else begin
            ProofDuplicate := ClipList.DefaultMax;
        end;
        for i := 0 to CurrentForbidenUrlList.Count - 1 do
        begin
            if i < CurrentForbidenUrlList.Count then
            begin
                if (Trim(CurrentForbidenUrlList[i]) = '') or
                    (SystemForbidenUrlList.IndexOf(LowAndTrim(CurrentForbidenUrlList[i])) >= 0) then
                begin
                    CurrentForbidenUrlList.Delete(i);
                end else
                    CurrentForbidenUrlList[i] :=
                        LowAndTrim(CurrentForbidenUrlList[i]);
            end else
                Break;
        end;
        for i := 0 to CurrentBadWordList.Count - 1 do
        begin
            if i < CurrentBadWordList.Count then
            begin
                if (Trim(CurrentBadWordList[i]) = '') or
                    (SystemBadWordList.IndexOf(LowAndTrim(CurrentBadWordList[i]))
                    >=
                    0) then
                begin
                    CurrentBadWordList.Delete(i);
                end else
                    CurrentBadWordList[i] := LowAndTrim(CurrentBadWordList[i]);
            end else
                Break;
        end;
    end else begin
        ThisSiteMaxPage := StringToIntDef(configweb.MaxIndexPage.Text, 256);
        CurrentForbidenUrlList.Text := '';
        CurrentBadWordList.Text := '';
        ProofDuplicate := ClipList.DefaultMax;
    end;
    adolink.SQL.Clear;
    adolink.Close;
    SemaphoreRelease(DBtoken);

    UpdateAntiDuplicat;

    if HaveLeftSite and (CurrentSiteID > 0) and (CurrentSubRoot <> '') and (rlt
        <> '') then
    begin
        InsertSiteRoot(CurrentSiteID);
        ExecuteSQL(Format('Update UindexWeb_Entry Set SEStatus=1 where SEId=%d',
            [CurrentSiteID]));
    end else begin
        //已经将该组搜索完成
        StatusPrintf(Format('第 %d 组网站搜索完成.', [GroupId]));
        CompleteGroup(GroupId);
    end;
    Result := rlt;
end;

procedure Tsomain.UpdateAntiDuplicat();
var buffersize      : integer;
begin
    //--------------------------------------------------------------------------
    //缓存512片,强力避免重复
    //--------------------------------------------------------------------------
    if ProofDuplicate <= 0 then
        buffersize := StringToIntDef(configweb.ClipBufferMax.Text, 512)
    else
        buffersize := ProofDuplicate;

    SemaphoreAcquire(URLtoken);
    SiteUrlList.MaxHeap := buffersize;
    SemaphoreRelease(URLtoken);

    SemaphoreAcquire(FILEtoken);
    EmbedFileList.MaxHeap := buffersize;
    SemaphoreRelease(FILEtoken);

    SemaphoreAcquire(CLIPtoken);
    ClipList.MaxHeap := buffersize;
    SemaphoreRelease(CLIPtoken);
end;

procedure Tsomain.InsertSiteRoot(SiteID: integer);
var url, sql        : string;
    EofError        : boolean;
begin
    EofError := true;

    SemaphoreAcquire(DBtoken);
    adolink.Close;
    adolink.SQL.Clear;
    sql :=
        Format('Select Top 1 SEId,SERoot,SEEntryPoint From UindexWeb_Entry Where SEId=%d Order By SEId', [SiteID]);
    adolink.SQL.Text := sql;
    adolink.Open;
    if not adolink.Eof then
    begin
        EofError := false;
        if VarIsOrdinal(adolink.Recordset.Fields[0].Value) then
            CurrentSiteID := adolink.Recordset.Fields[0].Value
        else
            CurrentSiteID := 0;

        if IsValidVarString(adolink.Recordset.Fields[2].Value) then
        begin
            CurrentSubRoot :=
                LowAndTrim(GetDomainRoot(adolink.Recordset.Fields[2].Value));
            url := adolink.Recordset.Fields[2].Value;
        end else
        begin
            CurrentSubRoot := '';
            url := '';
        end;

        if IsValidVarString(adolink.Recordset.Fields[1].Value) then
        begin
            if (CurrentRoot = '') or (NCpos(CurrentRoot,
                LowAndTrim(adolink.Recordset.Fields[1].Value)) <= 0) then
            begin
                DebugPrintf('(插入网站入口时)切换根域至：' +
                    LowAndTrim(adolink.Recordset.Fields[1].Value) + '当前根域：'
                    +
                    CurrentRoot);
                CurrentRoot := LowAndTrim(adolink.Recordset.Fields[1].Value);
            end;
        end else
        begin
            CurrentRoot := CurrentSubRoot;
        end;
    end;
    adolink.SQL.Clear;
    adolink.Close;
    SemaphoreRelease(DBtoken);

    if (not EofError) and (CurrentSiteID > 0) and (CurrentSubRoot <> '') and (url
        <> '') then
    begin
        //----------------------------------------------------------------------
        // 若站点列表标示未更新,则认为从新更新,不保存模式
        //----------------------------------------------------------------------
        if ConfigWeb.DiscardTmp.Checked then
            DiscardSite(CurrentSiteID);

        sql := 'Insert Into UindexWeb_WebUrl(WUUrl,WUStatus,WUSiteId,WUParent) values('''
            + url + ''',0,' + IntToStr(CurrentSiteID) + ',0)';
        //----------------------------------------------------------------------
        // 这里如果写入失败,说明该网站已经被检索,现在的任务就是要更新变化了的网页
        //没有变化的只需要分析一下超连接,看下级页面有没有变化,所以这里设置所有的
        //下级URL为未更新状态.
        //----------------------------------------------------------------------
        if ExecuteSQL(sql) then
            StatusPrintf('为网站 ' + CurrentSubRoot + ' 写入入口地址.')
        else begin
            ExecuteSQL('Update UindexWeb_WebUrl Set WUStatus=0,WUParent=0,WUSiteId='
                + IntToStr(CurrentSiteID) + ' where WUUrl=''' + url + '''');
            StatusPrintf('更新网站 ' + CurrentSubRoot + ' 页面.');
        end;
    end;
end;

procedure Tsomain.CompleteGroup(GroupID: integer);
var SoEndTime       : TDateTime;
    SpentDay, SpentHour, SpentMinute: int64;
begin
    FlashTrigger.Enabled := false;
    //计算消耗时间
    SoEndTime := Now;
    SpentMinute := MinutesBetween(SoEndTime, SoStartTime) mod 60;
    SpentHour := HoursBetween(SoEndTime, SoStartTime) mod 60;
    SpentDay := DaysBetween(SoEndTime, SoStartTime);
    if m_ExitEngine.Checked or m_autoshutdown.Checked or LogOff.Checked then
    begin
        //-------------------------------------------------------------------------
        // 选择了退出或自动关机
        //-------------------------------------------------------------------------
        if m_ExitEngine.Checked then
            ExitApplication(true)
        else begin
            if LogOff.Checked then
                StatusPrintf('设置了 ' + LogOff.Hint + ' ,正在数秒.')
            else
                StatusPrintf('设置了 ' + m_autoshutdown.Hint + ' ,正在数秒.');
            CountSecond.Enabled := true;
        end;
    end else if (GroupID > -1) and (GroupID < 13) then
        Application.MessageBox(PChar(ShortCopyRight + '已完成对第 ' +
            IntToStr(GroupId)
            + ' 组网站的搜索.' + #13 + #13 + '耗时 ' + IntToStr(SpentDay) +
            '天, ' + IntToStr(SpentHour)
            + '小时, ' + IntToStr(SpentMinute) + '分,搜索网页 ' +
            IntToStr(AllSearched)
            + '页.'), PChar('搜索完成'), MB_ICONINFORMATION or MB_OK)
    else
        Application.MessageBox(PChar('用户选择的网站已全部搜索完成.' + #13 + #13
            + '耗时 '
            + IntToStr(SpentDay) + '天, ' + IntToStr(SpentHour) + '小时, ' +
            IntToStr(SpentMinute)
            + '分,搜索网页 ' + IntToStr(AllSearched) + '页.'),
            PChar('搜索完成'), MB_ICONINFORMATION or MB_OK);
    CurrentGroupId := 13;
    CurrentSubRoot := '';
    CurrentRoot := '';
    CurrentSiteID := -1;
    WaitSiteList.Clear;
end;

procedure Tsomain.SetThreadNum(ThreadCount: integer);
var i               : integer;
begin
    //-------------------------------------------------------------------------
    //  在重新分配内存前释放已经创建的页
    //-------------------------------------------------------------------------
    if WorkingSpider > 0 then
        exit;

    SpiderTabs.Hide;
    Screen.Cursor := crHourGlass;

    for i := 1 to MaxThreadNum do
    begin
        if PageHaveCreated[(MaxThreadNum - i)] then
        begin
            SpiderTab[MaxThreadNum - i].Free;
            PageHaveCreated[MaxThreadNum - i] := false;
            SpiderList[MaxThreadNum - i].Terminate;
        end;
    end;
    //-------------------------------------------------------------------------
    //  为界面元素重新分配资源
    //-------------------------------------------------------------------------
    setlength(SpiderTab, ThreadCount);
    setlength(CurrentPage, ThreadCount);
    setlength(UrlHeader, ThreadCount);
    setlength(Inprocess, ThreadCount);
    setlength(HasProcessed, ThreadCount);
    setlength(StaticsInfo, ThreadCount);
    setlength(PageLen, ThreadCount);
    setlength(PageLenNum, ThreadCount);
    setlength(FindLink, ThreadCount);
    setlength(FindLinkNum, ThreadCount);
    setlength(FindTotalUrls, ThreadCount);
    setlength(FindTotalUrlNums, ThreadCount);
    setlength(FindEmbeds, ThreadCount);
    setlength(FindEmbedNums, ThreadCount);
    setlength(FindEvent, ThreadCount);
    setlength(FindEventNum, ThreadCount);
    setlength(ClipInfo, ThreadCount);
    setlength(ClipInfoNum, ThreadCount);

    setlength(OfDomain, ThreadCount);
    setlength(OfDomainStr, ThreadCount);
    setlength(MessagePanel, ThreadCount);
    setlength(ImportantMsg, ThreadCount);
    setlength(ImportantMsgStr, ThreadCount);
    setlength(SplitInfo, ThreadCount);
    setlength(SplitInfobar, ThreadCount);
    setlength(ParseProgress, ThreadCount);
    setlength(ParseProgressBar, ThreadCount);
    setlength(WriteProgress, ThreadCount);
    setlength(WriteProgressBar, ThreadCount);
    setlength(SpentTime, ThreadCount);
    setlength(SpentTimeStr, ThreadCount);
    setlength(PageUrlId, ThreadCount);
    setlength(PageSizeArray, ThreadCount);
    //创建这些线程
    setlength(SpiderList, ThreadCount);
    for i := 0 to ThreadCount - 1 do
    begin
        SpiderList[i] := CSpider.Create(i);
        SpiderList[i].Oncomplete := ThreadComplete;
        SpiderList[i].FreeOnTerminate := True;
    end;
    //-------------------------------------------------------------------------
    //  根据用户的要求创建 ThreadCount 个界面
    //-------------------------------------------------------------------------
    for i := 0 to ThreadCount - 1 do
    begin
        SpiderTab[i] := TTabSheet.Create(SpiderTabs);
        with SpiderTab[i] do
        begin
            Align := alClient;
            Visible := True;
            Caption := SpiderNameList[i];
            PageControl := SpiderTabs;
            ImageIndex := 0;
            Parent := SpiderTabs;
        end;
        //当前网页组合框
        CurrentPage[i] := TgroupBox.Create(SpiderTab[i]);
        CurrentPage[i].Visible := True;
        CurrentPage[i].Caption := '当前网页:';
        CurrentPage[i].height := 49;
        CurrentPage[i].Width := 0;
        CurrentPage[i].Top := 0;
        CurrentPage[i].Left := 0;
        CurrentPage[i].Parent := SpiderTab[i];
        //显示当前页标志
        UrlHeader[i] := Tlabel.Create(CurrentPage[i]);
        UrlHeader[i].Visible := true;
        UrlHeader[i].AutoSize := false;
        UrlHeader[i].Caption := 'URL：';
        UrlHeader[i].Height := 13;
        UrlHeader[i].Width := 30;
        UrlHeader[i].Top := 21;
        UrlHeader[i].Left := 8;
        UrlHeader[i].Parent := CurrentPage[i];
        //当前网页地址
        SpiderUrl[i] := TEdit.Create(CurrentPage[i]);
        SpiderUrl[i].AutoSize := false;
        SpiderUrl[i].Visible := true;
        SpiderUrl[i].Text := '';
        SpiderUrl[i].ReadOnly := true;
        SpiderUrl[i].Top := 20;
        SpiderUrl[i].Left := 45;
        SpiderUrl[i].Height := 17;
        SpiderUrl[i].Parent := CurrentPage[i];
        //正在处理中
        Inprocess[i] := TcheckBox.Create(CurrentPage[i]);
        Inprocess[i].Caption := '正在处理';
        Inprocess[i].Top := 20;
        Inprocess[i].Visible := true;
        Inprocess[i].Enabled := false;
        Inprocess[i].Width := 73;
        Inprocess[i].Height := 17;
        Inprocess[i].Checked := false;
        Inprocess[i].Parent := CurrentPage[i];
        //已经处理完成
        HasProcessed[i] := TcheckBox.Create(CurrentPage[i]);
        HasProcessed[i].Caption := '处理完成';
        HasProcessed[i].Top := 20;
        HasProcessed[i].Visible := true;
        HasProcessed[i].Enabled := false;
        HasProcessed[i].Width := 73;
        HasProcessed[i].Height := 17;
        HasProcessed[i].Checked := false;
        HasProcessed[i].Parent := CurrentPage[i];
        //网页信息统计
        StaticsInfo[i] := TgroupBox.Create(SpiderTab[i]);
        StaticsInfo[i].Visible := True;
        StaticsInfo[i].Caption := '统计信息:';
        StaticsInfo[i].height := 87;
        StaticsInfo[i].Width := 0;
        StaticsInfo[i].Top := 50;
        StaticsInfo[i].Left := 0;
        StaticsInfo[i].Parent := SpiderTab[i];
        //--------------------------------------------------------------------
        // 第一行元素
        //--------------------------------------------------------------------
        //网页长度
        PageLen[i] := Tlabel.Create(StaticsInfo[i]);
        PageLen[i].Visible := true;
        PageLen[i].AutoSize := false;
        PageLen[i].Caption := '网页长度:';
        PageLen[i].Height := 13;
        PageLen[i].Width := 63;
        PageLen[i].Top := 18;
        PageLen[i].Left := 8;
        PageLen[i].Parent := StaticsInfo[i];
        //网页长度值
        PageLenNum[i] := Tlabel.Create(StaticsInfo[i]);
        PageLenNum[i].Visible := true;
        PageLenNum[i].AutoSize := false;
        PageLenNum[i].Caption := '0';
        PageLenNum[i].Height := 13;
        PageLenNum[i].Width := 55;
        PageLenNum[i].Top := 18;
        PageLenNum[i].Left := 73;
        PageLenNum[i].Parent := StaticsInfo[i];
        //发现连接
        FindLink[i] := Tlabel.Create(StaticsInfo[i]);
        FindLink[i].Visible := true;
        FindLink[i].AutoSize := false;
        FindLink[i].Caption := '有效链接:';
        FindLink[i].Height := 13;
        FindLink[i].Width := 63;
        FindLink[i].Top := 18;
        FindLink[i].Left := 136;
        FindLink[i].Parent := StaticsInfo[i];
        //发现连接数
        FindLinkNum[i] := Tlabel.Create(StaticsInfo[i]);
        FindLinkNum[i].Visible := true;
        FindLinkNum[i].AutoSize := false;
        FindLinkNum[i].Caption := '0';
        FindLinkNum[i].Height := 13;
        FindLinkNum[i].Width := 55;
        FindLinkNum[i].Top := 18;
        FindLinkNum[i].Left := 203;
        FindLinkNum[i].Parent := StaticsInfo[i];
        //嵌入文件
        FindTotalUrls[i] := Tlabel.Create(StaticsInfo[i]);
        FindTotalUrls[i].Visible := true;
        FindTotalUrls[i].AutoSize := false;
        FindTotalUrls[i].Caption := '全部链接:';
        FindTotalUrls[i].Height := 13;
        FindTotalUrls[i].Width := 63;
        FindTotalUrls[i].Top := 18;
        FindTotalUrls[i].Left := 265;
        FindTotalUrls[i].Parent := StaticsInfo[i];
        //嵌入文件数
        FindTotalUrlNums[i] := Tlabel.Create(StaticsInfo[i]);
        FindTotalUrlNums[i].Visible := true;
        FindTotalUrlNums[i].AutoSize := false;
        FindTotalUrlNums[i].Caption := '0';
        FindTotalUrlNums[i].Height := 13;
        FindTotalUrlNums[i].Width := 55;
        FindTotalUrlNums[i].Top := 18;
        FindTotalUrlNums[i].Left := 330;
        FindTotalUrlNums[i].Parent := StaticsInfo[i];
        //--------------------------------------------------------------------
        // 第二行元素
        //--------------------------------------------------------------------
        //图片
        FindEmbeds[i] := Tlabel.Create(StaticsInfo[i]);
        FindEmbeds[i].Visible := true;
        FindEmbeds[i].AutoSize := false;
        FindEmbeds[i].Caption := '包含文件:';
        FindEmbeds[i].Height := 13;
        FindEmbeds[i].Width := 63;
        FindEmbeds[i].Top := 40;
        FindEmbeds[i].Left := 8;
        FindEmbeds[i].Parent := StaticsInfo[i];
        //图片值
        FindEmbedNums[i] := Tlabel.Create(StaticsInfo[i]);
        FindEmbedNums[i].Visible := true;
        FindEmbedNums[i].AutoSize := false;
        FindEmbedNums[i].Caption := '0';
        FindEmbedNums[i].Height := 13;
        FindEmbedNums[i].Width := 55;
        FindEmbedNums[i].Top := 40;
        FindEmbedNums[i].Left := 73;
        FindEmbedNums[i].Parent := StaticsInfo[i];
        //解析事件
        FindEvent[i] := Tlabel.Create(StaticsInfo[i]);
        FindEvent[i].Visible := true;
        FindEvent[i].AutoSize := false;
        FindEvent[i].Caption := '解析事件:';
        FindEvent[i].Height := 13;
        FindEvent[i].Width := 63;
        FindEvent[i].Top := 40;
        FindEvent[i].Left := 136;
        FindEvent[i].Parent := StaticsInfo[i];
        //解析事件数
        FindEventNum[i] := Tlabel.Create(StaticsInfo[i]);
        FindEventNum[i].Visible := true;
        FindEventNum[i].AutoSize := false;
        FindEventNum[i].Caption := '0';
        FindEventNum[i].Height := 13;
        FindEventNum[i].Width := 55;
        FindEventNum[i].Top := 40;
        FindEventNum[i].Left := 203;
        FindEventNum[i].Parent := StaticsInfo[i];
        //信息分片
        ClipInfo[i] := Tlabel.Create(StaticsInfo[i]);
        ClipInfo[i].Visible := true;
        ClipInfo[i].AutoSize := false;
        ClipInfo[i].Caption := '信息分片:';
        ClipInfo[i].Height := 13;
        ClipInfo[i].Width := 63;
        ClipInfo[i].Top := 40;
        ClipInfo[i].Left := 265;
        ClipInfo[i].Parent := StaticsInfo[i];
        //信息分片数
        ClipInfoNum[i] := Tlabel.Create(StaticsInfo[i]);
        ClipInfoNum[i].Visible := true;
        ClipInfoNum[i].AutoSize := false;
        ClipInfoNum[i].Caption := '0';
        ClipInfoNum[i].Height := 13;
        ClipInfoNum[i].Width := 55;
        ClipInfoNum[i].Top := 40;
        ClipInfoNum[i].Left := 330;
        ClipInfoNum[i].Parent := StaticsInfo[i];
        //--------------------------------------------------------------------
        // 第三行元素
        //--------------------------------------------------------------------
        //所在站点
        OfDomain[i] := Tlabel.Create(StaticsInfo[i]);
        OfDomain[i].Visible := true;
        OfDomain[i].AutoSize := false;
        OfDomain[i].Caption := '所在网站:';
        OfDomain[i].Height := 13;
        OfDomain[i].Width := 63;
        OfDomain[i].Top := 62;
        OfDomain[i].Left := 8;
        OfDomain[i].Parent := StaticsInfo[i];
        //所在站点
        OfDomainStr[i] := Tlabel.Create(StaticsInfo[i]);
        OfDomainStr[i].Visible := true;
        OfDomainStr[i].AutoSize := false;
        OfDomainStr[i].Caption := HomePageUrl;
        OfDomainStr[i].Height := 13;
        OfDomainStr[i].Top := 62;
        OfDomainStr[i].Left := OfDomain[i].Left + OfDomain[i].Width;
        OfDomainStr[i].Parent := StaticsInfo[i];
        //网页信息统计
        MessagePanel[i] := TgroupBox.Create(SpiderTab[i]);
        MessagePanel[i].Visible := True;
        MessagePanel[i].Caption := '';
        MessagePanel[i].height := 90;
        MessagePanel[i].Width := 0;
        MessagePanel[i].Top := 137;
        MessagePanel[i].Left := 0;
        MessagePanel[i].Parent := SpiderTab[i];
        //重要消息
        ImportantMsg[i] := Tlabel.Create(MessagePanel[i]);
        ImportantMsg[i].Visible := true;
        ImportantMsg[i].AutoSize := false;
        ImportantMsg[i].Caption := '重要消息:';
        ImportantMsg[i].Height := 13;
        ImportantMsg[i].Width := 63;
        ImportantMsg[i].Top := 17;
        ImportantMsg[i].Left := 8;
        ImportantMsg[i].Parent := MessagePanel[i];
        //重要消息内容
        ImportantMsgStr[i] := TEdit.Create(MessagePanel[i]);
        ImportantMsgStr[i].AutoSize := false;
        ImportantMsgStr[i].Visible := true;
        ImportantMsgStr[i].Text := '准备就绪...';
        ImportantMsgStr[i].ReadOnly := true;
        ImportantMsgStr[i].Color := clBtnFace;
        ImportantMsgStr[i].Font.Color := clBlue;
        ImportantMsgStr[i].Top := 16;
        ImportantMsgStr[i].Left := 66;
        ImportantMsgStr[i].Height := 17;
        ImportantMsgStr[i].Parent := MessagePanel[i];
        //拆分进度
        SplitInfo[i] := Tlabel.Create(MessagePanel[i]);
        SplitInfo[i].Visible := true;
        SplitInfo[i].AutoSize := false;
        SplitInfo[i].Caption := '拆分进度:';
        SplitInfo[i].Height := 13;
        SplitInfo[i].Width := 63;
        SplitInfo[i].Top := 40;
        SplitInfo[i].Parent := MessagePanel[i];
        //拆分进度指示
        SplitInfobar[i] := tprogressbar.Create(MessagePanel[i]);
        SplitInfobar[i].Max := 100;
        SplitInfobar[i].Min := 0;
        SplitInfobar[i].Position := 0;
        SplitInfobar[i].Visible := true;
        SplitInfobar[i].Top := 40;
        SplitInfobar[i].Height := 16;
        SplitInfobar[i].Step := 1;
        SplitInfobar[i].Smooth := true;
        SplitInfobar[i].Parent := MessagePanel[i];
        //解析进度
        ParseProgress[i] := Tlabel.Create(MessagePanel[i]);
        ParseProgress[i].Visible := true;
        ParseProgress[i].AutoSize := false;
        ParseProgress[i].Caption := '解析进度:';
        ParseProgress[i].Height := 13;
        ParseProgress[i].Width := 63;
        ParseProgress[i].Top := 40;
        ParseProgress[i].Left := 8;
        ParseProgress[i].Parent := MessagePanel[i];
        //解析进度指示
        ParseProgressbar[i] := tprogressbar.Create(MessagePanel[i]);
        ParseProgressbar[i].Max := 100;
        ParseProgressbar[i].Min := 0;
        ParseProgressbar[i].Position := 0;
        ParseProgressbar[i].Visible := true;
        ParseProgressbar[i].Left := 66;
        ParseProgressbar[i].Top := 40;
        ParseProgressbar[i].Height := 16;
        ParseProgressbar[i].Step := 1;
        ParseProgressbar[i].Smooth := true;
        ParseProgressbar[i].Parent := MessagePanel[i];
        //写入进度
        WriteProgress[i] := Tlabel.Create(MessagePanel[i]);
        WriteProgress[i].Visible := true;
        WriteProgress[i].AutoSize := false;
        WriteProgress[i].Caption := '写入进度:';
        WriteProgress[i].Height := 13;
        WriteProgress[i].Width := 63;
        WriteProgress[i].Top := 64;
        WriteProgress[i].Left := 8;
        WriteProgress[i].Parent := MessagePanel[i];
        //写入进度指示
        WriteProgressbar[i] := tprogressbar.Create(MessagePanel[i]);
        WriteProgressbar[i].Max := 100;
        WriteProgressbar[i].Min := 0;
        WriteProgressbar[i].Position := 0;
        WriteProgressbar[i].Visible := true;
        WriteProgressbar[i].Left := 66;
        WriteProgressbar[i].Top := 64;
        WriteProgressbar[i].Height := 16;
        WriteProgressbar[i].Step := 1;
        WriteProgressbar[i].Smooth := true;
        WriteProgressbar[i].Parent := MessagePanel[i];
        //消耗时间
        SpentTime[i] := Tlabel.Create(MessagePanel[i]);
        SpentTime[i].Visible := true;
        SpentTime[i].AutoSize := false;
        SpentTime[i].Caption := '消耗时间:';
        SpentTime[i].Height := 13;
        SpentTime[i].Width := 63;
        SpentTime[i].Top := 64;
        SpentTime[i].Parent := MessagePanel[i];
        //消耗时间数
        SpentTimeStr[i] := Tlabel.Create(MessagePanel[i]);
        SpentTimeStr[i].Visible := true;
        SpentTimeStr[i].AutoSize := false;
        SpentTimeStr[i].Caption := '';
        SpentTimeStr[i].Height := 13;
        SpentTimeStr[i].Width := 63;
        SpentTimeStr[i].Top := 64;
        SpentTimeStr[i].Parent := MessagePanel[i];
        PageHaveCreated[i] := true;
    end;
    //Show Working Status
    SpiderTabs.ActivePageIndex := 0;
    somain.ShowRunning;
    Self.OnResize(nil);
    Screen.Cursor := crArrow;
end;

procedure Tsomain.m_ResumeClick(Sender: TObject);
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    somain.ShowRunning;
    if (CurrentSiteID > 0) then
    begin
        FlashTrigger.Enabled := true;
        StatusPrintf(Format('继续搜索网站 %d.', [CurrentSiteID]));
    end;
end;

procedure Tsomain.m_pauseClick(Sender: TObject);
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    somain.ShowRunning;
    if (CurrentSiteID > 0) then
    begin
        FlashTrigger.Enabled := false;
        StatusPrintf('正在暂停,请稍候..');
    end;
end;

procedure Tsomain.FormResize(Sender: TObject);
var i               : integer;
begin
    if Application.Terminated then
    begin
        Exit;
    end;

    Screen.Cursor := crHourGlass;

    divx := Width - 648;
    divy := Height - 484;

    SpiderTabs.Top := MainToolBar.Top + MainToolBar.Height;
    SpiderTabs.Left := 0;
    SpiderTabs.Width := ClientWidth;
    SpiderTabs.Height := 257;

    StatusWin.Top := SpiderTabs.Top + SpiderTabs.Height;
    StatusWin.Left := SpiderTabs.Left;
    StatusWin.Width := ClientWidth;
    StatusWin.Height := ClientHeight - SpiderTabs.Height - (mStatus.Height +
        MainToolBar.Height);

    //SiteList
    TotalSiteInfo.Top := SpiderTabs.Top;
    TotalSiteInfo.Left := SpiderTabs.Left;
    TotalSiteInfo.Width := SpiderTabs.Width;
    TotalSiteInfo.Height := 60;

    SiteListView.Top := TotalSiteInfo.Top + TotalSiteInfo.Height;
    SiteListView.Left := TotalSiteInfo.Left;
    SiteListView.Height := ClientHeight - TotalSiteInfo.Height - (mStatus.Height
        + MainToolBar.Height);
    SiteListView.Width := ClientWidth;
    SiteListView.Columns[1].Width := SiteListView.Width -
        SiteListView.Columns[0].Width - SiteListView.Columns[2].Width -
        (SiteListView.Columns[3].Width * 2);

    WaitWindow.Top := SiteListView.Top + ((SiteListView.Height -
        WaitWindow.Height) div 2);
    WaitWindow.Left := SiteListView.Left + ((SiteListView.Width -
        WaitWindow.Width) div 2);

    //TotalSite
    TotalSiteGroup.Width := TotalSiteInfo.Width - TotalSiteGroup.Left -
        ((TotalSiteInfo.Height - TotalSiteGroup.Height) div 2);
    SitePerPage.Left := TotalSiteGroup.Width
        - SitePerPage.Width
        - SitePerPage_Ticket.Width
        - CurrentSitePage.Width
        - CurrentSitePage_Ticket.Width;
    CurrentSitePage.Left := TotalSiteGroup.Width
        - CurrentSitePage.Width
        - CurrentSitePage_Ticket.Width
        + CurrentSitePage.Height;

    SitePerPage_Ticket.Left := SitePerPage.Left - SitePerPage_Ticket.Width;
    CurrentSitePage_Ticket.Left := CurrentSitePage.Left -
        CurrentSitePage_Ticket.Width;

    //绘制状态栏
    mStatus.Panels[2].Width := 130 + (divx div 2);
    mStatus.Panels[1].Width := 250 + (divx div 2);
    BuffreProgressBar.Width := 129 + (divx div 2);
    BuffreProgressBar.Left := 306 + (divx div 2);
    logo.Left := 440 + divx;

    for i := 0 to MaxThreadNum - 1 do
    begin
        if PageHaveCreated[i] then
        begin
            CurrentPage[i].Align := alTop;
            StaticsInfo[i].width := CurrentPage[i].Width;
            MessagePanel[i].width := CurrentPage[i].Width;

            SpiderUrl[i].Width := 422 + divx;
            Inprocess[i].Left := 473 + divx;
            HasProcessed[i].Left := 553 + divx;

            OfDomainStr[i].Width := 547 + divx;
            ImportantMsgStr[i].Width := OfDomainStr[i].Width;

            ParseProgressbar[i].Width := 238 + (divx div 2);
            WriteProgressbar[i].Width := ParseProgressbar[i].Width;

            SplitInfo[i].Left := 317 + (divx div 2);
            SplitInfobar[i].Left := 374 + (divx div 2);
            SplitInfobar[i].Width := ParseProgressbar[i].Width;

            SpentTime[i].Left := SplitInfo[i].Left;
            SpentTimeStr[i].Left := SplitInfobar[i].Left;
        end;
    end;

    Screen.Cursor := crArrow;
end;

procedure Tsomain.m_oneClick(Sender: TObject);
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    //如果有蜘蛛正在运行且搜索暂停,说明上次命令尚未完成
    if (Sender <> nil) and (Sender is TMenuItem) then
    begin
        ModifyThreadNum.Tag := (Sender as TMenuItem).Tag;
        ModifyThreadNum.Enabled := True;
    end;

    somain.ShowRunning;
end;

procedure Tsomain.FlashUITimer(Sender: TObject);
begin
    PostMessage(Self.Handle, FlashUIMessage, 0, 0);
end;

procedure Tsomain.m_authorClick(Sender: TObject);
begin
    ShowModalWindow(Uindexcopyright);
end;

procedure Tsomain.ShellOpen(obj: string);
begin
    ShellExecute(handle, 'open', Pchar(obj), nil, nil, SW_SHOW);
end;

procedure Tsomain.m_homepageClick(Sender: TObject);
begin
    ShellOpen(SiteUrlStr);
end;

procedure Tsomain.m_bbsClick(Sender: TObject);
begin
    ShellOpen(BbsPageUrl);
end;

procedure Tsomain.m_faqClick(Sender: TObject);
begin
    ShellOpen(UpdatePageUrl);
end;

procedure Tsomain.m_contentClick(Sender: TObject);
begin
    ShellOpen(Application.HelpFile);
end;

procedure Tsomain.m_resetStatusClick(Sender: TObject);
begin
    case
        Application.MessageBox(PChar('确定要将所有的网站设置为准备搜索状态吗?'),
        PChar('重置网站状态'), MB_ICONQUESTION or MB_YESNO) of
        IDYES:
            ExecuteSQL('Update UindexWeb_Entry Set SEStatus=0');
        IDNO: ;
    end;
end;

procedure Tsomain.TprintClick(Sender: TObject);
var Root, Entry, BadWords, JumpUrl: string;
    OutXML          : TStringList;
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    somain.ShowRunning;
    StatusPrintf('//-------------------------------------------------------------------');
    StatusPrintf('//               ' + CopyRightStr + '收录网站列表');
    StatusPrintf('//打印时间:' + DateTimeToStr(Now));
    StatusPrintf('//程序实现:曾俊');
    StatusPrintf('//-------------------------------------------------------------------');

    OutXML := TStringList.Create;
    try
        SemaphoreAcquire(DBtoken);
        adolink.Close;
        adolink.SQL.Clear;
        adolink.SQL.Add('Select SEId,SERoot,SEEntryPoint,SEBadwords,SEForbiden From UindexWeb_Entry Order By SEId');
        adolink.Open;
        OutXML.Add('<?xml version="1.0" encoding="GB2312" ?>');
        OutXML.Add('<!--打印时间:' + DateTimeToStr(Now) + '-->');
        OutXML.Add('<!--程序实现:曾俊-->');
        OutXML.Add('<!--注意:这里的元素名使用的一律是英语半角字母-->');
        OutXML.Add('<UindexWeb>');
        while (not adolink.EOF) and (not Application.Terminated) do
        begin
            OutXML.Add('  <WebSite>');
            if IsValidVarString(adolink.Recordset.Fields[1].Value) then
                Root := adolink.Recordset.Fields[1].Value
            else
                Root := '';
            if IsValidVarString(adolink.Recordset.Fields[2].Value) then
                Entry := adolink.Recordset.Fields[2].Value
            else
                Entry := '';

            if IsValidVarString(adolink.Recordset.Fields[3].Value) then
            begin
                BadWords := adolink.Recordset.Fields[3].Value;
                StringReplaceEx(BadWords, #13 + #10, '+');
            end else
                BadWords := '';

            if IsValidVarString(adolink.Recordset.Fields[4].Value) then
            begin
                JumpUrl := adolink.Recordset.Fields[4].Value;
                StringReplaceEx(JumpUrl, #13 + #10, '+');
            end else
                JumpUrl := '';

            StatusPrintf('网站:' + Root + '入口:' + Entry);
            OutXML.Add('	  <Root>' + Root + '</Root>');
            OutXML.Add('	  <EntryPoint>' + Entry + '</EntryPoint>');
            OutXML.Add('	  <BadWords>' + BadWords + '</BadWords>');
            OutXML.Add('	  <JumpUrl>' + JumpUrl + '</JumpUrl>');
            OutXML.Add('  </WebSite>');
            adolink.Next;
        end;
        adolink.SQL.Clear;
        adolink.Close;
        SemaphoreRelease(DBtoken);
        OutXML.Add('</UindexWeb>');
        if IODialog.Execute then
            OutXML.SaveToFile(IODialog.FileName);
    finally
        OutXML.Free;
    end;
end;

procedure Tsomain.m_addnewClick(Sender: TObject);
begin
    WebSite.SiteID.Caption := '0';
    WebSite.FreshUI;
    ShowModalWindow(WebSite);

    SitePerPageChange(Sender);
end;

procedure Tsomain.m_configClick(Sender: TObject);
begin
    ShowModalWindow(ConfigWeb);
end;

procedure Tsomain.SiteManagerMenuClick(Sender: TObject);
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    //Update Total Page
    UpdateTotalPageInDB();
    somain.ShowRunning(not SpiderTabs.Visible);

    if ((somain.SiteListView.Items.Count <>
        StringToIntDef(somain.SitePerPage.Text, 100)) or FlashTrigger.Enabled)
        then
    begin
        SitePerPageChange(Sender);
    end;
end;

procedure Tsomain.DrawSiteList;
var listgroup       : integer;
    listroot, liststatus: string;
    ListItem        : TListItem;
    Fprogress       : Cardinal;
    FSitePerPage    : Cardinal;
    FCurrentPage    : Cardinal;
begin
    if SpiderTabs.Visible then
    begin
        Exit;
    end;

    //WaitWindow
    if (not WaitWindow.Visible) then
    begin
        somain.SiteListView.Clear;
        somain.SiteListView.Realign;
        somain.SiteListView.Repaint;
        WaitWindow.Visible := true;
        Application.ProcessMessages;
        {}
        EnterUiLock(False);

        FSitePerPage := StringToIntDef(somain.SitePerPage.Text, 100);
        FCurrentPage := StringToIntDef(somain.CurrentSitePage.Text, 1);
        Fprogress := 0;
        WaitMessage.Caption := Format('%s (%d)', ['正在填充网站列表...',
            Fprogress]);
        WaitProgress.Max := FSitePerPage;
        WaitProgress.Position := Fprogress;

        DebugPrintf(Format('CFillSiteList.ReadmStatus(FSitePerPage=%d,FCurrentPage=%d)', [FSitePerPage, FCurrentPage]));

        SemaphoreAcquire(DBtoken);
        adolink.Close;
        adolink.SQL.Clear;
        adolink.SQL.Add('Select Top ' + IntToStr(FSitePerPage * FCurrentPage) +
            ' SEId,SERoot,SEGroup,SEStatus From UindexWeb_Entry Order By SEId');

        adolink.Open;
        if (Cardinal(adolink.RecordCount) = (FSitePerPage * FCurrentPage))
            or (Cardinal(adolink.RecordCount) <= (0)) then
        begin
            adolink.SQL.Text :=
                Format('SELECT Top %d SEId,SERoot,SEGroup,SEStatus FROM (%s)a order by SEId Desc', [FSitePerPage, Trim(adolink.SQL.Text)]);
        end else
        begin
            adolink.SQL.Text :=
                Format('SELECT Top %d SEId,SERoot,SEGroup,SEStatus FROM (%s)b order by SEId Desc', [(Cardinal(adolink.RecordCount) mod FSitePerPage), Trim(adolink.SQL.Text)]);
        end;
        adolink.Close;

        adolink.SQL.Text :=
            Format('SELECT SEId,SERoot,SEGroup,SEStatus FROM (%s)c order by SEId',
            [Trim(adolink.SQL.Text)]);
        adolink.Open;
        while (not adolink.EOF) and (not Application.Terminated) do
        begin
            if IsValidVarString(adolink.Recordset.Fields[1].Value) then
                listroot := adolink.Recordset.Fields[1].Value
            else
                listroot := '';

            if VarIsOrdinal(adolink.Recordset.Fields[2].Value) then
                listgroup := adolink.Recordset.Fields[2].Value
            else
                listgroup := 0;

            if not VarIsOrdinal(adolink.Recordset.Fields[3].Value) then
                liststatus := '未定'
            else begin
                case adolink.Recordset.Fields[3].Value of
                    0: liststatus := '准备';
                    1: liststatus := '运行中';
                    2: liststatus := '完成';
                else liststatus := '未定';
                end;
            end;

            ListItem := somain.SiteListView.Items.Add;
            ListItem.Caption := IntToStr(adolink.Recordset.Fields[0].Value);

            Inc(Fprogress);
            WaitMessage.Caption := Format('%s (%d)', ['正在填充网站列表...',
                Fprogress]);
            WaitProgress.Position := Fprogress;

            ListItem.SubItems.Add(listroot);
            ListItem.SubItems.Add(IntToStr(listgroup));
            ListItem.SubItems.Add(liststatus);
            adolink.Next;
        end;

        adolink.SQL.Clear;
        adolink.Close;
        SemaphoreRelease(DBtoken);

        with somain do
        begin
            SiteListView.Realign;
            WaitWindow.Visible := false;
            EnterUiLock(True);
        end;
    end else
        StatusPrintf('已经有一个线程正在执行命令.');
end;

procedure Tsomain.setreadyClick(Sender: TObject);
var i, Scnt, IntStatus: integer;
    S               : string;
begin
    screen.Cursor := crHourGlass;
    S := '';
    Scnt := 0;
    if (Sender <> nil) and ((Sender as TMenuItem).Tag > -1) then
        IntStatus := (Sender as TMenuItem).Tag
    else
        IntStatus := 0;
    for i := 0 to SiteListView.Items.Count - 1 do
    begin
        if SiteListView.Items[i].Selected then
        begin
            setsitestatus(SiteListView.Items[i].Caption, IntStatus);
            if Scnt < 100 then
                S := S + SiteListView.Items[i].Caption + '号,';
            inc(Scnt);
        end;
    end;
    screen.Cursor := crArrow;
    Application.MessageBox(PChar('下列网站被设置为' + (Sender as TMenuItem).Hint
        + ':' + #13 + S + #13 + #13 + '共将 ' + IntToStr(Scnt) + ' 个网站设置为'
        +
        (Sender as TMenuItem).Hint + '.'), PChar('设置完成'), MB_ICONINFORMATION
        or
        MB_OK);

    DrawSiteList;
end;

procedure Tsomain.setsitestatus(idstr: string; status: integer);
begin
    if (idstr <> '') and (status > -1) then
        ExecuteSQL(Format('Update UindexWeb_Entry Set SEStatus=%d Where SEId=%s',
            [status, idstr]));
end;

procedure Tsomain.popsearchselectedClick(Sender: TObject);
var i               : integer;
begin
    if WaitSiteList.Count > 0 then
        case
            Application.MessageBox(PChar('上次的搜索任务尚未完成,"是" 全新搜索,"否" 增量搜索吗?'), PChar('全新搜索?'), MB_ICONQUESTION or MB_YESNOCANCEL) of
            IDYES: WaitSiteList.Clear;
            IDNO: ;
            IDCANCEL: exit;
        end;

    screen.Cursor := crHourGlass;
    TaskNew.SiteSelectPage.ActivePageIndex := 1;
    TaskNew.ServerList.ClearSelection;
    for i := 0 to SiteListView.Items.Count - 1 do
    begin
        if SiteListView.Items[i].Selected and
            (WaitSiteList.IndexOf(SiteListView.Items[i].Caption) < 0) then
            WaitSiteList.Add(SiteListView.Items[i].Caption);
    end;
    screen.Cursor := crArrow;

    TaskNew.freshcheck;
    ShowModalWindow(TaskNew);
end;

procedure Tsomain.GroupSearchClick(Sender: TObject);
var i               : integer;
begin
    if WaitSiteList.Count > 0 then
        case
            Application.MessageBox(PChar('上次的搜索任务尚未完成,"是" 全新搜索,"否" 增量搜索吗?'), PChar('全新搜索?'), MB_ICONQUESTION or MB_YESNOCANCEL) of
            IDYES: WaitSiteList.Clear;
            IDNO: ;
            IDCANCEL: exit;
        end;

    screen.Cursor := crHourGlass;
    TaskNew.SiteSelectPage.ActivePageIndex := 0;
    TaskNew.ServerList.ClearSelection;
    for i := 0 to SiteListView.Items.Count - 1 do
    begin
        if SiteListView.Items[i].Selected then
        begin
            TaskNew.ListView1.ClearSelection;
            TaskNew.ListView1.Items[StringToIntDef(SiteListView.Items[i].SubItems[1], -1)].Selected := True;
            Break;
        end;
    end;
    screen.Cursor := crArrow;

    ShowModalWindow(TaskNew);
end;

procedure Tsomain.ModifyThreadNumTimer(Sender: TObject);
begin
    PostMessage(Self.Handle, ModifyThreadNumMessage, 0, 0);
end;

procedure Tsomain.popdelsearchClick(Sender: TObject);
var i, Scnt         : integer;
    S               : string;
begin
    screen.Cursor := crHourGlass;
    S := '';
    Scnt := 0;
    for i := 0 to SiteListView.Items.Count - 1 do
    begin
        if SiteListView.Items[i].Selected then
        begin
            if (Sender as TMenuItem).Tag = 1 then
            begin
                ExecuteSQL('Delete From UindexWeb_FileList Where FLSiteId=' +
                    SiteListView.Items[i].Caption);
                ExecuteSQL('Delete From UindexWeb_WebUrl Where WUSiteId=' +
                    SiteListView.Items[i].Caption);
            end else if (Sender as TMenuItem).Tag = 2 then
            begin
                ExecuteSQL('Delete From UindexWeb_Entry Where SEId=' +
                    SiteListView.Items[i].Caption);
                DiscardSite(StringToIntDef(SiteListView.Items[i].Caption));
            end else
                ExecuteSQL('Delete From UindexWeb_WebPage Where WPSiteId=' +
                    SiteListView.Items[i].Caption);
            if Scnt < 100 then
                S := S + SiteListView.Items[i].Caption + '号,';
            inc(Scnt);
        end;
    end;
    Application.MessageBox(PChar('下列网站的' + (Sender as TMenuItem).Hint +
        '被删除:' + #13 + S + #13 + #13 + '共将 ' + IntToStr(Scnt) + ' 个网站的'
        +
        (Sender as TMenuItem).Hint + '删除.'), PChar('清理完成'),
        MB_ICONINFORMATION
        or MB_OK);
    screen.Cursor := crArrow;

    if (Sender as TMenuItem).Tag = 2 then
        SitePerPageChange(Sender);
end;

procedure Tsomain.DiscardSite(siteid: integer);
//------------------------------------------------------------------------------
//  这里操作数据库多了点
//------------------------------------------------------------------------------
begin
    ExecuteSQL(Format('Delete From UindexWeb_WebUrl Where WUSiteId=%d',
        [siteid]));
    ExecuteSQL(Format('Delete From UindexWeb_FileList Where FLSiteId=%d',
        [siteid]));
    ExecuteSQL(Format('Delete From UindexWeb_WebPage Where WPSiteId=%d',
        [siteid]));
end;

procedure Tsomain.popgroupsiteClick(Sender: TObject);
var i, Scnt         : integer;
    S               : string;
begin
    screen.Cursor := crHourGlass;
    S := '';
    Scnt := 0;
    for i := 0 to SiteListView.Items.Count - 1 do
    begin
        if SiteListView.Items[i].Selected then
        begin
            ExecuteSQL('Update UindexWeb_Entry Set SEGroup=' + IntToStr((Sender
                as TMenuItem).Tag) + ' Where SEId=' +
                SiteListView.Items[i].Caption);
            if Scnt < 100 then
                S := S + SiteListView.Items[i].Caption + '号,';
            inc(Scnt);
        end;
    end;
    Application.MessageBox(PChar('下列网站被分到 ' + (Sender as TMenuItem).Hint
        +
        '(' + IntToStr((Sender as TMenuItem).Tag) + '组) 组:' + #13 + S + #13 +
        #13 +
        '共将 ' + IntToStr(Scnt) + ' 个网站分到第 ' + IntToStr((Sender as
        TMenuItem).Tag) + ' 组.'), PChar('分组完成'), MB_ICONINFORMATION or
        MB_OK);
    screen.Cursor := crArrow;

    DrawSiteList;
end;

procedure Tsomain.SiteListViewDblClick(Sender: TObject);
var i               : integer;
    HaveFoundSelected: boolean;
    FindSite        : string;
begin
    HaveFoundSelected := false;
    for i := 0 to SiteListView.Items.Count - 1 do
    begin
        if SiteListView.Items[i].Selected and (not HaveFoundSelected) then
        begin
            FindSite := SiteListView.Items[i].Caption;
            HaveFoundSelected := true;
        end;
    end;
    if HaveFoundSelected then
    begin
        WebSite.SiteID.Caption := FindSite;
        WebSite.FreshUI;
        ShowModalWindow(WebSite);
    end;

    DrawSiteList;
end;

procedure Tsomain.FormDestroy(Sender: TObject);
var i               : integer;
    CHM             : HWnd;
begin
    try
        FlashTrigger.Enabled := false;
        FlashUI.Enabled := false;
        ModifyThreadNum.Enabled := false;
        CountSecond.Enabled := false;

        //----------------------------------------------------------------------
        //  释放常规资源
        //----------------------------------------------------------------------
        CHM := FindWindow(nil, 'Uindex使用帮助');
        if (CHM <> 0) then
        begin
            SendMessage(CHM, WM_CLOSE, 0, 0);
        end;
        for i := 0 to ThreadNum - 1 do
        begin
            SpiderList[i].Terminate;
            //Sleep(50);
            application.ProcessMessages;
        end;
        CSpilterList.Free;
        DomainExt.Free;
        binExtList.Free;
        TextExtList.Free;
        ImgExtList.Free;
        MovieExtList.Free;
        PreCSWList.Free;
        SpiderNameList.Free;
        //地址记录
        SiteUrlList.Free;
        EmbedFileList.Free;
        ClipList.Free;
        WaitSiteList.Free;
        CurrentForbidenUrlList.Free;
        CurrentBadWordList.Free;
        SystemBadWordList.Free;
        SystemForbidenUrlList.Free;
        //释放数据库资源
        try
            adolink.Close;
            adolink.Free;
        except
        end;

        CloseHandle(DBtoken);
        CloseHandle(URLtoken);
        CloseHandle(FILEtoken);
        CloseHandle(CLIPtoken);
        CloseHandle(CSWtoken);
    except
    end;
end;

procedure Tsomain.IndexWebClick(Sender: TObject);
begin
    ShowModalWindow(SearchTST);
end;

procedure Tsomain.m_ExitEngineClick(Sender: TObject);
var op              : integer;
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    if (Sender <> nil) and (Sender is TMenuItem) then
    begin
        somain.ShowRunning;
        op := (Sender as TMenuItem).Tag;
        if op = 0 then
        begin
            if m_ExitEngine.Checked then
            begin
                m_ExitEngine.Checked := false;
                exit;
            end;
            m_autoshutdown.Checked := false;
            LogOff.Checked := false;
            m_ExitEngine.Checked := true;
            StatusPrintf('设置为 ' + (Sender as TMenuItem).Hint + '.');
            Application.MessageBox(PChar('设置为 ' + (Sender as TMenuItem).Hint
                +
                '.'), PChar(ShortCopyRight), MB_ICONINFORMATION or MB_OK);
        end else if op = 1 then
        begin
            if LogOff.Checked then
            begin
                LogOff.Checked := false;
                exit;
            end;
            m_autoshutdown.Checked := false;
            m_ExitEngine.Checked := false;
            LogOff.Checked := true;
            StatusPrintf('设置为 ' + (Sender as TMenuItem).Hint + '.');
            Application.MessageBox(PChar('设置为 ' + (Sender as TMenuItem).Hint
                +
                '.'), PChar(ShortCopyRight), MB_ICONINFORMATION or MB_OK);
        end else begin
            if m_autoshutdown.Checked then
            begin
                m_autoshutdown.Checked := false;
                exit;
            end;
            m_ExitEngine.Checked := false;
            LogOff.Checked := false;
            m_autoshutdown.Checked := true;
            StatusPrintf('设置为 ' + (Sender as TMenuItem).Hint + '.');
            Application.MessageBox(PChar('设置为 ' + (Sender as TMenuItem).Hint
                +
                '.'), PChar(ShortCopyRight), MB_ICONINFORMATION or MB_OK);
        end;
    end;
end;

procedure Tsomain.tautoshutdownClick(Sender: TObject);
begin
    m_ExitEngineClick(m_autoshutdown);
end;

procedure Tsomain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    Self.QuitEngineClick(Sender);
    CanClose := False;
end;

procedure Tsomain.ShutDownPc(logoff: boolean);
var
    hdlProcessHandle: Cardinal;
    hdlTokenHandle  : Cardinal;
    tmpLuid         : Int64;
    tkp             : TOKEN_PRIVILEGES;
    tkpNewButIgnored: TOKEN_PRIVILEGES;
    lBufferNeeded   : Cardinal;
    Privilege       : array[0..0] of _LUID_AND_ATTRIBUTES;
begin
    hdlProcessHandle := GetCurrentProcess;
    OpenProcessToken(hdlProcessHandle,
        (TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY),
        hdlTokenHandle);
    // 为关机获得LCID.
    LookupPrivilegeValue('', 'SeShutdownPrivilege', tmpLuid);
    Privilege[0].Luid := tmpLuid;
    Privilege[0].Attributes := SE_PRIVILEGE_ENABLED;
    tkp.PrivilegeCount := 1;            // One privilege to set
    tkp.Privileges[0] := Privilege[0];
    // Enable the shutdown privilege in the access token of this process.
    AdjustTokenPrivileges(hdlTokenHandle,
        False,
        tkp,
        Sizeof(tkpNewButIgnored),
        tkpNewButIgnored,
        lBufferNeeded);
    if logoff then
        ExitWindowsEx((EWX_FORCE or EWX_LOGOFF), $FFFF)
    else
        ExitWindowsEx((EWX_SHUTDOWN or EWX_FORCE or EWX_POWEROFF), $FFFF);
end;

procedure Tsomain.CountSecondTimer(Sender: TObject);
begin
    PostMessage(Self.Handle, CountSecondMessage, 0, 0);
end;

procedure Tsomain.FlashTriggerProc(var Message: TMessage);
//------------------------------------------------------------------------------
//主线程时钟，默认200MS,填写任务，由线程完成
//------------------------------------------------------------------------------
var i, IdleIndex    : integer;
begin
    if Application.Terminated or (not FlashTrigger.Enabled) then
    begin
        Exit;
    end;

    //find if there is an idle thread
    IdleIndex := -1;
    if (WorkingSpider < ThreadNum) then
    begin
        //有闲置,可以处理新网页,首先获得这个编号
        for i := 0 to ThreadNum - 1 do
        begin
            if PageHaveCreated[i] and (not IsThreadRunning(i)) then
            begin
                IdleIndex := i;
                break;
            end;
        end;
    end;
    i := IdleIndex;

    //have an idle thread
    if i >= 0 then
    begin
        if (not ProxyEnable) and (not IsNetWorkValid) then
        begin
            FlashTrigger.Interval := TriggerSlow;
            Exit;
        end else
        begin
            FlashTrigger.Interval := TriggerInterval;
        end;

        //有空闲线程,可以运行
        SpiderUrl[i].Text := GetNextUrl(i);
        if IsThreadRunning(i) then
        begin
            Inprocess[i].Checked := true;
            HasProcessed[i].Checked := false;
            OfDomainStr[i].Caption := CurrentSubRoot;
        end;
    end;
end;

procedure Tsomain.FlashUIProc(var Message: TMessage);
var Ini             : TIniFile;
    BinCnt, TextExt, NameCnt, ImgCnt, MediaCnt, DmCnt, SpCnt, PreCSWCnt, i,
        config_file_age, CFGtn: integer;
    Value           : string;
begin
    if Application.Terminated then
    begin
        Exit;
    end;

    //-------------------------------------------------------------------------
    //注意所有的启动参数都是这个事件读入的
    //-------------------------------------------------------------------------
    if (IsNetWorkValid) then
        mStatus.Panels[1].Text :=
            Format('检索:%d/%d 错误:%d/%d 开始时间:%s 当前时间:%s',
            [ThisHaveIndex,
            ThisSiteMaxPage, PageAccessError, PageErrorPermit,
                DateTimeToStr(SoStartTime), DateTimeToStr(Now)]);

    SemaphoreAcquire(CLIPtoken);
    BuffreProgressBar.Min := 0;
    BuffreProgressBar.Max := ClipList.exceedheap;
    BuffreProgressBar.Position := ClipList.heap;
    SemaphoreRelease(CLIPtoken);

    if WorkingSpider > 0 then
        exit;
    ModifyThreadNum.Enabled := false;
    config_file := ExtractFilePath(Application.ExeName) + 'UindexWeb.INI';
    config_file_age := FileAge(config_file);
    if (config_file_age <> FlashUI.Tag) then
    begin
        FlashUI.Tag := config_file_age;
        Ini := TIniFile.Create(config_file);
        //----------------------------------------------------------------------
        // 读取常规设置
        //----------------------------------------------------------------------
        GlobalDataBase := ini.ReadString('UindexWeb', 'ConnStr',
            GlobalDataBase);
        //----------------------------------------------------------------------
        // 读入数据库中的禁止关键字和禁止搜索URL列表
        //----------------------------------------------------------------------
        Screen.Cursor := crSQLWait;

        SemaphoreAcquire(DBtoken);
        adolink.ConnectionString := GlobalDataBase;
        SemaphoreRelease(DBtoken);

        LoadWordCheck;

        Screen.Cursor := crDefault;

        CFGtn := ini.ReadInteger('UindexWeb', 'SpiderNum', 2);
        if (CFGtn > 0) and (ModifyThreadNum.Tag <> CFGtn) then
            ModifyThreadNum.Tag := CFGtn;
        PageErrorPermit := ini.ReadInteger('UindexWeb', 'DefaultErrorMax', 32);

        TriggerInterval := ini.ReadInteger('UindexWeb', 'TriggerInterval', 200);
        TriggerSlow := ini.ReadInteger('UindexWeb', 'TriggerSlow', 4000);
        if (TriggerSlow <= TriggerInterval) then
        begin
            TriggerSlow := TriggerInterval * 10;
        end;

        //----------------------------------------------------------------------
        //根据配置文件修改版权信息
        //----------------------------------------------------------------------
        configweb.spideragent.Text := ini.ReadString('UindexWeb', 'spideragent',
            'Mozilla/4.0 (compatible; UindexWeb)');
        CopyRightStr := ini.ReadString('CopyRight', 'CopyRight',
            'UindexWeb搜索引擎');
        SiteUrlStr := ini.ReadString('CopyRight', 'SiteUrl', HomePageUrl);
        ShortCopyRight := ini.ReadString('CopyRight', 'ShortCopyRight',
            'UindexWeb');
        SoftVersion := ini.ReadString('CopyRight', 'SoftVersion',
            '(C) 2005-2012');
        Caption := CopyRightStr;
        Application.Title := CopyRightStr;
        ConfigWeb.Caption := '配置' + CopyRightStr;
        TaskNew.mStatus.Panels[1].Text := CopyRightStr +
            '将遍历并记录网页的有效信息。';
        mStatus.Panels[3].Text := CopyRightStr;
        Uindexcopyright.Label3.Caption := CopyRightStr;
        Uindexcopyright.Label5.Caption := SiteUrlStr;
        //基本配置部分
        configweb.DefaultErrorMax.Text := ini.ReadString('UindexWeb',
            'DefaultErrorMax', '32');
        configweb.UrlLenMax.Text := ini.ReadString('UindexWeb', 'UrlLenMax',
            '256');
        configweb.PageProcessMax.Text := ini.ReadString('UindexWeb',
            'PageProcessMax', '60000');
        configweb.ClipBufferMax.Text := ini.ReadString('UindexWeb',
            'ClipBufferMax', '512');
        configweb.SiteAllOpen.Checked := ini.ReadBool('UindexWeb',
            'SiteAllOpen', false);
        //菜单上的项目
        LimitCPURate.checked := ini.ReadBool('UindexWeb', 'LimitCPURate', true);
        AutoClearMessage.checked := ini.ReadBool('UindexWeb',
            'AutoClearMessage', true);
        configweb.MaxIndexPage.Text := ini.ReadString('UindexWeb',
            'MaxIndexPage', '256');

        configweb.SiteInnerOpen.Enabled := not configweb.SiteAllOpen.Checked;
        UpdateAntiDuplicat;
        configweb.PageMaxLen.Text := ini.ReadString('UindexWeb', 'PageMaxLen',
            '327679');
        m_autoshutdown.Checked := ini.ReadBool('UindexWeb',
            'shutdownwhencomplete', false);
        configweb.SiteInnerOpen.Checked := ini.ReadBool('UindexWeb',
            'SiteInnerOpen', true);
        configweb.KeepTmp.Checked := ini.ReadBool('UindexWeb', 'KeepTemp',
            true);
        configweb.DiscardTmp.Checked := ini.ReadBool('UindexWeb', 'DiscardTmp',
            false);
        configweb.SubDomainDeepth.Value := ini.ReadInteger('UindexWeb',
            'SubDomainDeepth', 0);
        configweb.IgnoreEmbedJs.Checked := ini.ReadBool('UindexWeb',
            'IgnoreEmbedJs', true);
        configweb.Cfreshui.Checked := ini.ReadBool('UindexWeb', 'Cfreshui',
            true);
        configweb.CshowFindLink.Checked := ini.ReadBool('UindexWeb',
            'CshowFindLink', false);
        configweb.OutputSystemDebug.Checked := ini.ReadBool('UindexWeb',
            'OutputSystemDebug', false);
        OutPutDebug := configweb.OutputSystemDebug.Checked;
        configweb.CheckBadWord.Checked := ini.ReadBool('UindexWeb',
            'CheckBadWord', True);
        configweb.SkipBadPage.Checked := ini.ReadBool('UindexWeb',
            'SkipBadPage', false);

        if configweb.SkipBadPage.Checked then
        begin
            configweb.CheckBadWord.Enabled := False;
        end;
        configweb.UseComplexAlgr.Checked := ini.ReadBool('UindexWeb',
            'UseComplexAlgr', true);
        configweb.NeedNoCount.Checked := ini.ReadBool('UindexWeb',
            'NeedNoCount', false);
        //----------------------------------------------------------------------
        // 定义蜘蛛名称
        //----------------------------------------------------------------------
        NameCnt := Ini.ReadInteger('nickname', 'nickname', 0);
        if NameCnt > 0 then
        begin
            SpiderNameList.Clear;
            for i := 1 to NameCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('nickname', 'nickname' +
                    IntToStr(i), '贝贝'));

                if (Value <> '') then
                begin
                    SpiderNameList.Add(Value);
                end;
            end;
            //比如只有9个,那就补齐到 MaxThreadNum
            while SpiderNameList.Count < MaxThreadNum do begin
                SpiderNameList.Add(Format('线程%d', [SpiderNameList.Count +
                    1]));
            end;
        end else begin
            SpiderNameList.Clear;
            for i := 1 to MaxThreadNum do
            begin
                SpiderNameList.Add(Format('线程%d', [i]));
            end;
        end;
        //----------------------------------------------------------------------
        // 处理二进制类型
        //----------------------------------------------------------------------
        BinCnt := Ini.ReadInteger('binext', 'binext', 0);
        if BinCnt > 0 then
        begin
            binExtList.Clear;
            for i := 1 to BinCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('binext', 'binext' +
                    IntToStr(i), 'exe'));

                if (Value <> '') then
                begin
                    binExtList.Add(Value);
                end;
            end;
        end;
        //----------------------------------------------------------------------
        // 处理文本类型
        //----------------------------------------------------------------------
        TextExt := Ini.ReadInteger('TextExt', 'TextExt', 0);
        if TextExt > 0 then
        begin
            TextExtList.Clear;
            for i := 1 to TextExt do
            begin
                Value := LowAndTrim(Ini.ReadString('TextExt', 'TextExt' +
                    IntToStr(i), 'htm'));

                if (Value <> '') then
                begin
                    TextExtList.Add(Value);
                end;
            end;
        end;
        //----------------------------------------------------------------------
        // 定义图片文件
        //----------------------------------------------------------------------
        ImgCnt := Ini.ReadInteger('ImgExt', 'ImgExt', 0);
        if ImgCnt > 0 then
        begin
            ImgExtList.Clear;
            for i := 1 to ImgCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('ImgExt', 'ImgExt' +
                    IntToStr(i), 'png'));

                if (Value <> '') then
                begin
                    ImgExtList.Add(Value);
                end;
            end;
        end;
        //----------------------------------------------------------------------
        // 定义媒体文件
        //----------------------------------------------------------------------
        MediaCnt := Ini.ReadInteger('MovieExt', 'MovieExt', 0);
        if MediaCnt > 0 then
        begin
            MovieExtList.Clear;
            for i := 1 to MediaCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('MovieExt', 'MovieExt' +
                    IntToStr(i), 'mp3'));

                if (Value <> '') then
                begin
                    MovieExtList.Add(Value);
                end;
            end;
        end;
        //----------------------------------------------------------------------
        // 查询域名可能的后缀
        //----------------------------------------------------------------------
        DmCnt := Ini.ReadInteger('DomainExt', 'DomainExt', 0);
        if DmCnt > 0 then
        begin
            DomainExt.Clear;
            for i := 1 to DmCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('DomainExt', 'DomainExt' +
                    IntToStr(i), 'com'));

                if (Value <> '') then
                begin
                    DomainExt.Add(Value);
                end;
            end;
        end;
        //----------------------------------------------------------------------
        // 获得拆分器使用字符
        //----------------------------------------------------------------------
        SpCnt := Ini.ReadInteger('spliter', 'spliter', 0);
        if SpCnt > 0 then
        begin
            CSpilterList.Clear;
            for i := 1 to SpCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('spliter', 'spliter' +
                    IntToStr(i), '</div>'));

                if (Value <> '') then
                begin
                    CSpilterList.Add(Value);
                end;
            end;
        end;
        //----------------------------------------------------------------------
        // 预分词
        //----------------------------------------------------------------------
        PreCSWCnt := Ini.ReadInteger('PreCSW', 'PreCSW', 0);
        if (PreCSWCnt > 0) then
        begin
            SemaphoreAcquire(CSWtoken);

            PreCSWList.Clear;
            for i := 1 to PreCSWCnt do
            begin
                Value := LowAndTrim(Ini.ReadString('PreCSW', 'PreCSW' +
                    IntToStr(i), '…'));

                if (Value <> '') then
                begin
                    PreCSWList.Add(Value);
                end;
            end;

            SemaphoreRelease(CSWtoken);
        end;
        Ini.Free;
        StatusPrintf('新配置文件生效.');
        StatusPrintf(Format('指定蜘蛛名称%d个,二进制%d,文本%d,域名扩展%d,图片%d,媒体%d', [NameCnt, BinCnt, TextExt, DmCnt, ImgCnt, MediaCnt]));
        if (NCPos('Provider=Microsoft.Jet.OLEDB.4.0', GlobalDataBase) > 0) then
        begin
            StatusPrintf('指定桌面数据库 ' +
                GetDBFileFromConnStr(GlobalDataBase));
            if (not FileExists(GetDBFileFromConnStr(GlobalDataBase))) or
                (not
                SetFileAttributes(PChar(GetDBFileFromConnStr(GlobalDataBase)),
                FILE_ATTRIBUTE_NORMAL))
                then
            begin
                StatusPrintf('指定数据库不存在或无写权限(ENO0003).');
            end;
        end else
        begin
            StatusPrintf('用户选择了使用自定义数据库.');
        end;

        if not FileExists(config_file) then
        begin
            StatusPrintf('配置文件不存在,使用默认参数.');
        end;

        FlashUI.Interval := 500;
        ModifyThreadNum.Interval := 10;
        ModifyThreadNum.Enabled := true;
    end;
end;

procedure Tsomain.ModifyThreadNumProc(var Message: TMessage);
begin
    if Application.Terminated then
    begin
        Exit;
    end;

    if ThreadNum <> ModifyThreadNum.Tag then
    begin
        if (m_pause.Tag = 0) and (WorkingSpider > 0) then
        begin
            //保证只暂停一次,
            m_pauseClick(nil);
            m_pause.Tag := 1;
        end;

        if WorkingSpider = 0 then
        begin
            ThreadNum := ModifyThreadNum.Tag;
            SetThreadNum(ThreadNum);
            ModifyThreadNum.Enabled := False;

            if m_pause.Tag = 1 then
            begin
                m_ResumeClick(nil);
                m_pause.Tag := 0;
            end;
        end;
    end;
end;

procedure Tsomain.CountSecondProc(var Message: TMessage);
begin
    if Application.Terminated then
    begin
        Exit;
    end;

    FlashUI.Enabled := false;
    FlashTrigger.Enabled := false;
    ModifyThreadNum.Enabled := false;
    if (CountSecond.Tag < 60) and (not ConfigWeb.NeedNoCount.Checked) then
    begin
        CountSecond.Tag := CountSecond.Tag + 1;
        mStatus.Panels[1].Text := '正在数秒:' + IntToStr(60 - CountSecond.Tag);
    end else
        ShutDownPc(LogOff.Checked);
end;

procedure Tsomain.LoadWordCheck;
var sql             : string;
begin
    SemaphoreAcquire(DBtoken);

    //开始查询禁止关键字
    adolink.Close;
    adolink.SQL.Clear;
    sql := 'Select BWId,BWString From UindexWeb_BadWord Order By BWId';
    adolink.SQL.Text := sql;
    adolink.Open;

    SystemBadWordList.Clear;
    while (not adolink.EOF) and (not Application.Terminated) do
    begin
        if IsValidVarString(adolink.Recordset.Fields[1].Value) and
            (SystemBadWordList.IndexOf(LowAndTrim(adolink.Recordset.Fields[1].Value))
            < 0) then
            SystemBadWordList.Add(LowAndTrim(adolink.Recordset.Fields[1].Value));
        adolink.Next;
    end;

    adolink.SQL.Clear;
    adolink.Close;
    //开始查询禁止URL列表
    sql := 'Select FBUId,FBUString From UindexWeb_FobidenUrl Order By FBUId';
    adolink.SQL.Text := sql;
    adolink.Open;

    SystemForbidenUrlList.Clear;
    while (not adolink.Eof) and (not Application.Terminated) do
    begin
        if IsValidVarString(adolink.Recordset.Fields[1].Value) and
            (SystemForbidenUrlList.IndexOf(LowAndTrim(adolink.Recordset.Fields[1].Value)) < 0) then
            SystemForbidenUrlList.Add(LowAndTrim(adolink.Recordset.Fields[1].Value));
        adolink.Next;
    end;

    adolink.SQL.Clear;
    adolink.Close;
    SemaphoreRelease(DBtoken);
end;

procedure Tsomain.PrintBadPageClick(Sender: TObject);
var URL, SITEID     : string;
begin
    if not somain.SiteManagerMenu.Enabled then
    begin
        Exit;
    end;

    somain.ShowRunning;
    StatusWin.Clear;
    StatusPrintf('//-------------------------------------------------------------------');
    StatusPrintf('//               ' + ShortCopyRight + '违禁网页列表');
    StatusPrintf('//打印时间:' + DateTimeToStr(Now));
    StatusPrintf('//程序实现:曾俊');
    StatusPrintf('//-------------------------------------------------------------------');
    if ConfigWeb.CheckBadWord.Checked then
        StatusPrintf('违禁内容检查功能: 开启')
    else
        StatusPrintf('违禁内容检查功能: 关闭');

    SemaphoreAcquire(DBtoken);
    adolink.Close;
    adolink.SQL.Clear;
    adolink.SQL.Add('Select WPId,WPUrl,WPSiteId,WPBadWord From UindexWeb_WebPage Where WPBadWord>0 Order By WPId');
    adolink.Open;
    while (not adolink.EOF) and (not Application.Terminated) do
    begin
        if IsValidVarString(adolink.Recordset.Fields[1].Value) then
            URL := adolink.Recordset.Fields[1].Value
        else
            URL := '';
        if VarIsOrdinal(adolink.Recordset.Fields[2].Value) then
            SITEID := IntToStr(adolink.Recordset.Fields[2].Value)
        else
            SITEID := '';
        StatusPrintf('网站:' + SITEID + '号 网页:' + URL);
        adolink.Next;
    end;
    adolink.SQL.Clear;
    adolink.Close;
    SemaphoreRelease(DBtoken);
end;

procedure Tsomain.ImportSiteMenuClick(Sender: TObject);
var SiteList        : TStringList;
    i, added, updated: integer;
    SERoot, SEntry, Sxml, BadWords, JumpUrl: string;
begin
    if IODialog.Execute then
    begin
        added := 0;
        updated := 0;
        StatusPrintf('//-------------------------------------------------------------------');
        StatusPrintf('//               ' + CopyRightStr + ' 网站导入');
        StatusPrintf('//导入时间:' + DateTimeToStr(Now));
        StatusPrintf('//程序实现:曾俊');
        StatusPrintf('//-------------------------------------------------------------------');
        SiteList := TStringList.Create;
        try
            SiteList.LoadFromFile(IODialog.FileName);
            Sxml := SiteList.Text;

            StringReplaceEx(Sxml, #10, '', [rfReplaceAll]);
            StringReplaceEx(Sxml, #13, '', [rfReplaceAll]);
            StringReplaceEx(Sxml, '< ', '<', [rfReplaceAll]);
            StringReplaceEx(Sxml, ' >', '>', [rfReplaceAll]);
            StringReplaceEx(Sxml, #13 + #10, '', [rfReplaceAll]);
            StringReplaceEx(Sxml, '<website>', #13 + #10, [rfReplaceAll,
                rfIgnoreCase]);
            StringReplaceEx(Sxml, '</website>', #13 + #10, [rfReplaceAll,
                rfIgnoreCase]);

            SiteList.Text := Sxml;
            for i := 0 to SiteList.Count - 1 do
            begin
                if NCPos('<root>', SiteList[i]) > 0 then
                begin
                    SERoot := GetXmlKey(SiteList[i], 'root');
                    SEntry := GetXmlKey(SiteList[i], 'entrypoint');

                    BadWords := SqlFitness(GetXmlKey(SiteList[i], 'BadWords'));
                    StringReplaceEx(BadWords, '+', #13 + #10);

                    JumpUrl := SqlFitness(GetXmlKey(SiteList[i], 'JumpUrl'));
                    StringReplaceEx(JumpUrl, '+', #13 + #10);

                    if (SERoot <> '') and (Length(SEntry) > 3) then
                    begin
                        if not
                            ExecuteSQL('Insert Into UindexWeb_Entry(SERoot,SEEntryPoint,SEGroup,SEBadwords,SEForbiden) Values('''
                            + SERoot + ''',''' + SEntry + ''',0,''' +
                            SetDefaultSqlStr(BadWords) + ''',''' +
                            SetDefaultSqlStr(JumpUrl) + ''')') then
                        begin
                            StatusPrintf('更新网站 ' + SERoot + ' 入口 ' +
                                SEntry);
                            inc(updated);
                            ExecuteSQL('Update UindexWeb_Entry Set SEEntryPoint='''
                                + SEntry + ''',SEBadwords=''' +
                                SetDefaultSqlStr(BadWords) + ''',SEForbiden='''
                                +
                                SetDefaultSqlStr(JumpUrl) + ''' Where SERoot='''
                                +
                                SERoot + '''');
                        end else begin
                            inc(added);
                            StatusPrintf('添加网站 ' + SERoot + ' 入口 ' +
                                SEntry);
                        end;
                    end;
                end;
            end;
        finally
            SiteList.Free;
        end;
        Application.MessageBox(PChar('网站导入完成,添加网站 ' + IntToStr(added)
            +
            ' 个,更新网站 ' + intToStr(updated) + ' 个.'),
            PChar(ShortCopyRight),
            MB_ICONINFORMATION or MB_OK);
    end;
end;

function Tsomain.GetXmlKey(XmlLine, Key: string): string;
var keypos, keyend  : integer;
begin
    keypos := NCpos('<' + Key + '>', XmlLine);
    keyend := NCpos('</' + Key + '>', XmlLine);
    result := copy(XmlLine, keypos + Length(Key) + 2, ((keyend - keypos) -
        (Length(Key) + 2)));
end;

procedure Tsomain.StatusPrintf(msg: string);
begin
    if AutoClearMessage.Checked and (StatusWin.Lines.Count > 1000) then
        StatusWin.Lines.Clear;

    StatusWin.Lines.Add(msg);

    DebugPrintf(msg);
end;

function Tsomain.IsSpiderRunning: boolean;
begin
    Result := (FlashTrigger.Enabled or (WorkingSpider > 0));
end;

procedure Tsomain.ThreadComplete(Sender: TObject);
var spiderid        : integer;
    TName           : string;
begin
    //-------------------------------------------------------------------------
    //注意:外面的ado连接写入时不需要令牌
    //-------------------------------------------------------------------------
    if (Sender <> nil) and (Sender is CSpider) then
    begin
        spiderid := (Sender as CSpider).SpiderID;
        TName := (Sender as CSpider).SpiderName;
        //对于无法访问的网页减少检索计数且增加无法访问计数
        inc(AllSearched);
        if (Sender as CSpider).IsAccessError then
        begin
            dec(ThisHaveIndex);
            dec(AllSearched);
            inc(PageAccessError);
        end;
        //对于跳过的网页只减少检索计数
        if (Sender as CSpider).IsSkipedPage then
        begin
            dec(ThisHaveIndex);
            dec(AllSearched);
        end;

        if (spiderid >= 0) and (spiderid <= ThreadNum) then
        begin
            HasProcessed[spiderid].Checked := true;
            inprocess[spiderid].Checked := false;
            SpiderUrl[spiderid].Text := '';
        end;

        //Update Total Page
        UpdateTotalPageInDB();
    end;
end;

procedure Tsomain.ExitApplication(action: boolean);
begin
    if action then
    begin
        Screen.Cursor := crHourGlass;
        somain.SiteListView.Clear;
        Screen.Cursor := crArrow;
        Application.Terminate;
    end;
end;

procedure Tsomain.MenuResetClick(Sender: TObject);
begin
    if (Sender is TMenuItem) then
    begin
        (Sender as TMenuItem).Checked := not (Sender as TMenuItem).Checked;
    end;
end;

procedure Tsomain.m_cleanClick(Sender: TObject);
begin
    case Application.MessageBox(PChar('点击确定删除所有的搜索结果?'),
        PChar('删除搜索结果'), MB_ICONQUESTION or MB_YESNO) of
        IDYES: begin
                ExecuteSQL('Delete From UindexWeb_WebPage');
                ExecuteSQL('Delete From UindexWeb_FileList');
                ExecuteSQL('Delete From UindexWeb_WebUrl');
            end;
        IDNO: ;
    end;
end;

procedure Tsomain.UindexWebException(Sender: TObject; E: Exception);
begin
    ReportBug.BugContents.Clear;

    ReportBug.BugContents.Lines.Add('程序：' + CopyRightStr);
    ReportBug.BugContents.Lines.Add('版本：' + SoftVersion);
    ReportBug.BugContents.Lines.Add('连接：' + GlobalDataBase);
    ReportBug.BugContents.Lines.Add('线程：' + IntToStr(ThreadNum));
    ReportBug.BugContents.Lines.Add('消息：' + E.Message);
    JclLastExceptStackListToStrings(ReportBug.BugContents.Lines, False, True,
        True, True);
    if ReportBug.BugContents.Lines.Count > 5 then
    begin
        ReportBug.BugContents.Lines[5] := '调用：' +
            ReportBug.BugContents.Lines[5];
    end;

    ShowExceptionDialog();
end;

procedure Tsomain.UindexWebThreadException(const MessageString: string);
begin
    ReportBug.BugContents.Clear;

    ReportBug.BugContents.Lines.Add('程序：' + CopyRightStr);
    ReportBug.BugContents.Lines.Add('版本：' + SoftVersion);
    ReportBug.BugContents.Lines.Add('连接：' + GlobalDataBase);
    ReportBug.BugContents.Lines.Add('线程：' + IntToStr(ThreadNum));
    ReportBug.BugContents.Lines.Add(MessageString);

    ShowExceptionDialog();
end;

procedure Tsomain.ShowExceptionDialog;
var ts              : TStringList;
begin
    ts := TStringList.Create;
    try
        if FileExists(config_file) then
        begin
            ts.LoadFromFile(config_file);
            ReportBug.BugContents.Lines.Add('配置信息：');
            ReportBug.BugContents.Lines.Add(ts.Text);
        end;
    finally
        ts.Free;
    end;

    FlashTrigger.Enabled := False;
    FlashUI.Enabled := False;
    ModifyThreadNum.Enabled := False;
    CountSecond.Enabled := False;

    ShowModalWindow(ReportBug);
    Application.Terminate();
end;

procedure Tsomain.SiteListViewKeyDown(Sender: TObject; var Key: Word;
    Shift: TShiftState);
begin
    if (ssCtrl in Shift) and (Key in [ord('a'), ord('A')]) then
    begin
        SiteListView.SelectAll;
    end;
end;

procedure Tsomain.EnterUiLock(const Lock: boolean);
begin
    with somain do
    begin
        SiteManagerBtn.Enabled := Lock;
        SiteManagerMenu.Enabled := Lock;
        SpiderViewBtn.Enabled := Lock;
        m_StartSearch.Enabled := Lock;
        m_addnew.Enabled := Lock;
        ImportSiteMenu.Enabled := Lock;
        ExportSiteMenu.Enabled := Lock;
        PrintBadPage.Enabled := Lock;
        StartSearch.Enabled := Lock;
        taddsite.Enabled := Lock;
        TestSearch.Enabled := Lock;
        IndexWeb.Enabled := Lock;
        SiteListView.Enabled := Lock;
        m_clean.Enabled := Lock;
        m_resetStatus.Enabled := Lock;
        SitePerPage.Enabled := Lock;
        CurrentSitePage.Enabled := Lock;
    end;

    with TaskNew do
    begin
        UserDefineSite.Enabled := Lock;
        StartSearch.Enabled := Lock;
        ExitWinzard.Enabled := Lock;
    end;

    with WebSite do
    begin
        SaveInfo.Enabled := Lock;
    end;
end;

procedure Tsomain.SitePerPageChange(Sender: TObject);
var i               : Integer;
begin
    if (adolink = nil) then
        Exit;

    SemaphoreAcquire(DBtoken);

    CurrentSitePage.Clear;
    with adolink do
    begin
        Close;
        SQL.Clear;
        SQL.Add('Select SEId,SERoot,SEGroup,SEStatus From UindexWeb_Entry Order By SEId');
        Open;

        for i := 1 to (RecordCount div (StringToIntDef(somain.SitePerPage.Text,
            100)) + 1) do
        begin
            CurrentSitePage.Items.Add(IntToStr(i));
        end;

        SQL.Clear;
        Close;
    end;

    SemaphoreRelease(DBtoken);

    CurrentSitePage.ItemIndex := 0;
    DrawSiteList;
end;

procedure Tsomain.CurrentSitePageChange(Sender: TObject);
begin
    if (adolink = nil) then
        Exit;

    DrawSiteList;
end;

procedure Tsomain.ShowRunning(const Show: Boolean = True);
begin
    SpiderTabs.Visible := Show;
    StatusWin.Visible := SpiderTabs.Visible;

    TotalSiteInfo.Visible := not SpiderTabs.Visible;
    SiteListView.Visible := TotalSiteInfo.Visible;
end;

procedure Tsomain.FormPaint(Sender: TObject);
begin
    mStatus.Realign;
end;

procedure Tsomain.UpdateTotalPageInDB;
begin
    SemaphoreAcquire(DBtoken);
    with adolink do
    begin
        Close;
        SQL.Clear;
        SQL.Add('SELECT count(*) as Total from UindexWeb_WebPage');
        Open;
        if (not Eof) then
        begin
            TotalPageInDB.Text := IntToStr(Recordset.Fields[0].Value);
        end;
        SQL.Clear;
        Close;

        SQL.Clear;
        SQL.Add('SELECT count(*) as Total from UindexWeb_Entry');
        Open;
        if (not Eof) then
        begin
            totalsite.Text := IntToStr(Recordset.Fields[0].Value);
        end;
        SQL.Clear;
        Close;
    end;
    SemaphoreRelease(DBtoken);
end;

procedure Tsomain.CreateSyncObject;
begin
    DBtoken := CreateSemaphore(nil, 1, 1, nil);
    URLtoken := CreateSemaphore(nil, 1, 1, nil);
    FILEtoken := CreateSemaphore(nil, 1, 1, nil);
    CLIPtoken := CreateSemaphore(nil, 1, 1, nil);
    CSWtoken := CreateSemaphore(nil, 1, 1, nil);
end;

procedure Tsomain.ShowModalWindow(Sender: TObject);
begin
    if TaskNew.Visible then
        PostMessage(TaskNew.Handle, WM_CLOSE, 0, 0);
    if Uindexcopyright.Visible then
        PostMessage(Uindexcopyright.Handle, WM_CLOSE, 0, 0);
    if WebSite.Visible then
        PostMessage(WebSite.Handle, WM_CLOSE, 0, 0);
    if ConfigWeb.Visible then
        PostMessage(ConfigWeb.Handle, WM_CLOSE, 0, 0);
    if SearchTST.Visible then
        PostMessage(SearchTST.Handle, WM_CLOSE, 0, 0);
    if ReportBug.Visible then
        PostMessage(ReportBug.Handle, WM_CLOSE, 0, 0);

    while ((Sender as TForm).Visible) do
    begin
        PostMessage((Sender as TForm).Handle, WM_CLOSE, 0, 0);
        Application.ProcessMessages;
    end;

    (Sender as TForm).ShowModal();
end;

initialization

    // Enable raw mode (default mode uses stack frames which aren't always generated by the compiler)
    Include(JclStackTrackingOptions, stRawMode);
    // Disable stack tracking in dynamically loaded modules (it makes stack tracking code a bit faster)
    Include(JclStackTrackingOptions, stStaticModuleList);

    // Initialize Exception tracking
    JclStartExceptionTracking;

finalization

    // Uninitialize Exception tracking
    JclStopExceptionTracking;

end.
