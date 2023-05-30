unit GetThread;

interface

uses
    Classes, StdCtrls, Windows, SysUtils, StrUtils, OverbyteIcsWndControl,
    OverbyteIcsHttpCCodZLib, Math,
    OverbyteIcsHttpProt, HtmlParser, HtmlSplit, DB, ADODB, ActiveX, CoreString,
    ComObj, DateUtils, JclDebug, Forms;

type
    CSpider = class(TJclDebugThread)
    private
        FPageUrl: string;               //网页绝对地址
        WorkingUrl: string;
        Fhtml: string;                  //源代码
        FUrlId: integer;
        FPreviousSize: integer;
        //创建时获得的参数
        FMaxPageProcess: integer;
        FMaxPageLen: integer;
        FLimitCPUn: integer;
        FFreshUI: boolean;
        FShowLink: boolean;
        FIgnoreEmbedJs: boolean;

        FCheckBadWord: boolean;
        FSkipBadPage: boolean;
        FPageForbiden: boolean;
        FUseComplexAlgr: boolean;
        FInnerOpen: boolean;
        FSubDomainDeepth: Integer;
        //动态创建部分
        myGet: THttpCli;
        HtmlParser: CHtmlParser;
        InfoClip: CInformationClip;

        GetStream: TMemoryStream;
        //该页所获得资源的临时存储的地方
        NewFoundUrls: TStringList;
        NewFileUrls: TStringList;
        FExceptionLog: TStringList;
        NewFileComments: TStringList;
        Clips: string;

        //界面元素变量设置部分
        FPageLen: integer;
        UiEventNum: integer;
        UiClipInfo: integer;
        UiImportantmsg: string;
        //3个进度条
        UiParseMin: integer;
        UiParseMax: integer;
        UiParsePos: integer;
        UiClipMin: integer;
        UiClipMax: integer;
        UiClipPos: integer;
        UiWriteMin: integer;
        UiWriteMax: integer;
        UiWritePos: integer;
        NetStartTime: TDateTime;
        downloadspent: integer;
        Fcomplete: boolean;
        //网页基本信息
        Fpagetitle: string;
        FCopyRight: string;
        Fauthor: string;
        Fdeveloptool: string;
        Fkeywords: string;
        Fdiscription: string;
        FWPSignature: string;
        Foncomplete: TNotifyEvent;
        //公共调用过程部分
        procedure AbortCurrentPage();
        procedure PrepareNewTask;
        procedure ReadMainThread;
        procedure ThreadReportBug;
        procedure ThreadReportComplete;
        procedure SendBack;
        procedure SendInfo(Str: string);
        function GetDocType(url: string): integer;
        function IsSiteInner(url: string): boolean;
        function CheckUrlForbiden(url: string): boolean;
        function CheckWordForbiden(const content: string): boolean;
        procedure GetCommonInfo();

        procedure AddUrl(url, title: string);
        procedure AddClip(clip: string);
        procedure AddNewFUrl(Link: string);
        procedure AddNewFile(FUrl, FComment: string);
        //写入数据库部分
        procedure preparesave;
        procedure SaveLink;
        procedure SaveImage;
        procedure SavePage;
        //下载和网页预处理部分
        procedure PreCSW(var input: string);
        procedure HttpCliDocBegin(Sender: TObject);
        procedure HttpCliDocEnd(Sender: TObject);
        procedure HttpCliSocksError(Sender: TObject; Error: Integer; Msg:
            string);
        procedure HttpCliStateChange(Sender: TObject);
        procedure HttpCliRequestDone(Sender: TObject; RqType: THttpRequest;
            ErrCode: Word);
        procedure HttpCliDocData(Sender: TObject; Buffer: Pointer; Len:
            Integer);
        procedure FreeStream();
        //字符串消息函数
        procedure CommonMessage(msg: string);
        //界面刷新函数
        procedure sentimportant();
        procedure UpdateWriteProgress();
        procedure SentWriteProgress();
        procedure ParseComplete();
        procedure SentParseComplete();
        procedure SplitComplete();
        procedure SentSplitComplete();
        procedure ParseProgress(const min, max, pos: Integer);
        procedure SplitProgress(const min, max, pos: Integer);
        //网页连接和资源解析部分
        procedure HtmlParserComplete(const EventCount: Integer);
        procedure HtmlParserEmbedFrame(const FrameUrl: string);
        procedure HtmlParserFreshRedirect(const NewUrl: string);
        procedure HtmlParserEmbedJs(const Jsurl: string);
        procedure HtmlParserFindEmbed(const src, alt, title: string);
        procedure HtmlParserFindImage(const src, alt, title: string);
        procedure HtmlParserFindUrl(const url, title, target: string);
        //信息片拆分算法实现部分
        procedure InfoClipComplete(const ClipCount: Integer);
        procedure InfoClipFindClip(const ClipStr: string);
        procedure AddNewSite(root, entry: string);
        //--------------------------------------------------------------------------
        //  网页权重计算部分,搜索核心之一,这里计算的是网页的物理得分
        //--------------------------------------------------------------------------
        function PreSplit(content: string): string;
        function IsDuplicatePage(const Signature: string): Boolean;
    protected
        procedure Execute; override;    //线程函数
    public
        SpiderID: integer;
        StatusMessage: string;
        FSocketErrorNo: Cardinal;
        SpiderName: string;
        IsAccessError: boolean;
        IsSkipedPage: boolean;
        constructor Create(SpiderIndex: integer);
        destructor destroy; override;
        property Oncomplete: TNotifyEvent read Foncomplete write Foncomplete;
    end;

implementation
uses main, config;

constructor CSpider.Create(SpiderIndex: integer);
begin
    //创建非挂起线程
    inherited Create(False);
    FreeOnTerminate := True;
    NetStartTime := Now;
    SpiderID := SpiderIndex;
    FInnerOpen := false;
    FPageForbiden := False;
    FSubDomainDeepth := 0;
    //网页下载初始化设置部分及事件委托
    myGet := THttpCli.Create(nil);
    GetStream := TMemoryStream.Create;
    myGet.RcvdStream := GetStream;
    myGet.Accept := 'text/html,text/xml,*/*';
    myGet.Connection := 'Keep-Alive';
    myGet.AcceptLanguage := 'zh-cn, en, en-us';
    myGet.Options := myGet.Options + [httpoEnableContentCoding];

    //每线程一秒钟最多接收16M Byte数据
    myGet.BandwidthLimit := 16 * 1024 * 1024;
    myGet.BandwidthSampling := 1000;
    myGet.FollowRelocation := true;
    myget.LocationChangeMaxCount := 16;

    myget.MultiThreaded := true;
    myget.NoCache := true;
    myget.OnDocBegin := HttpCliDocBegin;
    myget.OnDocEnd := HttpCliDocEnd;
    myget.OnSocksError := HttpCliSocksError;
    myget.OnRequestDone := HttpCliRequestDone;
    myget.OnStateChange := HttpCliStateChange;
    myget.OnDocData := HttpCliDocData;
    //网页连接解析过程委托
    HtmlParser := CHtmlParser.create(nil);
    HtmlParser.onEmbedJs := HtmlParserEmbedJs;
    HtmlParser.onEmbedFrame := HtmlParserEmbedFrame;
    HtmlParser.OnFindUrl := HtmlParserFindUrl;
    HtmlParser.OnFindImage := HtmlParserFindImage;
    HtmlParser.OnFindEmbed := HtmlParserFindEmbed;
    HtmlParser.OnFreshRedirect := HtmlParserFreshRedirect;
    HtmlParser.OnComplete := HtmlParserComplete;
    HtmlParser.onProgress := ParseProgress;
    HtmlParser.IgnoreJs := false;
    HtmlParser.IgnoreFrame := false;
    HtmlParser.IgnoreEmbed := false;
    HtmlParser.ExtList := @DomainExt;
    HtmlParser.PlainTextList := @TextExtList;
    //信息片拆分算法过程委托
    InfoClip := CInformationClip.create(nil);
    InfoClip.OnFindClip := InfoClipFindClip;
    InfoClip.OnComplete := InfoClipComplete;
    InfoClip.OnProgress := SplitProgress;
    InfoClip.SpilterList := @CSpilterList;

    //初始化临时存储的地方
    NewFoundUrls := TStringList.Create;
    NewFileUrls := TStringList.Create;
    NewFileComments := TStringList.Create;
    FExceptionLog := TStringList.Create;
end;

destructor CSpider.destroy;
begin
    myGet.Free;
    GetStream.Clear;
    Freeandnil(GetStream);
    Fhtml := '';
    HtmlParser.Free;
    InfoClip.Free;
    NewFoundUrls.Free;
    NewFileUrls.Free;
    NewFileComments.Free;
    FExceptionLog.Free;
    inherited destroy;
end;

procedure CSpider.Execute;
var TempANSI        : string;
    HasWait         : integer;
    Counter         : Integer;
begin
    //----------------------------------------------------------------------------
    //在没有被结束的情况下,循环等待下一个网页地址
    //----------------------------------------------------------------------------
    Counter := 0;
    CoInitialize(nil);
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        'COM初始化完成.');

    while (not Terminated) and (not Application.Terminated) do
    begin
        try
            Counter := Counter + 1;
            if (Counter mod 1024) = 0 then
            begin
                DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
                    '空闲查询1024次...');
            end;
            Sleep(10);

            if FPageUrl <> '' then
            begin
                //新的网页等待处理
                if (not IsSiteInner(FPageUrl)) then
                    CommonMessage('无效站外网页 ' + FPageUrl)
                else begin
                    //启用品牌站点照顾策略,则品牌站点可以不限制单页连接数
                    HtmlParser.IgnoreJs := not FIgnoreEmbedJs;
                    HtmlParser.IgnoreFrame := not FIgnoreEmbedJs;
                    HtmlParser.IgnoreEmbed := not FIgnoreEmbedJs;
                    NetStartTime := Now;
                    //进度显示
                    FPageLen := 0;
                    UiEventNum := 0;
                    UiClipInfo := 0;
                    //3个进度条
                    UiParseMin := 0;
                    UiParseMax := 100;
                    UiParsePos := 0;
                    UiClipMin := 0;
                    UiClipMax := 100;
                    UiClipPos := 0;
                    UiWriteMin := 0;
                    UiWriteMax := 100;
                    UiWritePos := 0;
                    downloadspent := 0;
                    NewFoundUrls.Clear;
                    NewFileUrls.Clear;
                    NewFileComments.Clear;
                    ParseProgress(0, 20, 0);
                    SplitProgress(0, 20, 0);
                    FreeStream;
                    HasWait := 0;
                    //开始执行,抓取并处理网页
                    if (myGet.State = httpReady) then
                    begin
                        //-----------------------------------------------------------------
                        //工作地址为空,HttpGet不忙,且不是线程的第一次下载
                        //-----------------------------------------------------------------
                        WorkingUrl := FPageUrl;
                        myGet.URL := WorkingUrl;

                        if (ProxyEnable) and (ProxyServer <> '') and (ProxyPort
                            <> '') then
                        begin
                            myGet.Proxy := ProxyServer;
                            myGet.ProxyPort := ProxyPort;
                        end;

                        CommonMessage('读取 ' + WorkingUrl);
                        FPageUrl := ''; //这个变量不再使用
                        SendInfo('正在下载网页...');
                        myGet.GetASync;
                    end;
                    while not (Terminated or Fcomplete or Application.Terminated)
                        do
                    begin
                        //-----------------------------------------------------------------
                        //下载完成,且网络未出错,首先将流转换为字符串,记录下载消耗时间
                        //-----------------------------------------------------------------
                        if (myGet.State = httpReady) and (WorkingUrl <> '') then
                        begin
                            downloadspent := MilliSecondsBetween(Now,
                                NetStartTime);

                            {详细状态字意义参考：http://www.ietf.org/rfc/rfc2616.txt}
                            CommonMessage('响应状态' +
                                IntToStr(myget.StatusCode));
                            if (myget.StatusCode < 400) and (GetStream.Size > 0)
                                then
                            begin
                                GetStream.Position := 0;
                                Fhtml := StrPas(GetStream.Memory);
                                FPageLen := GetStream.Size;

                                if FPageLen > (FMaxPageLen div 4) then
                                    CommonMessage('读取完成(大).')
                                else
                                    CommonMessage('读取完成.');
                            end else
                                FPageLen := 0;

                            //现在开始整理网页字符串
                            if (FPageLen > FMaxPageLen) then
                            begin
                                //如果网页太大
                                Fcomplete := true;
                                IsSkipedPage := true;
                                CommonMessage('网页太大,跳过收录.');
                                //网页不能为空
                            end else if FPageLen > 0 then
                            begin
                                if FUrlId > 0 then
                                begin
                                    //执行到这里说明网页有效,必须抛弃失效的上次分析网页所得.
                                    ExecuteSQL(Format('Delete From UindexWeb_WebUrl where WUParent=%d', [FUrlId]));
                                    ExecuteSQL(Format('Delete From UindexWeb_FileList where FLWebpage=%d', [FUrlId]));
                                    ExecuteSQL('Delete From UindexWeb_WebPage where WPUrl='''
                                        + WorkingUrl + '''');
                                end;
                                if (FPageLen > 0) then
                                    //不论UTF8还是ANSI总得满足MBCS基本要求
                                begin
                                    //对网页源代码进行修正
                                    TempANSI := AutoConvert2Ansi(@Fhtml);
                                    if (TempANSI <> '') then
                                    begin
                                        Fhtml := TempANSI;
                                        FPageLen := Length(Fhtml);
                                        SendInfo('编码格式转换完成.');
                                    end else
                                    begin
                                        Fhtml := '';
                                        FPageLen := 0;
                                        SendInfo('编码格式不支持.');
                                        CommonMessage('编码格式不支持.');
                                    end;

                                    if (FPageLen > 0) then
                                    begin
                                        FWPSignature := HashClip32(@Fhtml);
                                        FWPSignature :=
                                            SqlFitness(FWPSignature);
                                    end else
                                    begin
                                        FWPSignature := '';
                                    end;

                                    if ((FWPSignature <> '') and (not
                                        IsDuplicatePage(FWPSignature))) then
                                    begin
                                        SentWriteProgress;
                                        LatinChar(Fhtml);
                                        CommonMessage('HTML字母转义完成.');
                                        FormatHtml(Fhtml);
                                        CommonMessage('HTML标签标准化完成.');
                                        SendInfo('开始分析网页.');
                                        HtmlParser.LoadHTML(@Fhtml);
                                        HtmlParser.DocumentUrl := WorkingUrl;
                                        HtmlParser.Parse;
                                        SentParseComplete;
                                        GetCommonInfo;
                                        //如果不是仅仅做内容检测,并且文件大小有变化,充分说明
                                        //需要保存了
                                        FPageForbiden :=
                                            CheckWordForbiden(Fhtml);
                                        if (not (FSkipBadPage and FPageForbiden))
                                            and (not (FPreviousSize = FPageLen))
                                            then
                                        begin
                                            InfoClip.LoadHtml(@Fhtml);
                                            InfoClip.Prepare;
                                            InfoClip.InsertSpliter;
                                            InfoClip.DiGuiClip;
                                            InfoClip.SentComplete;

                                            preparesave;
                                            SaveLink;
                                            SaveImage;
                                            SavePage;

                                            SendInfo('链接和信息片保存完成.');
                                        end else begin
                                            CommonMessage('网页 ' + WorkingUrl +
                                                ' 已保存.');
                                        end;
                                    end;
                                end;
                                Fcomplete := true;
                            end else
                                //字符长度为空,或字符串长度小于0,出错
                                Fcomplete := true;
                        end else begin
                            //在这种下载中间状态最多停留10000毫秒
                            if (GetStream.Size > 0) then
                            begin
                                DebugPrintf(SpiderName + '(线程 ' +
                                    IntToStr(SpiderID) + ') ' + '正在下载网页:'
                                    +
                                    myGet.URL + ' ->(' + IntToStr(GetStream.Size)
                                    +
                                    ' Byte)');
                            end;

                            //消息显示完成,开始判断超时
                            if (HasWait > FMaxPageProcess) then
                            begin
                                Fcomplete := true;
                                AbortCurrentPage();
                                if not IsAccessError then
                                begin
                                    IsAccessError := true;
                                    CommonMessage('读取网页超时.');
                                end;
                            end else begin
                                HasWait := HasWait + 10;
                                Sleep(10);
                            end;
                            //Http下载中的繁忙状态
                        end;
                        //网页下载状态循环,这里网页处理完成了,设置完成状态
                    end;
                    if (not IsAccessError) and (not IsSkipedPage) then
                    begin
                        //-----------------------------------------------------------------
                        //对于既不是忽略又不是跳过的页,更新状态和大小
                        //这里将可以访问的网页状态设置为2,长度为实际长度
                        //-----------------------------------------------------------------
                        ExecuteSQL(Format('Update UindexWeb_WebUrl Set WUStatus=2,WUSize=%d where WUId=%d', [FPageLen, FUrlId]));
                    end else if (FSocketErrorNo <> NO_ERROR) then
                    begin
                        CommonMessage(Format('网络错误,%s',
                            [SocketMessage(FSocketErrorNo)]));
                    end;
                    //在站内
                end;
				SendInfo('网页完成.');
                CommonMessage('网页完成.');

                Synchronize(ThreadReportComplete);
            end;                        //单个网页(FPageUrl)处理完成

            Sleep(10);
            PrepareNewTask;
            //消息循环结束
        except
            on E: Exception do
            begin
                DebugPrintf('严重错误(ENO0001):' + E.Message);

                FExceptionLog.Clear;
                FExceptionLog.Add('当前线程：' + IntToStr(SpiderID));
                FExceptionLog.Add('线程名称：' + SpiderName);
                FExceptionLog.Add('当前网页：' + WorkingUrl);
                FExceptionLog.Add('错误消息：' + E.Message);
                JclLastExceptStackListToStrings(FExceptionLog, False, True,
                    True, True);
                if FExceptionLog.Count > 4 then
                begin
                    FExceptionLog[4] := '调用堆栈：' + FExceptionLog[4];
                end;
                Synchronize(ThreadReportBug);
            end;
        end;
    end;
    CoUninitialize();
end;

procedure CSpider.AbortCurrentPage;
begin
    try
        myGet.Abort();
    except
        on E: Exception do
        begin
            CommonMessage(format('Abort failed.class=%s,message=%s',
                [E.ClassName, E.Message]));
        end;
    end;
end;

procedure CSpider.PrepareNewTask;
begin
    // 重置标志位
    IsSkipedPage := false;
    Fcomplete := false;
    IsAccessError := false;
    FPageUrl := '';
    Clips := '';
    FSocketErrorNo := 0;
    Synchronize(ReadMainThread);
end;

procedure CSpider.ReadMainThread;
begin
    //公共初始化设置部分
    if (not Terminated) and (not Application.Terminated) then
    begin
        Fhtml := '';
        with somain do
        begin
            if IsThreadRunning(SpiderID) then
            begin
                FInnerOpen := ConfigWeb.SiteInnerOpen.Checked;
                FSubDomainDeepth := ConfigWeb.SubDomainDeepth.Value;
                FPageUrl := Trim(SpiderUrl[SpiderID].Text);
                FUrlId := PageUrlId[SpiderID];
                FPreviousSize := PageSizeArray[SpiderID];
                FFreshUI := ConfigWeb.Cfreshui.Checked;

                FMaxPageProcess := StringToIntDef(ConfigWeb.PageProcessMax.Text,
                    60000);
                FShowLink := ConfigWeb.CshowFindLink.Checked;
                if somain.LimitCPURate.checked then
                    FLimitCPUn := 1
                else
                    FLimitCPUn := 0;

                FIgnoreEmbedJs := ConfigWeb.IgnoreEmbedJs.Checked;
                WorkInOpenMode := ConfigWeb.SiteAllOpen.Checked;
                FCheckBadWord := configweb.CheckBadWord.Checked;
                FSkipBadPage := configweb.SkipBadPage.Checked;
                FUseComplexAlgr := configweb.UseComplexAlgr.Checked;
                myGet.Agent := ConfigWeb.spideragent.Text;
                HtmlParser.MaxUrlLen := StringToIntDef(ConfigWeb.UrlLenMax.Text,
                    256);
                //需要判断处理的参数
                FMaxPageLen := StringToIntDef(ConfigWeb.PageMaxLen.Text,
                    524288);
                //512KB网页
                if FMaxPageLen > 1073741824 then
                    FMaxPageLen := 1073741824;
            end;

            if SpiderNameList.Count > SpiderID then
                SpiderName := SpiderNameList[SpiderID]
            else
                SpiderName := Format('线程%d', [SpiderID]);
        end;
    end;
end;

procedure CSpider.ThreadReportBug;
begin
    somain.UindexWebThreadException(FExceptionLog.Text);
end;

procedure CSpider.CommonMessage(msg: string);
begin
    if FFreshUI then
    begin
        StatusMessage := Msg;
        Synchronize(SendBack);
    end;
end;

procedure CSpider.SendBack;
begin
    if (not Terminated) and (not Application.Terminated) then
        somain.StatusPrintf(SpiderName + ':' + StatusMessage);
end;

procedure CSpider.sentimportant;
begin
    if (not Terminated) and (not Application.Terminated) then
    begin
        somain.ImportantMsgStr[SpiderID].Text := UiImportantmsg;
        somain.SpentTimeStr[SpiderID].Caption := Format('%s s',
            [FormatFloat('0.000', MilliSecondsBetween(Now, NetStartTime) /
                1000)]);
    end;
end;

procedure CSpider.SendInfo(Str: string);
begin
    UiImportantmsg := Str;
    Synchronize(sentimportant);
end;

procedure CSpider.SentWriteProgress;
begin
    if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);
    Synchronize(UpdateWriteProgress);
end;

procedure CSpider.UpdateWriteProgress;
begin
    if (not Terminated) and (not Application.Terminated) then
    begin
        somain.SplitInfobar[SpiderID].Min := UiClipMin;
        somain.SplitInfobar[SpiderID].Max := UiClipMax;
        somain.SplitInfobar[SpiderID].Position := UiClipPos;
        somain.ParseProgressBar[SpiderID].Min := UiParseMin;
        somain.ParseProgressBar[SpiderID].Max := UiParseMax;
        somain.ParseProgressBar[SpiderID].Position := UiParsePos;
        somain.WriteProgressBar[SpiderID].Min := UiWriteMin;
        somain.WriteProgressBar[SpiderID].Max := UiWriteMax;
        somain.WriteProgressBar[SpiderID].Position := UiWritePos;
        somain.PageLenNum[SpiderID].Caption := IntToStr(FPageLen);
        somain.SpentTimeStr[SpiderID].Caption := Format('%s s',
            [FormatFloat('0.000', MilliSecondsBetween(Now, NetStartTime) /
                1000)]);
    end;
end;

procedure CSpider.FreeStream;
begin
    //注意:这里已经将GetStream释放
    GetStream.Clear;
    Fhtml := '';
end;

procedure CSpider.HttpCliDocBegin(Sender: TObject);
begin
    if not (POS('text/', myget.ContentType) = 1) then
    begin
        WorkingUrl := '';
        Fcomplete := true;
        AbortCurrentPage();
        FreeStream;
    end;
end;

procedure CSpider.HttpCliDocEnd(Sender: TObject);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        '网页下载完成.');
end;

procedure CSpider.HttpCliSocksError(Sender: TObject; Error: Integer;
    Msg: string);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        '错误:HTTP SOCKET ERROR,' + Msg);

    CommonMessage('错误:HTTP SOCKET ERROR,' + Msg);
end;

procedure CSpider.HttpCliRequestDone(Sender: TObject; RqType: THttpRequest;
    ErrCode: Word);
begin
    if ErrCode <> 0 then
    begin
        FSocketErrorNo := ErrCode;
        IsAccessError := true;
        Fcomplete := true;
    end;
end;

procedure CSpider.HttpCliStateChange(Sender: TObject);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        'ICS状态更新.');
end;

procedure CSpider.HtmlParserComplete(const EventCount: Integer);
begin
    UiEventNum := EventCount;
    SendInfo(Format('网页解析完成,有效标签 %d 个.', [EventCount]));
end;

procedure CSpider.HtmlParserEmbedFrame(const FrameUrl: string);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' + '框架:' +
        FrameUrl);

    AddUrl(FrameUrl, '');
end;

procedure CSpider.HtmlParserFreshRedirect(const NewUrl: string);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' + '刷新跳转:'
        + NewUrl);

    AddUrl(NewUrl, '');
end;

procedure CSpider.HtmlParserEmbedJs(const Jsurl: string);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' + 'Javascript:'
        + Jsurl);

    AddNewFile(Jsurl, '');
end;

procedure CSpider.HtmlParserFindEmbed(const src, alt, title: string);
begin
    if FShowLink then
        CommonMessage('嵌入:' + src);
    AddNewFile(src, alt + title);
end;

procedure CSpider.HtmlParserFindImage(const src, alt, title: string);
begin
    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' + '图片:' +
        src);

    AddNewFile(src, alt + title);
end;

procedure CSpider.HtmlParserFindUrl(const url, title, target: string);
begin
    if FShowLink then
        CommonMessage('链接:' + url);
    AddUrl(url, title);
end;

procedure CSpider.InfoClipComplete(const ClipCount: Integer);
begin
    UiClipInfo := ClipCount;
    CommonMessage('链接和信息片处理完成.');
end;

procedure CSpider.InfoClipFindClip(const ClipStr: string);
begin
    if FShowLink then
        DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' + '信息片:'
            + ClipStr);

    AddClip(ClipStr);
end;

procedure CSpider.ParseComplete;
begin
    if (not Terminated) and (not Application.Terminated) then
        somain.FindEventNum[SpiderID].Caption := IntToStr(UiEventNum);
end;

procedure CSpider.SentParseComplete;
begin
    Synchronize(ParseComplete);
end;

procedure CSpider.SentSplitComplete;
begin
    Synchronize(SplitComplete);
end;

procedure CSpider.SplitComplete;
begin
    if (not Terminated) and (not Application.Terminated) then
    begin
        somain.FindLinkNum[SpiderID].Caption := IntToStr(NewFoundUrls.Count);
        somain.FindEmbedNums[SpiderID].Caption := IntToStr(NewFileUrls.Count);
        somain.ClipInfoNum[SpiderID].Caption := IntToStr(UiClipInfo);
        somain.FindTotalUrlNums[SpiderID].Caption := IntToStr(NewFoundUrls.Count
            + NewFileUrls.Count);
    end;
end;

procedure CSpider.ParseProgress(const min, max, pos: Integer);
begin
    UiParseMin := min;
    UiParseMax := max;
    if max >= pos then
        UiParsePos := pos
    else
        UiParsePos := max;
    SentWriteProgress;

    DebugPrintf(Format(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        '链接进度:%d', [pos]));
end;

procedure CSpider.SplitProgress(const min, max, pos: Integer);
begin
    UiClipMin := min;
    UiClipMax := max;
    if max >= pos then
        UiClipPos := pos
    else
        UiClipPos := max;
    SentWriteProgress;

    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        Format('拆分进度:%d', [pos]));
end;

function CSpider.GetDocType(url: string): integer;
var doc, ext        : string;
begin
    doc := GetDocNameFromUrl(url);
    Result := DOC_WEB;                  //默认空扩展名

    if IsHttpURL(url) then
    begin
        if (doc <> '') then
        begin
            ext := GetDomainExt(doc);
            //存在这个点,而且不是最后一个字符
            if (ext <> '') then
            begin
                if FShowLink then
                    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') '
                        + '文件类型:' + ext);

                if binExtList.IndexOf(ext) >= 0 then
                    Result := DOC_BIN
                else if TextExtList.IndexOf(ext) >= 0 then
                    Result := DOC_TEXT
                else if ImgExtList.IndexOf(ext) >= 0 then
                    Result := DOC_IMAGE
                else if MovieExtList.IndexOf(ext) >= 0 then
                    Result := DOC_MOVIE
                else
                    Result := DOC_OTHER; //未知扩展名
            end;
        end;
    end else
    begin
        Result := DOC_OTHER;            //未知扩展名
    end;
end;

procedure CSpider.AddUrl(url, title: string);
var doctype         : integer;
begin
    if (url <> '') then
    begin
        doctype := GetDocType(url);
        //-------------------------------------------------------------------------
        // 这里只针对链接到的文件类型,毕竟根据扩展名判断文件类型是不够的
        //-------------------------------------------------------------------------
        case doctype of
            DOC_WEB: AddNewFUrl(url);   //没有扩展名
            DOC_TEXT: AddNewFUrl(url);  //普通链接
        else
            AddNewFile(url, title);
        end;
    end;
end;

procedure CSpider.PreCSW(var input: string);
var i               : integer;
begin
    //-------------------------------------------------------------------------
    //这里对信息片进行第一次分词,主要依据就是标点符号
    //clip中的大部分标点被统一为空格,然后依据空格来拆分信息
    //-------------------------------------------------------------------------
    if (input <> '') then
    begin
        SemaphoreAcquire(CSWtoken);

        for i := 0 to PreCSWList.Count - 1 do
        begin
            StringReplaceEx(input, PreCSWList[i], #32, [rfReplaceAll,
                rfIgnoreCase]);
        end;

        SemaphoreRelease(CSWtoken);

        //注意:PreCSW返回末尾为空格的字符串
        StringReplaceEx(input, #32 + #32, #32, [rfReplaceAll]);
        input := Trim(input) + #32;
    end;
end;

function CSpider.PreSplit(content: string): string;
var divpos, LastPos : integer;
    smallclip, rlt  : string;
begin
    PreCSW(content);
    if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);

    StringReplaceEx(content, #34, #32, [rfReplaceAll]);
    StringReplaceEx(content, #39, #32, [rfReplaceAll]);

    result := #32;
    if (content <> '') then
    begin
        if FUseComplexAlgr then
        begin
            LastPos := 1;
            divpos := pos(#32, content);
            while (divpos > 0) do begin
                //比如第5个字符是空格,就拷贝1-4这4个字符
                smallclip := copy(content, LastPos, divpos - LastPos);
                //注意是从空格下一个字符开始复制新字符串的
                LastPos := divpos + 1;
                divpos := sposex(#32, content, LastPos);
                if (not IsNumeric(smallclip)) then
                begin
                    //比较长或者不是简单数字
                    SemaphoreAcquire(CLIPtoken);
                    //单个的字母不能作为分词依据,向前靠拢
                    if (Length(smallclip) > 1) and (ClipList.process(@smallclip)
                        < 0) then
                        rlt := rlt + #32 + smallclip
                    else if Length(smallclip) = 1 then
                        rlt := rlt + smallclip;
                    SemaphoreRelease(CLIPtoken);

                    if FShowLink then
                        DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) +
                            ') ' + '标志片:' + smallclip);
                end;
            end;
        end else begin
            SemaphoreAcquire(CLIPtoken);
            //单个的字母不能作为分词依据,向前靠拢
            if (Length(content) > 1) and (ClipList.process(@content) < 0) then
                rlt := rlt + #32 + content
            else if Length(content) = 1 then
                rlt := rlt + content;
            SemaphoreRelease(CLIPtoken);

            if FShowLink then
                DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
                    '标志片2:' + content);
        end;
        //假设经过信息片算法后没有样本了,给个空格
        if (rlt <> '') and (Length(Trim(rlt)) > 1) then
            result := AnsiLeftStr(rlt, 248);
    end;
end;

procedure CSpider.AddClip(clip: string);
var divpos, LastPos : integer;
    smallclip       : string;
begin
    if (Trim(clip) = '') then
    begin
        DebugPrintf('AddClip:clip=nil');
        Exit;
    end;

    PreCSW(clip);
    if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);

    StringReplaceEx(clip, #34, #32, [rfReplaceAll]);
    StringReplaceEx(clip, #39, #32, [rfReplaceAll]);

    if (Trim(clip) <> '') then
    begin
        if FUseComplexAlgr then
        begin
            LastPos := 1;
            divpos := pos(#32, clip);
            while (divpos > 0) do begin
                smallclip := trim(copy(clip, LastPos, divpos - LastPos));
                LastPos := divpos + 1;
                divpos := sposex(#32, clip, LastPos);
                if (not IsNumeric(smallclip)) then
                begin
                    //比较长或者不是简单数字
                    SemaphoreAcquire(CLIPtoken);
                    //单个的字母不能作为分词依据,向前靠拢
                    if (Length(smallclip) > 1) and (ClipList.process(@smallclip)
                        < 0) then
                        Clips := Clips + #32 + smallclip
                    else if Length(smallclip) = 1 then
                        Clips := Clips + smallclip;
                    SemaphoreRelease(CLIPtoken);

                    if FShowLink then
                        DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) +
                            ') ' + '最小片:' + smallclip);
                end;
            end;
        end else begin
            //比较长或者不是简单数字
            SemaphoreAcquire(CLIPtoken);
            //单个的字母不能作为分词依据,向前靠拢
            if (Length(clip) > 1) and (ClipList.process(@clip) < 0) then
                Clips := Clips + #32 + clip
            else if Length(clip) = 1 then
                Clips := Clips + clip;
            SemaphoreRelease(CLIPtoken);

            if FShowLink then
                DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
                    '最小片2:' + clip);
        end;
    end;
end;

procedure CSpider.AddNewFile(FUrl, FComment: string);
begin
    if (Trim(FUrl) = '') then
    begin
        DebugPrintf('AddNewFile:FUrl=nil');
        Exit;
    end;

    SemaphoreAcquire(FILEtoken);
    if (not CheckUrlForbiden(LowAndTrim(FUrl))) and (EmbedFileList.process(@FUrl)
        < 0) then
    begin
        NewFileUrls.Add(FUrl);          //文件
        NewFileComments.Add(FComment);
    end;
    SemaphoreRelease(FILEtoken);
end;

procedure CSpider.AddNewFUrl(Link: string);
begin
    if (Trim(Link) = '') then
    begin
        DebugPrintf('AddNewFUrl:Link=nil');
        Exit;
    end;

    //如果这个站点有禁止列表,不区分大小写
    if IsSiteInner(Link) then
    begin
        SemaphoreAcquire(URLtoken);
        //这个表达式的排序不能变
        if IsBasicURL(Link) and (not CheckUrlForbiden(LowAndTrim(Link))) and
            (SiteUrlList.process(@Link) < 0) then
            NewFoundUrls.Add(Link);
        SemaphoreRelease(URLtoken);
    end;
end;

function CSpider.CheckWordForbiden(const content: string): boolean;
var i               : integer;
    LCaseFhtml      : string;
begin
    if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);
    result := false;
    LCaseFhtml := AnsiLowerCase(content);

    if SystemBadWordList.Count > 0 then
    begin
        for i := 0 to SystemBadWordList.Count - 1 do
        begin
            if pos(SystemBadWordList[i], LCaseFhtml) > 0 then
            begin
                result := true;
                exit;
            end;
        end;
    end;

    if CurrentBadWordList.Count > 0 then
    begin
        for i := 0 to CurrentBadWordList.Count - 1 do
        begin
            if pos(CurrentBadWordList[i], LCaseFhtml) > 0 then
            begin
                result := true;
                exit;
            end;
        end;
    end;
end;

function CSpider.CheckUrlForbiden(url: string): boolean;
var i               : integer;
begin
    if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);
    result := false;
    url := AnsiLowerCase(url);

    if (SystemForbidenUrlList.Count > 0) then
    begin
        for i := 0 to SystemForbidenUrlList.Count - 1 do
        begin
            //判断元素有效,察看列表中的元素是否出现
            if pos(SystemForbidenUrlList[i], url) > 0 then
            begin
                result := true;
                exit;
            end;
        end;
    end;

    if (CurrentForbidenUrlList.Count > 0) then
    begin
        for i := 0 to CurrentForbidenUrlList.Count - 1 do
        begin
            //判断元素有效,察看列表中的元素是否出现
            if pos(CurrentForbidenUrlList[i], url) > 0 then
            begin
                result := true;
                exit;
            end;
        end;
    end;
end;

function CSpider.IsSiteInner(url: string): boolean;
var NewSite         : string;
begin
    if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);
    Result := False;

    if (not IsHttpURL(url)) then
    begin
        DebugPrintf(Format(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
            '意外地遇到非HTTP链接 %s', [url]));
        Exit;
    end;

    NewSite := LowAndTrim(GetDomainRoot(url));
    if (NewSite <> '') then
    begin
        Result := (NewSite = CurrentSubRoot);
        if (not Result) and (WorkInOpenMode or (FInnerOpen and ((Length(NewSite)
            > Length(CurrentRoot)) and (AnsiRightStr(NewSite,
            (Length(CurrentRoot) +
            1)) = '.' + CurrentRoot)))) then
        begin
            //不在站内,此时如果完全开放，或半开放且在站内，再看看是不是有效站点
            if IsHealthDomain(NewSite) and (GetDocType(url) in [DOC_WEB,
                DOC_TEXT]) then
            begin
                if (FSubDomainDeepth = 0) or (CountStr('.', NewSite, CurrentRoot)
                    <= FSubDomainDeepth) then
                begin
                    AddNewSite(NewSite, Copy(url, 1, sposex('/', url, pos('://',
                        url) + 3)));
                end;
            end;
        end;
    end;
end;

function CSpider.IsDuplicatePage(const Signature: string): Boolean;
begin
    SemaphoreAcquire(DBtoken);
    with adolink do
    begin
        Close;
        SQL.Clear;
        SQL.Text :=
            'Select Top 1 WPSignature From UindexWeb_WebPage Where WPSignature=''' + Signature
            + '''';

        Open;
        Result := (not EOF);
        if Result then
        begin
            DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
                'IsDuplicatePage(TRUE):' + WorkingURL);
        end;

        SQL.Clear;
        Close;
    end;
    SemaphoreRelease(DBtoken);
end;

procedure CSpider.AddNewSite(root, entry: string);
var SiteId          : Integer;
begin
    SiteId := 0;

    if (root <> '') and (entry <> '') then
    begin
        if
            (ExecuteSQL(Format('insert into UindexWeb_Entry(SERoot,SEEntryPoint) values(''%s'',''%s'')', [root, entry]))) then
        begin
            DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
                '新增网站 ' + root);
        end else
        begin
            SemaphoreAcquire(DBtoken);

            with adolink do
            begin
                Close;
                SQL.Clear;
                SQL.Add('select SEiD,SERoot from UindexWeb_Entry where SERoot='''
                    + root + '''');

                Open;

                if not Eof then
                    SiteId := adolink.FieldValues['SEiD'];

                SQL.Clear;
                Close;
            end;

            SemaphoreRelease(DBtoken);

            if (SiteId > 0) then
                ExecuteSQL(Format('insert into UindexWeb_WebUrl(WUUrl,WUSiteId,WUParent) values(''%s'',%d,%d)', [entry, SiteId, FUrlId]));
        end;
    end;
end;

procedure CSpider.preparesave;
begin
    SentSplitComplete;
end;

procedure CSpider.SaveImage;
var i               : integer;
begin
    SendInfo(Format('保存文件:%d', [NewFileUrls.Count]));

    for i := 0 to NewFileUrls.Count - 1 do
    begin
        ExecuteSQL(Format('insert into UindexWeb_FileList(FLUrl,FLSiteId,FLComment,FLWebpage) values(''%s'',%d,''%s'',%d)', [NewFileUrls[i], CurrentSiteID,
            SqlFitness(SetDefaultSqlStr(NewFileComments[i])), FUrlId]));
        if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);
    end;

    UiWritePos := NewFoundUrls.Count + NewFileUrls.Count;
    SentWriteProgress;
end;

procedure CSpider.SaveLink;
var i               : integer;
begin
    SendInfo(Format('保存链接:%d 个.', [NewFoundUrls.Count]));
    UiWriteMax := NewFoundUrls.Count + NewFileUrls.Count;

    for i := 0 to NewFoundUrls.Count - 1 do
    begin
        ExecuteSQL(Format('insert into UindexWeb_WebUrl(WUUrl,WUSiteId,WUParent) values(''%s'',%d,%d)', [NewFoundUrls[i], CurrentSiteID, FUrlId]));
        if (FLimitCPUn <> 0) then Sleep(FLimitCPUn);
    end;

    UiWritePos := NewFoundUrls.Count;
    SentWriteProgress;
end;

procedure CSpider.SavePage;
begin
    SendInfo('保存网页.');
    //-------------------------------------------------------------------------
    // 信息片准备完成
    //-------------------------------------------------------------------------
    if (ContentPR(Clips) > 3) then
    begin
        //网页有效字符条件
        ExecuteSQL('Delete From UindexWeb_WebPage Where WPUrl=''' + WorkingUrl +
            '''');
        SemaphoreAcquire(DBtoken);

        with adolink do
        begin
            Close;
            SQL.Clear;
            SQL.Add('insert into UindexWeb_WebPage(WPContent,WPUrl,WPTitle,WPRealTitle,WPSiteId,WPCopyRight,WPAuthor,WPDevelopTool,WPKeyword,WPDiscription,WPHaveFile,WPHaveLink,WPBadWord,WPSignature) values(:P1,:P2,:P3,:P4,:P5,:P6,:P7,:P8,:P9,:P10,:P11,:P12,:P13,:P14)');
            Parameters.ParamByName('P1').Value := SqlFitness(Clips);
            Parameters.ParamByName('P2').Value := SqlFitness(WorkingUrl);
            Parameters.ParamByName('P3').Value := SqlFitness(Fpagetitle);
            Parameters.ParamByName('P4').Value :=
                SqlFitness(HtmlParser.PageTitle);
            Parameters.ParamByName('P5').Value := CurrentSiteID;
            Parameters.ParamByName('P6').Value := SqlFitness(FCopyRight);
            Parameters.ParamByName('P7').Value := SqlFitness(Fauthor);
            Parameters.ParamByName('P8').Value := SqlFitness(Fdeveloptool);
            Parameters.ParamByName('P9').Value := SqlFitness(Fkeywords);
            Parameters.ParamByName('P10').Value := SqlFitness(Fdiscription);
            Parameters.ParamByName('P11').Value := NewFileUrls.Count;
            Parameters.ParamByName('P12').Value := NewFoundUrls.Count;
            if FCheckBadWord and FPageForbiden then
            begin
                Parameters.ParamByName('P13').Value := 1;
                DebugPrintf(SpiderName + ':' + WorkingUrl + '，包含违禁内容！');
            end else
                Parameters.ParamByName('P13').Value := 0;
            Parameters.ParamByName('P14').Value := SqlFitness(FWPSignature);

            try
                ExecSQL;
            except
                on e: exception do
                begin
                    DebugPrintf(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') '
                        + '保存网页错误.E.T.SavePage.C' + e.Message);
                end;
            end;
            SQL.Clear;
            Close;
        end;

        SemaphoreRelease(DBtoken);
    end;
    UiWritePos := NewFoundUrls.Count + NewFileUrls.Count;
    SentWriteProgress;
end;

procedure CSpider.HttpCliDocData(Sender: TObject; Buffer: Pointer;
    Len: Integer);
begin
    DebugPrintf(Format(SpiderName + '(线程 ' + IntToStr(SpiderID) + ') ' +
        '已下载 %d', [myget.RcvdCount]));

    if myget.RcvdCount > FMaxPageLen then
    begin
        //如果网页太大,或者不需要更新
        Fcomplete := true;
        IsSkipedPage := true;
        AbortCurrentPage();
        FreeStream;
        FSocketErrorNo := 0;
        CommonMessage('网页太大,跳过解析.');
    end;
end;

procedure CSpider.GetCommonInfo;
begin
    //----------------------------------------------------------------------
    //网页基本信息
    //----------------------------------------------------------------------
    Fpagetitle := PreSplit(HtmlParser.PageTitle);
    FCopyRight := PreSplit(HtmlParser.CopyRight);
    Fauthor := PreSplit(HtmlParser.PageAuthor);
    Fdeveloptool := PreSplit(HtmlParser.DevelopTool);
    Fkeywords := PreSplit(HtmlParser.Keywords);
    Fdiscription := PreSplit(HtmlParser.Discription);
end;

procedure CSpider.ThreadReportComplete;
begin
    if assigned(FOncomplete) then FOncomplete(Self);
end;

end.
