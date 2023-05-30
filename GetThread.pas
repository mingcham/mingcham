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
        FPageUrl: string;               //��ҳ���Ե�ַ
        WorkingUrl: string;
        Fhtml: string;                  //Դ����
        FUrlId: integer;
        FPreviousSize: integer;
        //����ʱ��õĲ���
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
        //��̬��������
        myGet: THttpCli;
        HtmlParser: CHtmlParser;
        InfoClip: CInformationClip;

        GetStream: TMemoryStream;
        //��ҳ�������Դ����ʱ�洢�ĵط�
        NewFoundUrls: TStringList;
        NewFileUrls: TStringList;
        FExceptionLog: TStringList;
        NewFileComments: TStringList;
        Clips: string;

        //����Ԫ�ر������ò���
        FPageLen: integer;
        UiEventNum: integer;
        UiClipInfo: integer;
        UiImportantmsg: string;
        //3��������
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
        //��ҳ������Ϣ
        Fpagetitle: string;
        FCopyRight: string;
        Fauthor: string;
        Fdeveloptool: string;
        Fkeywords: string;
        Fdiscription: string;
        FWPSignature: string;
        Foncomplete: TNotifyEvent;
        //�������ù��̲���
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
        //д�����ݿⲿ��
        procedure preparesave;
        procedure SaveLink;
        procedure SaveImage;
        procedure SavePage;
        //���غ���ҳԤ������
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
        //�ַ�����Ϣ����
        procedure CommonMessage(msg: string);
        //����ˢ�º���
        procedure sentimportant();
        procedure UpdateWriteProgress();
        procedure SentWriteProgress();
        procedure ParseComplete();
        procedure SentParseComplete();
        procedure SplitComplete();
        procedure SentSplitComplete();
        procedure ParseProgress(const min, max, pos: Integer);
        procedure SplitProgress(const min, max, pos: Integer);
        //��ҳ���Ӻ���Դ��������
        procedure HtmlParserComplete(const EventCount: Integer);
        procedure HtmlParserEmbedFrame(const FrameUrl: string);
        procedure HtmlParserFreshRedirect(const NewUrl: string);
        procedure HtmlParserEmbedJs(const Jsurl: string);
        procedure HtmlParserFindEmbed(const src, alt, title: string);
        procedure HtmlParserFindImage(const src, alt, title: string);
        procedure HtmlParserFindUrl(const url, title, target: string);
        //��ϢƬ����㷨ʵ�ֲ���
        procedure InfoClipComplete(const ClipCount: Integer);
        procedure InfoClipFindClip(const ClipStr: string);
        procedure AddNewSite(root, entry: string);
        //--------------------------------------------------------------------------
        //  ��ҳȨ�ؼ��㲿��,��������֮һ,������������ҳ������÷�
        //--------------------------------------------------------------------------
        function PreSplit(content: string): string;
        function IsDuplicatePage(const Signature: string): Boolean;
    protected
        procedure Execute; override;    //�̺߳���
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
    //�����ǹ����߳�
    inherited Create(False);
    FreeOnTerminate := True;
    NetStartTime := Now;
    SpiderID := SpiderIndex;
    FInnerOpen := false;
    FPageForbiden := False;
    FSubDomainDeepth := 0;
    //��ҳ���س�ʼ�����ò��ּ��¼�ί��
    myGet := THttpCli.Create(nil);
    GetStream := TMemoryStream.Create;
    myGet.RcvdStream := GetStream;
    myGet.Accept := 'text/html,text/xml,*/*';
    myGet.Connection := 'Keep-Alive';
    myGet.AcceptLanguage := 'zh-cn, en, en-us';
    myGet.Options := myGet.Options + [httpoEnableContentCoding];

    //ÿ�߳�һ����������16M Byte����
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
    //��ҳ���ӽ�������ί��
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
    //��ϢƬ����㷨����ί��
    InfoClip := CInformationClip.create(nil);
    InfoClip.OnFindClip := InfoClipFindClip;
    InfoClip.OnComplete := InfoClipComplete;
    InfoClip.OnProgress := SplitProgress;
    InfoClip.SpilterList := @CSpilterList;

    //��ʼ����ʱ�洢�ĵط�
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
    //��û�б������������,ѭ���ȴ���һ����ҳ��ַ
    //----------------------------------------------------------------------------
    Counter := 0;
    CoInitialize(nil);
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        'COM��ʼ�����.');

    while (not Terminated) and (not Application.Terminated) do
    begin
        try
            Counter := Counter + 1;
            if (Counter mod 1024) = 0 then
            begin
                DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
                    '���в�ѯ1024��...');
            end;
            Sleep(10);

            if FPageUrl <> '' then
            begin
                //�µ���ҳ�ȴ�����
                if (not IsSiteInner(FPageUrl)) then
                    CommonMessage('��Чվ����ҳ ' + FPageUrl)
                else begin
                    //����Ʒ��վ���չ˲���,��Ʒ��վ����Բ����Ƶ�ҳ������
                    HtmlParser.IgnoreJs := not FIgnoreEmbedJs;
                    HtmlParser.IgnoreFrame := not FIgnoreEmbedJs;
                    HtmlParser.IgnoreEmbed := not FIgnoreEmbedJs;
                    NetStartTime := Now;
                    //������ʾ
                    FPageLen := 0;
                    UiEventNum := 0;
                    UiClipInfo := 0;
                    //3��������
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
                    //��ʼִ��,ץȡ��������ҳ
                    if (myGet.State = httpReady) then
                    begin
                        //-----------------------------------------------------------------
                        //������ַΪ��,HttpGet��æ,�Ҳ����̵߳ĵ�һ������
                        //-----------------------------------------------------------------
                        WorkingUrl := FPageUrl;
                        myGet.URL := WorkingUrl;

                        if (ProxyEnable) and (ProxyServer <> '') and (ProxyPort
                            <> '') then
                        begin
                            myGet.Proxy := ProxyServer;
                            myGet.ProxyPort := ProxyPort;
                        end;

                        CommonMessage('��ȡ ' + WorkingUrl);
                        FPageUrl := ''; //�����������ʹ��
                        SendInfo('����������ҳ...');
                        myGet.GetASync;
                    end;
                    while not (Terminated or Fcomplete or Application.Terminated)
                        do
                    begin
                        //-----------------------------------------------------------------
                        //�������,������δ����,���Ƚ���ת��Ϊ�ַ���,��¼��������ʱ��
                        //-----------------------------------------------------------------
                        if (myGet.State = httpReady) and (WorkingUrl <> '') then
                        begin
                            downloadspent := MilliSecondsBetween(Now,
                                NetStartTime);

                            {��ϸ״̬������ο���http://www.ietf.org/rfc/rfc2616.txt}
                            CommonMessage('��Ӧ״̬' +
                                IntToStr(myget.StatusCode));
                            if (myget.StatusCode < 400) and (GetStream.Size > 0)
                                then
                            begin
                                GetStream.Position := 0;
                                Fhtml := StrPas(GetStream.Memory);
                                FPageLen := GetStream.Size;

                                if FPageLen > (FMaxPageLen div 4) then
                                    CommonMessage('��ȡ���(��).')
                                else
                                    CommonMessage('��ȡ���.');
                            end else
                                FPageLen := 0;

                            //���ڿ�ʼ������ҳ�ַ���
                            if (FPageLen > FMaxPageLen) then
                            begin
                                //�����ҳ̫��
                                Fcomplete := true;
                                IsSkipedPage := true;
                                CommonMessage('��ҳ̫��,������¼.');
                                //��ҳ����Ϊ��
                            end else if FPageLen > 0 then
                            begin
                                if FUrlId > 0 then
                                begin
                                    //ִ�е�����˵����ҳ��Ч,��������ʧЧ���ϴη�����ҳ����.
                                    ExecuteSQL(Format('Delete From UindexWeb_WebUrl where WUParent=%d', [FUrlId]));
                                    ExecuteSQL(Format('Delete From UindexWeb_FileList where FLWebpage=%d', [FUrlId]));
                                    ExecuteSQL('Delete From UindexWeb_WebPage where WPUrl='''
                                        + WorkingUrl + '''');
                                end;
                                if (FPageLen > 0) then
                                    //����UTF8����ANSI�ܵ�����MBCS����Ҫ��
                                begin
                                    //����ҳԴ�����������
                                    TempANSI := AutoConvert2Ansi(@Fhtml);
                                    if (TempANSI <> '') then
                                    begin
                                        Fhtml := TempANSI;
                                        FPageLen := Length(Fhtml);
                                        SendInfo('�����ʽת�����.');
                                    end else
                                    begin
                                        Fhtml := '';
                                        FPageLen := 0;
                                        SendInfo('�����ʽ��֧��.');
                                        CommonMessage('�����ʽ��֧��.');
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
                                        CommonMessage('HTML��ĸת�����.');
                                        FormatHtml(Fhtml);
                                        CommonMessage('HTML��ǩ��׼�����.');
                                        SendInfo('��ʼ������ҳ.');
                                        HtmlParser.LoadHTML(@Fhtml);
                                        HtmlParser.DocumentUrl := WorkingUrl;
                                        HtmlParser.Parse;
                                        SentParseComplete;
                                        GetCommonInfo;
                                        //������ǽ��������ݼ��,�����ļ���С�б仯,���˵��
                                        //��Ҫ������
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

                                            SendInfo('���Ӻ���ϢƬ�������.');
                                        end else begin
                                            CommonMessage('��ҳ ' + WorkingUrl +
                                                ' �ѱ���.');
                                        end;
                                    end;
                                end;
                                Fcomplete := true;
                            end else
                                //�ַ�����Ϊ��,���ַ�������С��0,����
                                Fcomplete := true;
                        end else begin
                            //�����������м�״̬���ͣ��10000����
                            if (GetStream.Size > 0) then
                            begin
                                DebugPrintf(SpiderName + '(�߳� ' +
                                    IntToStr(SpiderID) + ') ' + '����������ҳ:'
                                    +
                                    myGet.URL + ' ->(' + IntToStr(GetStream.Size)
                                    +
                                    ' Byte)');
                            end;

                            //��Ϣ��ʾ���,��ʼ�жϳ�ʱ
                            if (HasWait > FMaxPageProcess) then
                            begin
                                Fcomplete := true;
                                AbortCurrentPage();
                                if not IsAccessError then
                                begin
                                    IsAccessError := true;
                                    CommonMessage('��ȡ��ҳ��ʱ.');
                                end;
                            end else begin
                                HasWait := HasWait + 10;
                                Sleep(10);
                            end;
                            //Http�����еķ�æ״̬
                        end;
                        //��ҳ����״̬ѭ��,������ҳ���������,�������״̬
                    end;
                    if (not IsAccessError) and (not IsSkipedPage) then
                    begin
                        //-----------------------------------------------------------------
                        //���ڼȲ��Ǻ����ֲ���������ҳ,����״̬�ʹ�С
                        //���ｫ���Է��ʵ���ҳ״̬����Ϊ2,����Ϊʵ�ʳ���
                        //-----------------------------------------------------------------
                        ExecuteSQL(Format('Update UindexWeb_WebUrl Set WUStatus=2,WUSize=%d where WUId=%d', [FPageLen, FUrlId]));
                    end else if (FSocketErrorNo <> NO_ERROR) then
                    begin
                        CommonMessage(Format('�������,%s',
                            [SocketMessage(FSocketErrorNo)]));
                    end;
                    //��վ��
                end;
				SendInfo('��ҳ���.');
                CommonMessage('��ҳ���.');

                Synchronize(ThreadReportComplete);
            end;                        //������ҳ(FPageUrl)�������

            Sleep(10);
            PrepareNewTask;
            //��Ϣѭ������
        except
            on E: Exception do
            begin
                DebugPrintf('���ش���(ENO0001):' + E.Message);

                FExceptionLog.Clear;
                FExceptionLog.Add('��ǰ�̣߳�' + IntToStr(SpiderID));
                FExceptionLog.Add('�߳����ƣ�' + SpiderName);
                FExceptionLog.Add('��ǰ��ҳ��' + WorkingUrl);
                FExceptionLog.Add('������Ϣ��' + E.Message);
                JclLastExceptStackListToStrings(FExceptionLog, False, True,
                    True, True);
                if FExceptionLog.Count > 4 then
                begin
                    FExceptionLog[4] := '���ö�ջ��' + FExceptionLog[4];
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
    // ���ñ�־λ
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
    //������ʼ�����ò���
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
                //��Ҫ�жϴ���Ĳ���
                FMaxPageLen := StringToIntDef(ConfigWeb.PageMaxLen.Text,
                    524288);
                //512KB��ҳ
                if FMaxPageLen > 1073741824 then
                    FMaxPageLen := 1073741824;
            end;

            if SpiderNameList.Count > SpiderID then
                SpiderName := SpiderNameList[SpiderID]
            else
                SpiderName := Format('�߳�%d', [SpiderID]);
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
    //ע��:�����Ѿ���GetStream�ͷ�
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
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        '��ҳ�������.');
end;

procedure CSpider.HttpCliSocksError(Sender: TObject; Error: Integer;
    Msg: string);
begin
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        '����:HTTP SOCKET ERROR,' + Msg);

    CommonMessage('����:HTTP SOCKET ERROR,' + Msg);
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
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        'ICS״̬����.');
end;

procedure CSpider.HtmlParserComplete(const EventCount: Integer);
begin
    UiEventNum := EventCount;
    SendInfo(Format('��ҳ�������,��Ч��ǩ %d ��.', [EventCount]));
end;

procedure CSpider.HtmlParserEmbedFrame(const FrameUrl: string);
begin
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' + '���:' +
        FrameUrl);

    AddUrl(FrameUrl, '');
end;

procedure CSpider.HtmlParserFreshRedirect(const NewUrl: string);
begin
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' + 'ˢ����ת:'
        + NewUrl);

    AddUrl(NewUrl, '');
end;

procedure CSpider.HtmlParserEmbedJs(const Jsurl: string);
begin
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' + 'Javascript:'
        + Jsurl);

    AddNewFile(Jsurl, '');
end;

procedure CSpider.HtmlParserFindEmbed(const src, alt, title: string);
begin
    if FShowLink then
        CommonMessage('Ƕ��:' + src);
    AddNewFile(src, alt + title);
end;

procedure CSpider.HtmlParserFindImage(const src, alt, title: string);
begin
    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' + 'ͼƬ:' +
        src);

    AddNewFile(src, alt + title);
end;

procedure CSpider.HtmlParserFindUrl(const url, title, target: string);
begin
    if FShowLink then
        CommonMessage('����:' + url);
    AddUrl(url, title);
end;

procedure CSpider.InfoClipComplete(const ClipCount: Integer);
begin
    UiClipInfo := ClipCount;
    CommonMessage('���Ӻ���ϢƬ�������.');
end;

procedure CSpider.InfoClipFindClip(const ClipStr: string);
begin
    if FShowLink then
        DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' + '��ϢƬ:'
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

    DebugPrintf(Format(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        '���ӽ���:%d', [pos]));
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

    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        Format('��ֽ���:%d', [pos]));
end;

function CSpider.GetDocType(url: string): integer;
var doc, ext        : string;
begin
    doc := GetDocNameFromUrl(url);
    Result := DOC_WEB;                  //Ĭ�Ͽ���չ��

    if IsHttpURL(url) then
    begin
        if (doc <> '') then
        begin
            ext := GetDomainExt(doc);
            //���������,���Ҳ������һ���ַ�
            if (ext <> '') then
            begin
                if FShowLink then
                    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') '
                        + '�ļ�����:' + ext);

                if binExtList.IndexOf(ext) >= 0 then
                    Result := DOC_BIN
                else if TextExtList.IndexOf(ext) >= 0 then
                    Result := DOC_TEXT
                else if ImgExtList.IndexOf(ext) >= 0 then
                    Result := DOC_IMAGE
                else if MovieExtList.IndexOf(ext) >= 0 then
                    Result := DOC_MOVIE
                else
                    Result := DOC_OTHER; //δ֪��չ��
            end;
        end;
    end else
    begin
        Result := DOC_OTHER;            //δ֪��չ��
    end;
end;

procedure CSpider.AddUrl(url, title: string);
var doctype         : integer;
begin
    if (url <> '') then
    begin
        doctype := GetDocType(url);
        //-------------------------------------------------------------------------
        // ����ֻ������ӵ����ļ�����,�Ͼ�������չ���ж��ļ������ǲ�����
        //-------------------------------------------------------------------------
        case doctype of
            DOC_WEB: AddNewFUrl(url);   //û����չ��
            DOC_TEXT: AddNewFUrl(url);  //��ͨ����
        else
            AddNewFile(url, title);
        end;
    end;
end;

procedure CSpider.PreCSW(var input: string);
var i               : integer;
begin
    //-------------------------------------------------------------------------
    //�������ϢƬ���е�һ�ηִ�,��Ҫ���ݾ��Ǳ�����
    //clip�еĴ󲿷ֱ�㱻ͳһΪ�ո�,Ȼ�����ݿո��������Ϣ
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

        //ע��:PreCSW����ĩβΪ�ո���ַ���
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
                //�����5���ַ��ǿո�,�Ϳ���1-4��4���ַ�
                smallclip := copy(content, LastPos, divpos - LastPos);
                //ע���Ǵӿո���һ���ַ���ʼ�������ַ�����
                LastPos := divpos + 1;
                divpos := sposex(#32, content, LastPos);
                if (not IsNumeric(smallclip)) then
                begin
                    //�Ƚϳ����߲��Ǽ�����
                    SemaphoreAcquire(CLIPtoken);
                    //��������ĸ������Ϊ�ִ�����,��ǰ��£
                    if (Length(smallclip) > 1) and (ClipList.process(@smallclip)
                        < 0) then
                        rlt := rlt + #32 + smallclip
                    else if Length(smallclip) = 1 then
                        rlt := rlt + smallclip;
                    SemaphoreRelease(CLIPtoken);

                    if FShowLink then
                        DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) +
                            ') ' + '��־Ƭ:' + smallclip);
                end;
            end;
        end else begin
            SemaphoreAcquire(CLIPtoken);
            //��������ĸ������Ϊ�ִ�����,��ǰ��£
            if (Length(content) > 1) and (ClipList.process(@content) < 0) then
                rlt := rlt + #32 + content
            else if Length(content) = 1 then
                rlt := rlt + content;
            SemaphoreRelease(CLIPtoken);

            if FShowLink then
                DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
                    '��־Ƭ2:' + content);
        end;
        //���辭����ϢƬ�㷨��û��������,�����ո�
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
                    //�Ƚϳ����߲��Ǽ�����
                    SemaphoreAcquire(CLIPtoken);
                    //��������ĸ������Ϊ�ִ�����,��ǰ��£
                    if (Length(smallclip) > 1) and (ClipList.process(@smallclip)
                        < 0) then
                        Clips := Clips + #32 + smallclip
                    else if Length(smallclip) = 1 then
                        Clips := Clips + smallclip;
                    SemaphoreRelease(CLIPtoken);

                    if FShowLink then
                        DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) +
                            ') ' + '��СƬ:' + smallclip);
                end;
            end;
        end else begin
            //�Ƚϳ����߲��Ǽ�����
            SemaphoreAcquire(CLIPtoken);
            //��������ĸ������Ϊ�ִ�����,��ǰ��£
            if (Length(clip) > 1) and (ClipList.process(@clip) < 0) then
                Clips := Clips + #32 + clip
            else if Length(clip) = 1 then
                Clips := Clips + clip;
            SemaphoreRelease(CLIPtoken);

            if FShowLink then
                DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
                    '��СƬ2:' + clip);
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
        NewFileUrls.Add(FUrl);          //�ļ�
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

    //������վ���н�ֹ�б�,�����ִ�Сд
    if IsSiteInner(Link) then
    begin
        SemaphoreAcquire(URLtoken);
        //������ʽ�������ܱ�
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
            //�ж�Ԫ����Ч,�쿴�б��е�Ԫ���Ƿ����
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
            //�ж�Ԫ����Ч,�쿴�б��е�Ԫ���Ƿ����
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
        DebugPrintf(Format(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
            '�����������HTTP���� %s', [url]));
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
            //����վ��,��ʱ�����ȫ���ţ���뿪������վ�ڣ��ٿ����ǲ�����Чվ��
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
            DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
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
            DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
                '������վ ' + root);
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
    SendInfo(Format('�����ļ�:%d', [NewFileUrls.Count]));

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
    SendInfo(Format('��������:%d ��.', [NewFoundUrls.Count]));
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
    SendInfo('������ҳ.');
    //-------------------------------------------------------------------------
    // ��ϢƬ׼�����
    //-------------------------------------------------------------------------
    if (ContentPR(Clips) > 3) then
    begin
        //��ҳ��Ч�ַ�����
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
                DebugPrintf(SpiderName + ':' + WorkingUrl + '������Υ�����ݣ�');
            end else
                Parameters.ParamByName('P13').Value := 0;
            Parameters.ParamByName('P14').Value := SqlFitness(FWPSignature);

            try
                ExecSQL;
            except
                on e: exception do
                begin
                    DebugPrintf(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') '
                        + '������ҳ����.E.T.SavePage.C' + e.Message);
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
    DebugPrintf(Format(SpiderName + '(�߳� ' + IntToStr(SpiderID) + ') ' +
        '������ %d', [myget.RcvdCount]));

    if myget.RcvdCount > FMaxPageLen then
    begin
        //�����ҳ̫��,���߲���Ҫ����
        Fcomplete := true;
        IsSkipedPage := true;
        AbortCurrentPage();
        FreeStream;
        FSocketErrorNo := 0;
        CommonMessage('��ҳ̫��,��������.');
    end;
end;

procedure CSpider.GetCommonInfo;
begin
    //----------------------------------------------------------------------
    //��ҳ������Ϣ
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
