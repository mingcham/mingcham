unit HtmlParser;

interface

uses
    SysUtils, Classes, StrUtils, CoreString, JclStrings;

type
    TFindIncludeJS = procedure(const Jsurl: string) of object;
    TFindIncludeFrame = procedure(const FrameUrl: string) of object;
    TFindFreshRedirectEvent = procedure(const url: string) of object;
    TFindLink = procedure(const url, title, target: string) of object;
    TFindImage = procedure(const src, alt, title: string) of object;
    TFindEmbed = procedure(const src, alt, title: string) of object;
    TParseProgress = procedure(const min, max, pos: integer) of object;
    TParseComplete = procedure(const EventCount: integer) of object;
    //----------------------------------------------------------------------------
    //����:ʵ��HTML��ҳ�ķ����ֽ�
    //----------------------------------------------------------------------------
    CHtmlParser = class(TComponent)
    private
        Fhtml: PAnsiString;             //��ҳԴ����
        FDocumentUrl: string;           //��������ʱ,������URL�Ļ�׼
        FMaxParse: integer;             //���������ٸ����Ӻ����
        FDOCTYPE: string;               //��ҳ��������ѭ�Ĺ涨
        FCopyRight: string;             //��ҳʹ�õ��ַ���
        FTitle: string;                 //��ҳ�ı��� <title>��document.title����
        FAuthor: string;                //��ҳ������
        FDevelopeTool: string;          //��ҳ�ı�д����
        Fbgsound: string;
        FKeywords: string;              //��ҳ�Ĺؼ���
        FDiscription: string;           //��ҳ������
        FignoreJs: boolean;
        FignoreFrame: boolean;
        FignoreEmbed: boolean;
        FEnableLinkCheck: boolean;
        //����ָʾ����.
        FParseWebPagePoint: integer;
        FEventCount: integer;
        FProgressPos: integer;
        //��������
        FonEmbedJs: TFindIncludeJS;
        FonEmbedFrame: TFindIncludeFrame;
        FonRefreshDirect: TFindFreshRedirectEvent;
        FOnFindUrl: TFindLink;
        FonImage: TFindImage;
        FonEmbed: TFindEmbed;
        //������ɲ���
        FonComplete: TParseComplete;
        FonProgress: TParseProgress;
        FParserVersion: string;
        FMaxUrlLen: integer;
        procedure SetDocumentUrl(const Value: string);
        procedure ProcessTagItem(const item: PAnsiString);
        //���������ǰ��HTML����,���ʼ�����������ֵ
    protected
        //�ڲ�ͨ�ù���,���Ե�ʱ��ɷ���public��
        procedure ResetPoint;
        procedure GetPageInfo;
        function GetKeyValue(const ItemStr: PAnsiString; const Key: string):
            string;
        function VirginTouch(const you, me: string): string;
        function ValidateUrl(const Path: string): string;
        function GetWebDirectory(const url: string): string;
        function RecognizeUrl(url: string): string;
        function Relative2Native(const Url: string): string;
        function IsWebPageExt(const filename: string): boolean;
        function ParseWebPage: integer;
    public
        //���ݹ麯���������
        EmbedsCount: integer;
        LinksCount: integer;
        ImagesCount: integer;
        ExtList: ^TStringList;          //���Խ��ܵ�������׺
        PlainTextList: ^TStringList;    //���Խ��ܵ�������׺
        constructor create(Aowner: Tcomponent); override;
        destructor Destroy; override;
        function Parse(): integer;      //�ڲ�����,�ݹ�������Դ
        procedure LoadHtml(const html: PAnsiString);
    published
        property EnableLinkCheck: boolean read FEnableLinkCheck write
            FEnableLinkCheck;
        property DocumentUrl: string read FDocumentUrl write SetDocumentUrl;
        property onEmbedJs: TFindIncludeJS read FonEmbedJs write FonEmbedJs;
        property onEmbedFrame: TFindIncludeFrame read FonEmbedFrame write
            FonEmbedFrame;
        property OnFreshRedirect: TFindFreshRedirectEvent read FonRefreshDirect
            write FonRefreshDirect;
        property OnFindUrl: TFindLink read FOnFindUrl write FOnFindUrl;
        property OnFindImage: TFindImage read FonImage write FonImage;
        property OnFindEmbed: TFindEmbed read FonEmbed write FonEmbed;
        property OnComplete: TParseComplete read FonComplete write FonComplete;
        property onProgress: TParseProgress read FonProgress write FonProgress;
        property MaxParse: integer read FMaxParse write FMaxParse;
        property ParserVersion: string read FParserVersion write FParserVersion;
        property DOCTYPE: string read FDOCTYPE write FDOCTYPE;
        property CopyRight: string read FCopyRight write FCopyRight;
        property PageTitle: string read FTitle write FTitle;
        property PageAuthor: string read FAuthor write FAuthor;
        property DevelopTool: string read FDevelopeTool write FDevelopeTool;
        property Keywords: string read FKeywords write FKeywords;
        property Discription: string read FDiscription write FDiscription;
        property IgnoreJs: boolean read FignoreJs write FignoreJs;
        property IgnoreFrame: boolean read FignoreFrame write FignoreFrame;
        property IgnoreEmbed: boolean read FignoreEmbed write FignoreEmbed;
        property MaxUrlLen: integer read FMaxUrlLen write FMaxUrlLen;
    end;

procedure Register;

implementation

procedure Register;
begin
    RegisterComponents('Uindex', [CHtmlParser]);
end;

constructor CHtmlParser.create(Aowner: Tcomponent);
begin
    inherited create(Aowner);
    FParserVersion := 'Uindex HtmlParser V2009.5.26';
    FIgnoreFrame := false;
    FignoreJs := false;
    FIgnoreEmbed := false;
    FEnableLinkCheck := true;
    FMaxUrlLen := 0;
    FMaxParse := 0;
end;

procedure CHtmlParser.ResetPoint;
begin
    if assigned(onProgress) then
        onProgress(0, 20, 1);
    FEventCount := 0;
    FParseWebPagePoint := 0;
    FProgressPos := 0;
    //��ҳ�ķ������
    EmbedsCount := 0;
    LinksCount := 0;
    ImagesCount := 0;
end;

function CHtmlParser.GetKeyValue(const ItemStr: PAnsiString; const Key: string):
    string;
var i, j            : integer;
begin
    //E.g. img src="uindex.png"
    i := NCpos(Key + '=', ItemStr^);
    if (i > 0) then
    begin
        i := i + length(Key) + 1;

        { has one valid char at least }
        if (i <= Length(ItemStr^)) then
        begin
            if (ItemStr^[i] = #39) or (ItemStr^[i] = #34) then
            begin
                j := sposex(ItemStr^[i], ItemStr^, (i + 1));
                if j > 0 then
                begin
                    inc(i);
                    result := Copy(ItemStr^, i, j - i);
                end;
            end else if sposex(#32, ItemStr^, i) > 0 then
                result := Copy(ItemStr^, i, sposex(#32, ItemStr^, i) - i)
            else
                result := Copy(ItemStr^, i, length(ItemStr^));
        end;
    end;
end;

function CHtmlParser.ParseWebPage: integer;
var i, j, k         : integer;
    TagItem         : string;
begin
    result := 0;

    while True do
    begin
        if FEnableLinkCheck and (FMaxParse > 0) and (FEventCount > FMaxParse)
            then
            exit;
        //-------------------------------------------------------------------------
        // ���ұ�ǩ�Ŀ�ʼ�ͽ���
        //-------------------------------------------------------------------------
        i := sPosex('<', Fhtml^, FParseWebPagePoint);
        j := sPosex('>', Fhtml^, i);
        if (j > FParseWebPagePoint) and (i > 0) then
        begin
            //---------------------------------------------------------------------
            //����ʹ����Ӳ���뷽ʽ����Html�ĵ�,����Խ�����,�����ǿ�������������:
            //<a href='163.com'>(���ֱ�ǩ�����пո�͵Ⱥ�,�������ֱպϱ�ǩ����������Ϣ��)163</a>(��������)
            //---------------------------------------------------------------------
            FParseWebPagePoint := j;
            //ע��,a can't to Z,ASCII separated.(���Խ��)
            if (Fhtml^[i + 1] in ['a'..'z', 'A'..'Z']) then
            begin
                TagItem := Copy(Fhtml^, (i + 1), ((j - i) - 1));
                if (pos('=', TagItem) > 0) and (pos(#32, TagItem) > 0) and
                    (pos('<', TagItem) <= 0) then
                    ProcessTagItem(@TagItem);
            end;
            //---------------------------------------------------------------------
            // �ݹ�����ʱ��Ҫ�жϽ����Ƿ����1/7,�����ʾ7�ν��ȱ仯
            //---------------------------------------------------------------------
            if (Length(Fhtml^) > 16) then
            begin
                k := FParseWebPagePoint div (Length(Fhtml^) div 16);
                if (FProgressPos <> k) and assigned(onProgress) then
                begin
                    onProgress(0, 20, 4 + k);
                    FProgressPos := k;
                end;
            end;
        end else
        begin
            exit;
        end;
    end;

    result := LinksCount;
end;

procedure CHtmlParser.GetPageInfo;
var i, j            : integer;
    BgsoundStrOrgin : string;
begin
    //�õ���ҳ����
    if assigned(onProgress) then
        onProgress(0, 20, 2);
    i := NCposex('<title', Fhtml^, 0);
    j := NCposex('</title', Fhtml^, i);
    if (j > i) and (i > 0) then
    begin
        FTitle := Copy(Fhtml^, (i + 7), ((j - i) - 7));
    end else
        FTitle := '';

    //<base href="http://www.opencpu.com/"></base>
    i := NCposex('<base', Fhtml^, 0);
    j := NCposex('>', Fhtml^, (i + 4));
    if (j > i) and (i > 0) then
    begin
        BgsoundStrOrgin := Copy(Fhtml^, (i + 6), ((j - i) - 6));
        Fbgsound := GetKeyValue(@BgsoundStrOrgin, 'href');

        if (Fbgsound <> '') then
        begin
            FDocumentUrl := Fbgsound;
        end;
    end;

    //�Ƿ��б�������8,8+-1
    i := NCposex('<bgsound', Fhtml^, 0);
    j := NCposex('>', Fhtml^, (i + 7));
    if (j > i) and (i > 0) then
    begin
        BgsoundStrOrgin := Copy(Fhtml^, (i + 9), ((j - i) - 9));
        Fbgsound := GetKeyValue(@BgsoundStrOrgin, 'src');
    end else
        Fbgsound := '';

    //ɾ�����нű�
    ClearNoise(Fhtml, '<script', '</script>');
    //ɾ�����
    ClearNoise(Fhtml, '<style', '</style>');
    //ɾ��ע��
    ClearNoise(Fhtml, '<!--', '-->');
    //ɾ������
    ClearNoise(Fhtml, '<title', '</title>');
end;

function CHtmlParser.Parse: integer;
begin
    //-------------------------------------------------------------------------
    //˳��˵��:���Ƚ����õ���ҳ���⣬�������ֵ���Ϣ
    //ע��:��������������ϴ�.
    //-------------------------------------------------------------------------
    ResetPoint;
    GetPageInfo;
    if assigned(onProgress) then
        onProgress(0, 20, 3);
    if Length(Fhtml^) > 13 then
        //<a href=></a>�պ�13���ַ�,���������������ô����������
        ParseWebPage;
    if assigned(onProgress) then
        onProgress(0, 20, 20);
    if assigned(OnComplete) then
        OnComplete(FEventCount);
    result := FEventCount;
end;

function CHtmlParser.VirginTouch(const you, me: string): string;
var
    protocol        : string;
    TmpPath         : string;
begin
    //-------------------------------------------------------------------------
    //�״δ�������:��ǰ��ҳ��ַΪme,����ʶ��Ϊyou.
    //-------------------------------------------------------------------------
    result := Trim(you);
    if (you = '') or ((FMaxUrlLen > 0) and (Length(you) > FMaxUrlLen)) then
    begin
        result := '';
        exit;
    end;

    if (NCpos('mailto:', you) > 0) or (NCpos('script:', you) > 0) or
        (NCpos('target=', you) > 0)
        or (NCpos(you, me) > 0) then
    begin
        result := '';
        exit;
    end;

    //���ȿ��Ƿ�Ϊ����,����ֱ��ʶ����ֱ������.
    TmpPath := RecognizeUrl(you);
    if (TmpPath <> '') then
    begin
        //�ɹ�ʶ�����ַ,����Ҫ����.
        result := ValidateUrl(TmpPath);
    end else begin
        //����ʶyou,�Ǿͼ���ʶ��.
        if you[1] = '?' then
        begin
            if (pos('?', me) > 0) then  //��������ҼӸ�����,���Ѿ��в�����?
                result := Copy(me, 1, pos('?', me) - 1) + you //��
            else
                result := me + you;     //��ѹ����û�в���
        end else if you[1] = '&' then
        begin
            if pos('?', me) > 0 then    //���ǵ�ǰҳ�Ӹ�����,���в�����?
                result := Copy(me, 1, pos('?', me)) + Copy(you, 2, Length(you))
            else
                result := me + '?' + Copy(you, 2, Length(you));
        end else if you[1] = '/' then
        begin
            TmpPath := Copy(me, 1, posex('/', me, pos('://', me) + 3) - 1);
            //��Ը�Ŀ¼��·��
            if (TmpPath <> '') then
                result := TmpPath + you
            else
                result := '';
        end else begin
            TmpPath := GetWebDirectory(me); //��Ե�ǰĿ¼
            if (TmpPath <> '') then
                result := TmpPath + you
            else
                result := '';
        end;
    end;
    //-------------------------------------------------------------------------
    //  2:���м��ַ��������
    //-------------------------------------------------------------------------
    if (pos('://', result) > 0) then
    begin
        TmpPath := Copy(result, pos('://', result) + 3, length(result));
        //����Э��ĵ�ַ
        protocol := Copy(result, 1, pos('://', result) - 1); //Э��
        //  ����Ŀ¼����
        TmpPath := Relative2Native(TmpPath);

        // ����Ŀ¼��
        StringReplaceEx(TmpPath, '//', '/', [rfReplaceAll]);
        if (TmpPath <> '') then
            result := ValidateUrl(protocol + '://' + TmpPath)
        else
            result := '';
        // ·����ϵ�������
    end else
        result := '';
end;

function CHtmlParser.ValidateUrl(const Path: string): string;
//------------------------------------------------------------------------------
//ע��:���������������,�޷��б�http://www.opencpu.com/bbs�Ǹ�Ŀ¼���Ǹ��ļ�,����
//Ĭ����Ŀ¼,������һ�Ǹ�û����չ�����ļ�,�Ǿʹ�Զ��,ͬʱhttp://qq.com/index.net
//���������Ļᱻ�жϳ��ļ�,�����п����Ǵ����.
//------------------------------------------------------------------------------
var doc             : string;
    SlashPos, ParamPos, ExtI: integer;
begin
    if LeastUrlRequest(Path) then
    begin
        result := Path;
        ParamPos := pos('?', result);
        if (ParamPos > 0) then
            SlashPos := (length(result) - posex('/', AnsiReverseString(result),
                (length(result) - ParamPos))) + 1
        else
            SlashPos := RightPos('/', result);
        if (SlashPos > 0) and (SlashPos <= length(result)) and (SlashPos >
            (pos('://', result) + 2)) then
        begin
            //----------------------------------------------------------------------
            //����һ�����б��
            //----------------------------------------------------------------------
            doc := GetDocNameFromUrl(result);
            if ((ParamPos - SlashPos) > 1) and (not (pos('.', doc) > 0))
                and (not IsWebPageExt(doc)) then
                insert('/', result, ParamPos);
        end else if (SlashPos = (pos('://', result) + 2)) then
        begin
            //ѹ���Ͳ����ڱ�ʾ���û��б��
            if (ParamPos > 0) then
                insert('/', result, ParamPos)
                    //��http://www.163.com?qq=123����һƲ
            else if (SlashPos > 0) then
                result := result + '/'  //��http://www.163.com����һƲ/
            else begin
                result := '';
                exit;
            end;
        end else begin
            result := '';
            exit;
        end;
        //----------------------------------------------------------------------
        // ���¼������Ӹ�ʽ��Ҫ����
        //----------------------------------------------------------------------
        //ɾ����ǩ����

        SlashPos := pos('://', result);
        if (SlashPos > 0) and (sposex(':/', result, SlashPos + 3) > 0) then
        begin
            result := '';
            exit;
        end;

        if (pos('#', result) > 0) then
        begin
            delete(result, pos('#', result), length(result));
        end;

        //���������������URL
        ParamPos := pos('?', result);
        if (ParamPos > 0) then
        begin
            //����?���滹��?��
            if (sposex('?', result, ParamPos + 1) > 0) then
            begin
                result := '';
                exit;
            end;
            //��������г��ֳ�����,.com,.net,.org��Щ,��Ϊ����ת,����¼�õ�ַ
            for ExtI := 0 to (ExtList^).Count - 1 do
            begin
                if (result <> '') and (NCposex('.' + (ExtList^)[ExtI], result,
                    ParamPos + 1) > 0) then
                begin
                    result := '';
                    exit;
                end;
            end;
            //��������г��ֳ�����,.htm,.php,.aspx��Щ,��Ϊ����ת,����¼�õ�ַ
            for ExtI := 0 to (PlainTextList^).Count - 1 do
            begin
                if (result <> '') and (NCposex('.' + (PlainTextList^)[ExtI],
                    result, ParamPos + 1) > 0) then
                begin
                    result := '';
                    exit;
                end;
            end;
        end;

        //���Ŀ¼������
        StringReplaceEx(result, '...', '..', [rfReplaceAll]);
        StringReplaceEx(result, '/../', '/', [rfReplaceAll]);
        //������opencpu.com/../index.aspxʱ����취
        StringReplaceEx(result, '/./', '/', [rfReplaceAll]);
        StringReplaceEx(result, '///', '//', [rfReplaceAll]);
        StringReplaceEx(result, '??', '?', [rfReplaceAll]);
        StringReplaceEx(result, '&&', '&', [rfReplaceAll]);
        StringReplaceEx(result, '?&', '?', [rfReplaceAll]);

        //ȥ�����һ����Ч�ַ�
        doc := '';
        while (result <> '') and (result <> doc) do
        begin
            doc := result;
            result := StrTrimCharsRight(result, ['?', '&', '+', '*', '-', '_',
                '=']);
        end;
    end else
        result := '';
end;

function CHtmlParser.IsWebPageExt(const filename: string): boolean;
var ext             : string;
begin
    // ����չ�������ж�����ļ��Ƿ�����ҳ,���ϸ���ж�
    ext := GetDomainExt(filename);
    result := ((ext <> '') and ((PlainTextList^).IndexOf(ext) >= 0));
end;

function CHtmlParser.GetWebDirectory(const url: string): string;
//------------------------------------------------------------------------------
//���ر���Ŀ¼,��б��,��Ч���ؿ��ַ���:ע�� ����http:// �յ�ַ������RecognizeUrl
//�������Ѿ�������ˡ�
//------------------------------------------------------------------------------
begin
    result := RecognizeUrl(url);
    if (result <> '') then
    begin
        Delete(result, Pos('?', result), Length(result));
        Delete(result, Pos('&', result), Length(result));
        //Ϊhttp://www.163.com���ָ�ʽ���ϸ�Ŀ¼
        if (LastChar(result) <> '/') then
        begin
            if (RightPos('/', result) = Pos('://', result) + 2)
                or (GetDomainExt(GetDocNameFromUrl(result)) = '') then
                result := result + '/';
        end;
        //����,����Ӧ�ö������Ŀ¼·����,���ļ���ɾ��
        Delete(result, RightPos('/', result) + 1, Length(result));
    end;
end;

function CHtmlParser.RecognizeUrl(url: string): string;
//------------------------------------------------------------------------------
//URLʶ����:����һ��������HTTP��Դ��λ��,�ú���ֻʶ����������URL,
//��./index.htm���������ڴ���Χ��,��������Ҫһ���ο���ַ����һ������.
//��:.com.net.cn.org.gov.ac.edu.biz.info.mobi.hk.tw.jp.name.pro
//------------------------------------------------------------------------------
var DmExt           : string;
begin
    url := Trim(url);
    result := '';

    if (url <> '') then
    begin
        if IsBasicURL(url) then
        begin
            //�����Ѿ�����Э����,������URL����ʶ��,����Ҫ��֤
            if (IsHealthDomain(GetDomainRoot(url))) then
                result := url
        end else begin
            DmExt := GetDomainExt(GetDomainRoot(url));
            if (DmExt <> '') and ((ExtList^).IndexOf(DmExt) >= 0) then
                result := 'http://' + url;
        end;
    end;
end;

function CHtmlParser.Relative2Native(const Url: string): string;
var
    TmpStr          : string;
    UpPos           : integer;
    SlashA          : integer;
    SlashB          : integer;
begin
    {
    www.aa.com../ss.htm
    www.aa.com/ass/rrr/../btv.html
    www.aa.com/../cnn.asp
    www.aaa.com///nbcv//../jm.php
    }
    Result := Url;
    UpPos := Pos('../', Result);

    if (UpPos > 0)
        and (
        ((pos('?', Url) > 0) and (pos('?', Url) < UpPos)) or
        ((pos('#', Url) > 0) and (pos('#', Url) < UpPos))
        )
        then
    begin
        Result := '';
        Exit;                           //����������������ڲ�������ǩ����,������
    end;

    while (UpPos > 0) do
    begin
        //��:opencpu.com/(SlashA)index(SlashB)/../../index.asp
        // A���λ����Bǰ��б��
        TmpStr := Copy(Result, 1, UpPos - 1);
        //�õ�:opencpu.com/(SlashA)index(SlashB)/
        if (TmpStr <> '') then
        begin
            TmpStr := ReverseString(TmpStr);
            SlashB := Pos('/', TmpStr);
            SlashA := sposex('/', TmpStr, SlashB + 1);
            if (SlashB > 0) and (SlashA > SlashB) then
            begin
                if (SlashB = 1) then
                begin
                    Delete(Result, UpPos - SlashA, SlashA + Length('..'));
                end else
                begin
                    Delete(Result, UpPos - SlashB, SlashB + Length('..'));
                end;
            end else
            begin
                StringReplaceEx(Result, '../', '/');
                Break;
            end;
        end else
        begin
            Result := '';
            Exit;
        end;

        UpPos := Pos('../', Result);
    end;

    StringReplaceEx(Result, '//', '/');
end;

procedure CHtmlParser.ProcessTagItem(const item: PAnsiString);
var Tag, Prop1, Prop2, Prop3, URL: string;
    p1              : integer;
begin
    //-------------------------------------------------------------------------
    //  ����:����a href='163.com' target='_blank'
    //  ��ʱ:Tag��ֵΪa
    //-------------------------------------------------------------------------
    inc(FEventCount);
    if item^ <> '' then
    begin
        p1 := pos(#32, item^);
        Tag := AnsiLowerCase(Copy(item^, 1, p1 - 1));
        if Tag = 'meta' then
        begin
            //����META��Ϣ
            Prop1 := GetKeyValue(item, 'http-equiv');
            Prop2 := GetKeyValue(item, 'content');
            Prop3 := GetKeyValue(item, 'name');
            //Like this : 'text/html; charset=gb2312'
            if NCpos('Content-Type', Prop1) > 0 then
                FDOCTYPE := Prop2
            else if NCpos('refresh', Prop1) > 0 then
                URL := Copy(Prop2, NCpos('URL=', Prop2) + 4, Length(Prop2));
            URL := VirginTouch(URL, FDocumentUrl);
            if (URL <> '') and Assigned(OnFreshRedirect) then
                OnFreshRedirect(URL);
            if NCpos('description', Prop3) > 0 then
                FDiscription := Prop2;
            if NCpos('keywords', Prop3) > 0 then
                FKeywords := Prop2;
            if NCpos('GENERATOR', Prop3) > 0 then
                FDevelopeTool := Prop2;
            if NCpos('author', Prop3) > 0 then
                FAuthor := Prop2;
            if NCpos('copyright', Prop3) > 0 then
                FCopyRight := Prop2;
        end
        else if Tag = 'script' then
        begin
            //����Ƕ��ű��ļ�
            if not FignoreJs then
            begin
                Prop1 := GetKeyValue(item, 'src');
                URL := VirginTouch(Prop1, FDocumentUrl);
                if (URL <> '') and Assigned(FonEmbedJs) then
                    FonEmbedJs(URL);
            end;
        end
        else if (Tag = 'iframe') or (Tag = 'frame') then
        begin
            //����Ƕ����ҳ��
            if not FignoreFrame then
            begin
                Prop1 := GetKeyValue(item, 'src');
                URL := VirginTouch(Prop1, FDocumentUrl);
                if (URL <> '') and Assigned(FonEmbedFrame) then
                    FonEmbedFrame(URL);
            end;
        end
        else if Tag = 'a' then
        begin
            //����������
            Prop1 := GetKeyValue(item, 'href');
            Prop2 := GetKeyValue(item, 'title');
            Prop3 := GetKeyValue(item, 'target');
            URL := VirginTouch(Prop1, FDocumentUrl);
            if (URL <> '') and Assigned(FOnFindUrl) then
                FOnFindUrl(URL, Prop2, Prop3);
            inc(LinksCount);
        end
        else if Tag = 'img' then
        begin
            //���������ͼƬ
            Prop1 := GetKeyValue(item, 'src');
            Prop2 := GetKeyValue(item, 'alt');
            Prop3 := GetKeyValue(item, 'title');
            URL := VirginTouch(Prop1, FDocumentUrl);
            if (URL <> '') and Assigned(FonImage) then
                FonImage(URL, Prop2, Prop3);
            inc(ImagesCount);
        end
        else if Tag = 'embed' then
        begin
            //����Ƕ���ļ�
            if not FignoreEmbed then
            begin
                Prop1 := GetKeyValue(item, 'src');
                Prop2 := GetKeyValue(item, 'alt');
                Prop3 := GetKeyValue(item, 'title');
                URL := VirginTouch(Prop1, FDocumentUrl);
                if (URL <> '') and Assigned(FonEmbed) then
                    FonEmbed(URL, Prop2, Prop3);
                inc(EmbedsCount);
            end;
        end
        else
            //���������ʱ������,����һЩ��ǩ������Ϣ��Ƭʱͳһ����;
    end;
end;

procedure CHtmlParser.LoadHtml(const html: PAnsiString);
begin
    //Ϊ���������ֵ
    Fhtml := html;

    FDOCTYPE := '';
    FCopyRight := '';
    FTitle := '';
    FAuthor := '';
    FDevelopeTool := '';
    Fbgsound := '';
    FKeywords := '';
    FDiscription := '';
end;

procedure CHtmlParser.SetDocumentUrl(const Value: string);
begin
    FDocumentUrl := Value;
end;

destructor CHtmlParser.Destroy;
begin
    ExtList := nil;
    PlainTextList := nil;
    inherited Destroy;
end;

end.
