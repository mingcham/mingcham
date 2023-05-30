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
//���һ��URL��ַ����
var p1              : integer;
begin
    //http://user:pass@www.163.com:8080/music/chs/index.aspx?mid=23081712
    //    p1     p2   p3          p4   p5
    result := '';
    if LeastUrlRequest(url) then
    begin
        //ȥ��Э��
        p1 := pos('://', url);
        if (p1 > 0) then
            Delete(url, 1, p1 + 2);
        p1 := pos('/', url);
        if (p1 > 1) then
        begin
            //�õ�������ַ
            url := Copy(url, 1, p1 - 1);
            if url <> '' then
            begin
                //ȥ���û���������
                p1 := pos('@', url);
                if (p1 > 0) then
                    Delete(url, 1, p1);
                //ȥ���˿�
                Delete(url, pos(':', url), Length(url));
            end;
            if IsLocalHost(url) then
                result := ''
            else
                result := url;
        end else if (length(url) >= 3) and (url[1] <> '/') then
            //������a.b,���ȴ��ڵ���3�������������ļ�������ʽ
        begin
            if IsLocalHost(url) then
                result := ''
            else
                result := url;
        end;
    end;
end;

function GetDomainExt(const url: string): string;
//��ø������չ��
begin
    //ע��:�ڵ���ǰ�����ȵ���GetDomainRoot
    result := '';
    if (RightPos('.', url) > 0) then
        result := Copy(url, RightPos('.', url) + 1, Length(url));
end;

//�ж�URL�Ƿ�ΪHTTPЭ��

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
//�����ִ�Сд��pos
begin
    result := Pos(AnsiLowerCase(sub), AnsiLowerCase(source));
end;

function NCposex(const sub, source: string; index: integer): integer;
//�����ִ�Сд��posex
begin
    if (source = '') or (sub = '') then
        result := -1
    else
        result := posex(AnsiLowerCase(sub), AnsiLowerCase(source), index);
end;

function sposex(const sub, source: string; index: integer): integer;
//��ȫ��posex
begin
    if (source = '') or (sub = '') then
        result := -1
    else
        result := posex(sub, source, index);
end;

function SqlFitness(sql: string): string;
//�滻SQL����޷������������ַ�
begin
    if sql <> '' then
    begin
        StringReplaceEx(sql, #34, #32, [rfReplaceAll]);
        StringReplaceEx(sql, #39, #32, [rfReplaceAll]);
    end;
    result := SetDefaultSqlStr(sql);
end;

function GetDocNameFromUrl(url: string): string;
//����http://www.163.com/so?��163.com/so/index.htm?qq=254939297
//�ֱ𷵻�so,index.htm
var p1, p2, p3      : integer;
begin
    result := '';
    if LeastUrlRequest(url) then
    begin
        p3 := Pos('?', url);            //����λ��
        p2 := Pos('://', url);          //HTTP://λ��
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
        p1 := RightPos('/', url);       //б��λ��
        if (p1 > 0) and (p1 < Length(url)) then
            result := Copy(url, p1 + 1, Length(url));
    end;
end;

function GetDocumentName(const doc: string): string;
//����www.163.com/so?��163.com/so/index.htm
//�ڵ���ǰ�����ȵ�����һ����
begin
    result := Copy(doc, 1, RightPos('.', doc) - 1);
end;

function LastChar(const str: string): string;
//���ز����ַ���������һ���ַ�
begin
    result := '';
    if (str <> '') then
    begin
        result := str[length(str)];
    end;
end;

function IsNumeric(const InStr: string): boolean;
//�ж��Ƿ�Ϊ������
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
//�滻��128���ַ��ܺ�ʱ���������Ժ�������ҳ��ʱ�䲻������
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
//��ʽ��HTML
begin
    //�������滻Ϊ��ϢƬ�㷨��׼��,��ֹ�����Ƭ
    StringReplaceEx(HtmlCode, #9, '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, '��', '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, #10, '', [rfReplaceAll]);
    StringReplaceEx(HtmlCode, #13, '', [rfReplaceAll]);
    //--------------------------------------------------------------------------
    //   ����HTML����涨�ַ�
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
//���ұ߿�ʼ�Ĳ���
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
//���ı����ݵ���Ч�Ի�÷�ֵ�������϶��ܵø߷�,����:100
var i, j            : integer;
begin
    j := 0;

    StringReplaceEx(content, '��', '', [rfReplaceAll]);
    StringReplaceEx(content, '��', '', [rfReplaceAll]);
    StringReplaceEx(content, '��', '', [rfReplaceAll]);

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
//��Դ��λ�������Ҫ��,����������쳣�ַ��б��У�������False
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
//�ж�һ�������Ƿ�����,����������,IP,���Դ��˿�,�������������������ȡ������
var i               : integer;
begin
    Result := true;
    if (dm <> '') then
    begin
        for i := 1 to Length(dm) do
        begin
            //ע��,a can't to Z,ASCII separated.(���Խ��)
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
//��Щ�ֶα����Ϊ�����,Ȼ��ʵ���ϲ�ͬ�İ汾OLEDBȴ��һ��֧��
begin
    if trim(str) = '' then
        result := #32
    else
        result := Trim(str);
end;

function IsValidVarString(OleString: Variant): Boolean;
//����varant�Ƿ�Ϊ��Ч�ַ���
begin
    result := (VarIsStr(OleString)) and (trim(OleString) <> '');
end;

function GetDBFileFromConnStr(ConStr: string): string;
//�ַ�������,����adodb�����ִ�,������ݿ��ַ.
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
//����32�ֽ��ִ�����ԭʼ�ַ�������
var len, i          : integer;
    LenDiv          : Single;
    TmpStr          : string;
begin
    //-------------------------------------------------------------------------
    //ע��,������ֽ���ֱ�ӹ�ϵ���Ժ���ڴ�ռ��,����512*32*3�����ռ��48KB
    //-------------------------------------------------------------------------
    len := length(input^);
    if (len > 32) then
    begin
        setlength(TmpStr, 32);          //����ռ�
        LenDiv := len / 32;             //������һ������1

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
//ͬC���Ե�ATOI(),���ַ���תΪ����
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

