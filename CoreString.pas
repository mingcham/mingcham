unit CoreString;

interface

uses
    Classes, Variants, SysUtils, StrUtils, windows, JclStrings;

procedure StringReplaceEx(var S: string; const Search, Replace: string; const
    Flags: TReplaceFlags = [rfReplaceAll]);
procedure LatinChar(var HtmlCode: string);
procedure FormatHtml(var htmlcode: string);

function NCpos(const sub, source: string): integer;
function NCposex(const sub, source: string; index: integer): integer;
function sposex(const sub, source: string; index: integer): integer;
function GetDocNameFromUrl(url: string): string;
function GetDocumentName(const doc: string): string;
function LastChar(const str: string): string;
function IsNumeric(const InStr: string): boolean;
function SqlFitness(sql: string): string;
function RightPos(const sub, source: string): integer;
function IsHttpURL(const url: string): boolean;
function IsBasicURL(const url: string): boolean;
function IsLocalHost(const url: string): boolean;
function GetDomainRoot(url: string): string;
function GetDomainExt(const url: string): string;
function ContentPR(content: string): integer;
function LeastUrlRequest(const url: string): boolean;
function IsHealthDomain(const dm: string): boolean;
function IsValidVarString(OleString: Variant): Boolean;
function GetDBFileFromConnStr(ConStr: string): string;
function DecodeUtf8Str(const S: UTF8String): WideString;
function AutoConvert2Ansi(const pSrc: PAnsiString): string;
function HashClip32(const input: PAnsiString): string;
function StringToIntDef(const S: string; const Default: Integer = 0): integer;
function LowAndTrim(const str: string): string;
function SetDefaultSqlStr(const str: string): string;
function SocketMessage(const ErrorNo: Cardinal): string;
procedure ClearNoise(const Source: PAnsiString; const StartTag,
    EndTag: string);
function CountStr(const Sub, Source: string; const exclude: string = ''):
    Integer;

implementation

procedure StringReplaceEx(var S: string; const Search, Replace: string; const
    Flags: TReplaceFlags = [rfReplaceAll]);
var
    NewPosition     : integer;
    SrcLength       : integer;
    NewS            : string;
    NewSearch       : string;
    NewReplace      : string;
    SingleAcc       : Boolean;
begin
    if ((S = '') or (Search = '')) then
    begin
        Exit;
    end;

    if (rfIgnoreCase in Flags) then
    begin
        NewS := AnsiLowerCase(S);
        NewSearch := AnsiLowerCase(Search);
        NewReplace := AnsiLowerCase(Replace);
    end else
    begin
        NewS := S;
        NewSearch := Search;
        NewReplace := Replace;
    end;

    if (Pos(NewSearch, NewReplace) > 0) then
    begin
        Exit;
    end;

    SrcLength := Length(NewSearch);
    SingleAcc := (SrcLength = 1) or (StringReplace(NewSearch, NewSearch[1], '',
        [rfReplaceAll]) = '');

    if SingleAcc then
    begin
        NewSearch := NewSearch + NewSearch + NewSearch + NewSearch + NewSearch +
            NewSearch + NewSearch + NewSearch + NewSearch + NewSearch + NewSearch
            + NewSearch + NewSearch + NewSearch + NewSearch + NewSearch;
        repeat
            NewPosition := PosEx(NewSearch, NewS, 1);
            while (NewPosition > 0) do
            begin
                if (NewPosition > SrcLength) then
                    NewPosition := PosEx(NewSearch, NewS, NewPosition -
                        SrcLength)
                else
                    NewPosition := PosEx(NewSearch, NewS, NewPosition);
                Delete(NewS, NewPosition, SrcLength);
                Insert(NewReplace, NewS, NewPosition);
                Delete(S, NewPosition, SrcLength);
                Insert(Replace, S, NewPosition);
            end;
            NewSearch := Copy(NewSearch, 1, Length(NewSearch) div 2);
        until (Length(NewSearch) < SrcLength);
    end else
    begin
        NewPosition := PosEx(NewSearch, NewS, 1);
        while (NewPosition > 0) do
        begin
            if (NewPosition > SrcLength) then
                NewPosition := PosEx(NewSearch, NewS, NewPosition - SrcLength)
            else
                NewPosition := PosEx(NewSearch, NewS, NewPosition);
            Delete(NewS, NewPosition, SrcLength);
            Insert(NewReplace, NewS, NewPosition);
            Delete(S, NewPosition, SrcLength);
            Insert(Replace, S, NewPosition);
        end;
    end;
end;

function GetDomainRoot(url: string): string;
//获得一个URL地址的域
var p1              : integer;
begin
    //http://user:pass@www.163.com:8080/music/chs/index.aspx?mid=23081712
    //    p1     p2   p3          p4   p5
    result := '';
    if LeastUrlRequest(url) then
    begin
        //去掉协议
        p1 := pos('://', url);
        if (p1 > 0) then
            Delete(url, 1, p1 + 2);
        p1 := pos('/', url);
        if (p1 > 1) then
        begin
            //得到主机地址
            url := Copy(url, 1, p1 - 1);
            if url <> '' then
            begin
                //去掉用户名和密码
                p1 := pos('@', url);
                if (p1 > 0) then
                    Delete(url, 1, p1);
                //去掉端口
                Delete(url, pos(':', url), Length(url));
            end;
            if IsLocalHost(url) then
                result := ''
            else
                result := url;
        end else if (length(url) >= 3) and (url[1] <> '/') then
            //至少是a.b,长度大于等于3才满足域名或文件名的形式
        begin
            if IsLocalHost(url) then
                result := ''
            else
                result := url;
        end;
    end;
end;

function GetDomainExt(const url: string): string;
//获得根域或扩展名
begin
    //注意:在调用前必须先调用GetDomainRoot
    result := '';
    if (RightPos('.', url) > 0) then
        result := Copy(url, RightPos('.', url) + 1, Length(url));
end;

//判断URL是否为HTTP协议

function IsHttpURL(const url: string): boolean;
var
    Str             : string;
    dom             : string;
begin
    Str := AnsiLowerCase(Trim(url));
    dom := GetDomainRoot(Str);

    result := ((pos('http://', Str) = 1) or (pos('https://', Str) = 1)) and
        IsHealthDomain(dom);
end;

function IsBasicURL(const url: string): boolean;
begin
    result := (pos('://', url) > 0);
end;

function IsLocalHost(const url: string): boolean;
begin
    Result := (pos('127.1', url) = 1) or (pos('127.0.0.1', url) = 1) or
        (NCpos('localhost', url) = 1)
end;

function NCpos(const sub, source: string): integer;
//不区分大小写的pos
begin
    result := Pos(AnsiLowerCase(sub), AnsiLowerCase(source));
end;

function NCposex(const sub, source: string; index: integer): integer;
//不区分大小写的posex
begin
    if (source = '') or (sub = '') then
        result := -1
    else
        result := posex(AnsiLowerCase(sub), AnsiLowerCase(source), index);
end;

function sposex(const sub, source: string; index: integer): integer;
//安全的posex
begin
    if (source = '') or (sub = '') then
        result := -1
    else
        result := posex(sub, source, index);
end;

function SqlFitness(sql: string): string;
//替换SQL语句无法正常工作的字符
begin
    if sql <> '' then
    begin
        StringReplaceEx(sql, #34, #32, [rfReplaceAll]);
        StringReplaceEx(sql, #39, #32, [rfReplaceAll]);
    end;
    result := SetDefaultSqlStr(sql);
end;

function GetDocNameFromUrl(url: string): string;
//形如http://www.163.com/so?或163.com/so/index.htm?qq=254939297
//分别返回so,index.htm
var p1, p2, p3      : integer;
begin
    result := '';
    if LeastUrlRequest(url) then
    begin
        p3 := Pos('?', url);            //参数位置
        p2 := Pos('://', url);          //HTTP://位置
        if (p3 > p2) and (p2 > 0) then
        begin
            //http://www.163.com/index.aspx?q=12345
            url := copy(url, p2 + 3, (p3 - p2) - 3);
        end else if (p3 > p2) then
        begin
            //www.163.com/index.aspx?q=12345
            url := copy(url, 1, p3 - 1);
        end else if (p2 > 0) and (p3 <= 0) then
        begin
            //www.163.com/index.aspx
            url := copy(url, p2 + 3, length(url));
        end else if (p2 <= 0) and (p3 <= 0) then
        begin
            //www.163.com/index.aspx Keep!
        end else
            url := '';
        p1 := RightPos('/', url);       //斜杠位置
        if (p1 > 0) and (p1 < Length(url)) then
            result := Copy(url, p1 + 1, Length(url));
    end;
end;

function GetDocumentName(const doc: string): string;
//形如www.163.com/so?或163.com/so/index.htm
//在调用前必须先调用上一函数
begin
    result := Copy(doc, 1, RightPos('.', doc) - 1);
end;

function LastChar(const str: string): string;
//返回参数字符串的最后的一个字符
begin
    result := '';
    if (str <> '') then
    begin
        result := str[length(str)];
    end;
end;

function IsNumeric(const InStr: string): boolean;
//判断是否为纯数字
var i               : integer;
begin
    result := true;
    for i := 1 to Length(InStr) do
    begin
        if not (InStr[i] in ['0'..'9']) then
        begin
            result := false;
            exit;
        end;
    end;
end;

procedure LatinChar(var HtmlCode: string);
//替换这128个字符很耗时，甚至可以和下载网页的时间不相上下
var i               : integer;
begin
    for i := 127 downto 1 do
    begin
        StringReplaceEx(HtmlCode, Format('&#%d;', [i]), Chr(i), [rfReplaceAll]);
    end;
    for i := 127 downto 1 do
    begin
        StringReplaceEx(HtmlCode, Format('&#%d', [i]), Chr(i), [rfReplaceAll]);
    end;
end;

procedure FormatHtml(var htmlcode: string);
//格式化HTML
begin
    //这两处替换为信息片算法作准备,防止意外分片
    StringReplaceEx(HtmlCode, #9, '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, '　', '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, #10, '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, #13, '', [rfReplaceAll]);
    //--------------------------------------------------------------------------
    //   处理HTML特殊规定字符
    //--------------------------------------------------------------------------
    StringReplaceEx(HtmlCode, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&nbsp;', #32, [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&reg;', #32, [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&copy;', #32, [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '&raquo;', '', [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, '<![CDATA[', '', [rfReplaceAll, rfIgnoreCase]);
    StringReplaceEx(HtmlCode, ']]>', '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, '< ', '<', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, ' >', '>', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, '= ', '=', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, ' =', '=', [rfReplaceAll]);
end;

function RightPos(const sub, source: string): integer;
//从右边开始的查找
var i               : integer;
begin
    result := -1;
    if (sub <> '') and (source <> '') then
    begin
        i := pos(sub, AnsiReverseString(source));
        if i > 0 then
            result := (length(source) - i) + 1;
    end;
end;

function ContentPR(content: string): integer;
//从文本内容的有效性获得分值，基本上都能得高分,满分:100
var i, j            : integer;
begin
    j := 0;

    StringReplaceEx(content, '年', '', [rfReplaceAll]);
    StringReplaceEx(content, '月', '', [rfReplaceAll]);
    StringReplaceEx(content, '日', '', [rfReplaceAll]);

    for i := 1 to length(content) do
    begin
        if (j < 100) and (not (content[i] in ['0'..'9', '/', '-', ':', '.', #8,
            #10, #13, #32, #34, #39])) then
            inc(j)
        else if j >= 100 then
            break;
    end;
    result := j;
end;

function LeastUrlRequest(const url: string): boolean;
//资源定位符的最低要求,如果出现在异常字符列表中，则宣告False
var i               : integer;
begin
    Result := true;
    if url <> '' then
    begin
        for i := 1 to Length(url) do
        begin
            if (url[i] in ['(', ')', '[', ']', '{', '}', '\', '<', '>', '|',
                '+', #10, #13, #34, #39]) then
            begin
                Result := false;
                exit;
            end;
        end;
    end else
        Result := false;
end;

function IsHealthDomain(const dm: string): boolean;
//判断一个域名是否正常,可以是域名,IP,可以带端口,调用这个函数必须首先取得域名
var i               : integer;
begin
    Result := true;
    if (dm <> '') then
    begin
        for i := 1 to Length(dm) do
        begin
            //注意,a can't to Z,ASCII separated.(测试结果)
            if not (dm[i] in ['a'..'z', 'A'..'Z', '-', '.', '0'..'9']) then
            begin
                Result := false;
                exit;
            end;
        end;
    end else
        Result := false;
end;

function SetDefaultSqlStr(const str: string): string;
//有些字段被设计为允许空,然而实际上不同的版本OLEDB却不一定支持
begin
    if trim(str) = '' then
        result := #32
    else
        result := Trim(str);
end;

function IsValidVarString(OleString: Variant): Boolean;
//测试varant是否为有效字符串
begin
    result := (VarIsStr(OleString)) and (trim(OleString) <> '');
end;

function GetDBFileFromConnStr(ConStr: string): string;
//字符处理函数,输入adodb连接字串,输出数据库地址.
begin
    result := '';
    if (ConStr <> '') and (NCPos('Microsoft.Jet.OLEDB.', ConStr) > 0) then
    begin
        if posex(';', ConStr, NCpos('Data Source=', ConStr)) > 0 then
            ConStr := copy(ConStr, NCpos('Data Source=', ConStr) + 12,
                (posex(';', ConStr, NCpos('Data Source=', ConStr)) -
                NCpos('Data Source=', ConStr) - 12))
        else
            ConStr := copy(ConStr, NCpos('Data Source=', ConStr) + 12,
                Length(ConStr));
        if (pos(#34, ConStr) < 1) and (pos(#39, ConStr) < 1) then
            result := ConStr;
    end;
end;

function DecodeUtf8Str(const S: UTF8String): WideString;
var lenSrc, lenDst  : Integer;
begin
    lenSrc := Length(S);
    if (lenSrc = 0) then
        Exit;
    lenDst := MultiByteToWideChar(CP_UTF8, 0, Pointer(S), lenSrc, nil, 0);
    SetLength(Result, lenDst);
    MultiByteToWideChar(CP_UTF8, 0, Pointer(S), lenSrc, Pointer(Result),
        lenDst);
end;

function AutoConvert2Ansi(const pSrc: PAnsiString): string;
var
    Str             : string;
    P1              : Integer;
begin
    Str := pSrc^;
    Str := AnsiLowerCase(Str);

    P1 := Pos('<body', Str);
    if (P1 > 0) then
        Str := AnsiLeftStr(Str, P1);

    Str := StringReplace(Str, #32, '', [rfReplaceAll]);
    Str := StringReplace(Str, #39, '', [rfReplaceAll]);
    Str := StringReplace(Str, #34, '', [rfReplaceAll]);
    Str := StringReplace(Str, #9, '', [rfReplaceAll]);

    if (pos(AnsiLowerCase('charset=UTF-8'), Str) > 0) then
    begin
        Result := DecodeUtf8Str(pSrc^);
    end else
    begin
        if (pos(AnsiLowerCase('charset=gb2312'), Str) > 0) or
            (pos(AnsiLowerCase('charset=GBK'), Str) > 0) or
            (pos(AnsiLowerCase('charset=ISO-8859'), Str) > 0) then
        begin
            Result := pSrc^;
        end else
        begin
            Result := '';
        end;
    end;
end;

function HashClip32(const input: PAnsiString): string;
//产生32字节字串，后附原始字符串长度
var len, i          : integer;
    LenDiv          : Single;
    TmpStr          : string;
begin
    //-------------------------------------------------------------------------
    //注意,这里的字节数直接关系到以后的内存占用,比如512*32*3即最多占用48KB
    //-------------------------------------------------------------------------
    len := length(input^);
    if (len > 32) then
    begin
        setlength(TmpStr, 32);          //分配空间
        LenDiv := len / 32;             //该数字一定大于1

        for i := 1 to 32 do
        begin
            TmpStr[i] := input^[Trunc(LenDiv * i)];
        end;

        result := TmpStr + IntToStr(len)
    end else if input^ <> '' then
        result := input^ + IntToStr(len)
    else
        result := '';

    for i := 1 to length(result) do
    begin
        if (not (result[i] in ['a'..'z', 'A'..'Z', '0'..'9'])) then
        begin
            result[i] := chr((ord(result[i]) mod 26) + ord('a'));
        end;
    end;
end;

function StringToIntDef(const S: string; const Default: Integer = 0): integer;
//同C语言的ATOI(),将字符串转为整形
begin
    if (Trim(s) <> '') then
        result := StrToIntDef(S, Default)
    else
        result := Default;
end;

function LowAndTrim(const str: string): string;
begin
    result := AnsiLowerCase(Trim(str));
end;

function SocketMessage(const ErrorNo: Cardinal): string;
const
    ErrorTextBufLength = 256;
var
    sErrorText      : array[0..ErrorTextBufLength] of char;
begin
    ZeroMemory(@sErrorText, ErrorTextBufLength);
    FormatMessage(
        FORMAT_MESSAGE_FROM_SYSTEM,
        nil,
        ErrorNo,
        0,
        sErrorText,
        ErrorTextBufLength,
        nil
        );
    result := Trim(string(sErrorText));
    StringReplaceEx(result, #13, '', [rfReplaceAll]);
    StringReplaceEx(result, #10, '', [rfReplaceAll]);
end;

procedure ClearNoise(const Source: PAnsiString; const StartTag,
    EndTag: string);
var TagPos, EndTagPos, TagLen: integer;
begin
    if (Source^) <> '' then
    begin
        TagPos := NCpos(StartTag, (Source^));
        EndTagPos := NCPosex(EndTag, (Source^), TagPos);
        TagLen := Length(EndTag);
        while (TagPos > 0) and (EndTagPos > TagPos) do
        begin
            delete(Source^, TagPos, (EndTagPos - TagPos) + TagLen);
            if (Source^) <> '' then
            begin
                TagPos := NCpos(StartTag, (Source^));
                EndTagPos := NCPosex(EndTag, (Source^), TagPos);
            end else
                exit;
        end;
    end;
end;

function CountStr(const Sub, Source: string; const exclude: string = ''):
    Integer;
var
    deltaA, deltaB  : string;
begin
    if (Sub <> '') then
    begin
        deltaA := Source;
        StringReplaceEx(deltaA, exclude, '', [rfReplaceAll, rfIgnoreCase]);

        deltaB := deltaA;
        StringReplaceEx(deltaB, Sub, '', [rfReplaceAll, rfIgnoreCase]);

        Result := (Length(deltaA) - Length(deltaB)) div Length(Sub);
    end else
    begin
        Result := 0;
    end;
end;
end.

