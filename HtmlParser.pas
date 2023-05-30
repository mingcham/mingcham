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
    //主类:实现HTML网页的分析分解
    //----------------------------------------------------------------------------
    CHtmlParser = class(TComponent)
    private
        Fhtml: PAnsiString;             //网页源代码
        FDocumentUrl: string;           //发现链接时,产生新URL的基准
        FMaxParse: integer;             //最多分析多少个连接后放弃
        FDOCTYPE: string;               //网页语言所遵循的规定
        FCopyRight: string;             //网页使用的字符集
        FTitle: string;                 //网页的标题 <title>或document.title均可
        FAuthor: string;                //网页的作者
        FDevelopeTool: string;          //网页的编写工具
        Fbgsound: string;
        FKeywords: string;              //网页的关键字
        FDiscription: string;           //网页的描述
        FignoreJs: boolean;
        FignoreFrame: boolean;
        FignoreEmbed: boolean;
        FEnableLinkCheck: boolean;
        //进度指示变量.
        FParseWebPagePoint: integer;
        FEventCount: integer;
        FProgressPos: integer;
        //解析部分
        FonEmbedJs: TFindIncludeJS;
        FonEmbedFrame: TFindIncludeFrame;
        FonRefreshDirect: TFindFreshRedirectEvent;
        FOnFindUrl: TFindLink;
        FonImage: TFindImage;
        FonEmbed: TFindEmbed;
        //解析完成部分
        FonComplete: TParseComplete;
        FonProgress: TParseProgress;
        FParserVersion: string;
        FMaxUrlLen: integer;
        procedure SetDocumentUrl(const Value: string);
        procedure ProcessTagItem(const item: PAnsiString);
        //设置组件当前的HTML代码,会初始组件所有属性值
    protected
        //内部通用过程,调试的时候可放于public内
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
        //各递归函数结果部分
        EmbedsCount: integer;
        LinksCount: integer;
        ImagesCount: integer;
        ExtList: ^TStringList;          //可以接受的域名后缀
        PlainTextList: ^TStringList;    //可以接受的域名后缀
        constructor create(Aowner: Tcomponent); override;
        destructor Destroy; override;
        function Parse(): integer;      //内部函数,递归所有资源
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
    //网页的分析结果
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
        // 查找标签的开始和结束
        //-------------------------------------------------------------------------
        i := sPosex('<', Fhtml^, FParseWebPagePoint);
        j := sPosex('>', Fhtml^, i);
        if (j > FParseWebPagePoint) and (i > 0) then
        begin
            //---------------------------------------------------------------------
            //这里使用了硬编码方式处理Html文档,灵活性降低了,下面是可能碰到的例子:
            //<a href='163.com'>(这种标签里面有空格和等号,所以这种闭合标签里面是有信息的)163</a>(这种抛弃)
            //---------------------------------------------------------------------
            FParseWebPagePoint := j;
            //注意,a can't to Z,ASCII separated.(测试结果)
            if (Fhtml^[i + 1] in ['a'..'z', 'A'..'Z']) then
            begin
                TagItem := Copy(Fhtml^, (i + 1), ((j - i) - 1));
                if (pos('=', TagItem) > 0) and (pos(#32, TagItem) > 0) and
                    (pos('<', TagItem) <= 0) then
                    ProcessTagItem(@TagItem);
            end;
            //---------------------------------------------------------------------
            // 递归链接时需要判断进度是否大于1/7,最多显示7次进度变化
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
    //得到网页标题
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

    //是否有背景音乐8,8+-1
    i := NCposex('<bgsound', Fhtml^, 0);
    j := NCposex('>', Fhtml^, (i + 7));
    if (j > i) and (i > 0) then
    begin
        BgsoundStrOrgin := Copy(Fhtml^, (i + 9), ((j - i) - 9));
        Fbgsound := GetKeyValue(@BgsoundStrOrgin, 'src');
    end else
        Fbgsound := '';

    //删除所有脚本
    ClearNoise(Fhtml, '<script', '</script>');
    //删除风格
    ClearNoise(Fhtml, '<style', '</style>');
    //删除注释
    ClearNoise(Fhtml, '<!--', '-->');
    //删除标题
    ClearNoise(Fhtml, '<title', '</title>');
end;

function CHtmlParser.Parse: integer;
begin
    //-------------------------------------------------------------------------
    //顺序说明:最先解析得到网页标题，背景音乐等信息
    //注意:这个函数运算量较大.
    //-------------------------------------------------------------------------
    ResetPoint;
    GetPageInfo;
    if assigned(onProgress) then
        onProgress(0, 20, 3);
    if Length(Fhtml^) > 13 then
        //<a href=></a>刚好13个字符,这个条件不满足怎么分析链接呢
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
    //首次处理域名:当前网页地址为me,正在识别为you.
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

    //首先看是否为域名,若能直接识别则直接跳过.
    TmpPath := RecognizeUrl(you);
    if (TmpPath <> '') then
    begin
        //成功识别出地址,不需要处理.
        result := ValidateUrl(TmpPath);
    end else begin
        //不认识you,那就继续识别.
        if you[1] = '?' then
        begin
            if (pos('?', me) > 0) then  //你仅仅是我加个参数,我已经有参数吗?
                result := Copy(me, 1, pos('?', me) - 1) + you //有
            else
                result := me + you;     //我压根就没有参数
        end else if you[1] = '&' then
        begin
            if pos('?', me) > 0 then    //还是当前页加个参数,我有参数吗?
                result := Copy(me, 1, pos('?', me)) + Copy(you, 2, Length(you))
            else
                result := me + '?' + Copy(you, 2, Length(you));
        end else if you[1] = '/' then
        begin
            TmpPath := Copy(me, 1, posex('/', me, pos('://', me) + 3) - 1);
            //相对根目录的路径
            if (TmpPath <> '') then
                result := TmpPath + you
            else
                result := '';
        end else begin
            TmpPath := GetWebDirectory(me); //相对当前目录
            if (TmpPath <> '') then
                result := TmpPath + you
            else
                result := '';
        end;
    end;
    //-------------------------------------------------------------------------
    //  2:对中间地址进行整理
    //-------------------------------------------------------------------------
    if (pos('://', result) > 0) then
    begin
        TmpPath := Copy(result, pos('://', result) + 3, length(result));
        //不带协议的地址
        protocol := Copy(result, 1, pos('://', result) - 1); //协议
        //  处理目录上跳
        TmpPath := Relative2Native(TmpPath);

        // 整理目录名
        StringReplaceEx(TmpPath, '//', '/', [rfReplaceAll]);
        if (TmpPath <> '') then
            result := ValidateUrl(protocol + '://' + TmpPath)
        else
            result := '';
        // 路径关系整理完成
    end else
        result := '';
end;

function CHtmlParser.ValidateUrl(const Path: string): string;
//------------------------------------------------------------------------------
//注意:这个函数存在问题,无法判别http://www.opencpu.com/bbs是个目录还是个文件,所以
//默认是目录,但是万一是个没有扩展名的文件,那就错远了,同时http://qq.com/index.net
//类似这样的会被判断成文件,但是有可能是错误的.
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
            //存在一个最后斜杠
            //----------------------------------------------------------------------
            doc := GetDocNameFromUrl(result);
            if ((ParamPos - SlashPos) > 1) and (not (pos('.', doc) > 0))
                and (not IsWebPageExt(doc)) then
                insert('/', result, ParamPos);
        end else if (SlashPos = (pos('://', result) + 2)) then
        begin
            //压根就不存在表示域的没有斜杠
            if (ParamPos > 0) then
                insert('/', result, ParamPos)
                    //给http://www.163.com?qq=123插入一撇
            else if (SlashPos > 0) then
                result := result + '/'  //给http://www.163.com补上一撇/
            else begin
                result := '';
                exit;
            end;
        end else begin
            result := '';
            exit;
        end;
        //----------------------------------------------------------------------
        // 如下几种连接格式需要忽略
        //----------------------------------------------------------------------
        //删除书签内容

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

        //参数后面跟的连接URL
        ParamPos := pos('?', result);
        if (ParamPos > 0) then
        begin
            //参数?后面还有?号
            if (sposex('?', result, ParamPos + 1) > 0) then
            begin
                result := '';
                exit;
            end;
            //如果参数中出现常见的,.com,.net,.org这些,认为是跳转,不收录该地址
            for ExtI := 0 to (ExtList^).Count - 1 do
            begin
                if (result <> '') and (NCposex('.' + (ExtList^)[ExtI], result,
                    ParamPos + 1) > 0) then
                begin
                    result := '';
                    exit;
                end;
            end;
            //如果参数中出现常见的,.htm,.php,.aspx这些,认为是跳转,不收录该地址
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

        //完成目录名整理
        StringReplaceEx(result, '...', '..', [rfReplaceAll]);
        StringReplaceEx(result, '/../', '/', [rfReplaceAll]);
        //出现如opencpu.com/../index.aspx时解决办法
        StringReplaceEx(result, '/./', '/', [rfReplaceAll]);
        StringReplaceEx(result, '///', '//', [rfReplaceAll]);
        StringReplaceEx(result, '??', '?', [rfReplaceAll]);
        StringReplaceEx(result, '&&', '&', [rfReplaceAll]);
        StringReplaceEx(result, '?&', '?', [rfReplaceAll]);

        //去除最后一个无效字符
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
    // 从扩展名大致判断这个文件是否是网页,不严格的判断
    ext := GetDomainExt(filename);
    result := ((ext <> '') and ((PlainTextList^).IndexOf(ext) >= 0));
end;

function CHtmlParser.GetWebDirectory(const url: string): string;
//------------------------------------------------------------------------------
//返回本级目录,带斜杠,无效返回空字符串:注意 避免http:// 空地址问题在RecognizeUrl
//过程中已经避免掉了。
//------------------------------------------------------------------------------
begin
    result := RecognizeUrl(url);
    if (result <> '') then
    begin
        Delete(result, Pos('?', result), Length(result));
        Delete(result, Pos('&', result), Length(result));
        //为http://www.163.com这种格式补上根目录
        if (LastChar(result) <> '/') then
        begin
            if (RightPos('/', result) = Pos('://', result) + 2)
                or (GetDomainExt(GetDocNameFromUrl(result)) = '') then
                result := result + '/';
        end;
        //好了,现在应该都有相对目录路径了,把文件名删了
        Delete(result, RightPos('/', result) + 1, Length(result));
    end;
end;

function CHtmlParser.RecognizeUrl(url: string): string;
//------------------------------------------------------------------------------
//URL识别函数:返回一个完整的HTTP资源定位符,该函数只识别含有域名的URL,
//像./index.htm这样的则不在处理范围内,这样的需要一个参考地址和它一起运算.
//例:.com.net.cn.org.gov.ac.edu.biz.info.mobi.hk.tw.jp.name.pro
//------------------------------------------------------------------------------
var DmExt           : string;
begin
    url := Trim(url);
    result := '';

    if (url <> '') then
    begin
        if IsBasicURL(url) then
        begin
            //本身已经带有协议名,这样的URL不必识别,但需要验证
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
        Exit;                           //假设上跳命令出现在参数或书签后面,需跳过
    end;

    while (UpPos > 0) do
    begin
        //例:opencpu.com/(SlashA)index(SlashB)/../../index.asp
        // A点的位置是B前的斜线
        TmpStr := Copy(Result, 1, UpPos - 1);
        //得到:opencpu.com/(SlashA)index(SlashB)/
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
    //  例如:输入a href='163.com' target='_blank'
    //  此时:Tag的值为a
    //-------------------------------------------------------------------------
    inc(FEventCount);
    if item^ <> '' then
    begin
        p1 := pos(#32, item^);
        Tag := AnsiLowerCase(Copy(item^, 1, p1 - 1));
        if Tag = 'meta' then
        begin
            //处理META信息
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
            //处理嵌入脚本文件
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
            //处理嵌入框架页面
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
            //处理超级连接
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
            //处理包含的图片
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
            //处理嵌入文件
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
            //其他情况暂时不处理,另外一些标签将在信息分片时统一处理;
    end;
end;

procedure CHtmlParser.LoadHtml(const html: PAnsiString);
begin
    //为解析组件赋值
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
