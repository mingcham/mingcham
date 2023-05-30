unit HtmlSplit;

interface

uses
    SysUtils, Classes, StrUtils, CoreString;

type
    TonComplete = procedure(const ClipCount: integer) of object;
    TFindClip = procedure(const ClipStr: string) of object;
    TOnProgress = procedure(const min, max, pos: integer) of object;
    CInformationClip = class(TComponent)
    private
        Fhtml: PAnsiString;
        FonComplete: TonComplete;
        FOnProgress: TOnProgress;
        FonFindClip: TFindClip;
        FClipCount: integer;
        FDiGuiPoint: integer;
        FNowStep: integer;
        function degest(const HtmlClip: PAnsiString): string;
    public
        SpilterList: ^TStringList;      //可以接受的域名后缀
        constructor create(Aowner: Tcomponent); override;
        destructor Destroy; override;
        procedure Prepare;
        function DiGuiClip(): integer;
        procedure InsertSpliter;
        procedure SentComplete;
        procedure LoadHtml(const html: PAnsiString);
    published
        property OnFindClip: TFindClip read FonFindClip write FonFindClip;
        property OnComplete: TonComplete read FonComplete write FonComplete;
        property OnProgress: TOnProgress read FOnProgress write FOnProgress;
    end;

procedure Register;

implementation

procedure Register;
begin
    RegisterComponents('Uindex', [CInformationClip]);
end;

{ CInformationClip }

constructor CInformationClip.create(Aowner: Tcomponent);
begin
    inherited create(Aowner);
    FDiGuiPoint := 0;
    FClipCount := 0;
    FNowStep := 0;
end;

function CInformationClip.degest(const HtmlClip: PAnsiString): string;
var
    i               : integer;
    j               : integer;
    len             : integer;
    stm             : integer;
begin
    j := 1;
    len := Length(HtmlClip^);
    stm := 0;
    setlength(Result, len);

    for i := 1 to len do
    begin
        if (HtmlClip^[i] = '<') then
        begin
            stm := 1;
        end else
            if (HtmlClip^[i] = '>') then
            begin
                stm := 0;
            end else
                if (stm = 0) then
                begin
                    Result[j] := HtmlClip^[i];
                    Inc(j);
                end;
    end;
    setlength(Result, j - 1);

    //替换无意义字符
    StringReplaceEx(Result, '?', #32, [rfReplaceAll]);
    StringReplaceEx(Result, #32 + #32, #32, [rfReplaceAll]);
    StringReplaceEx(Result, #13 + #13, #13, [rfReplaceAll]);

    Result := Trim(Result);
end;

destructor CInformationClip.Destroy;
begin
    SpilterList := nil;
    inherited Destroy;
end;

function CInformationClip.DiGuiClip(): integer;
var NewClip         : string;
    NowPos, i       : integer;
begin
    //第三步，递归分行内容
    if assigned(OnProgress) then
        OnProgress(0, 20, 3);
    if Fhtml^ <> '' then
    begin
        NowPos := 0;
        FDiGuiPoint := sposex(#13, Fhtml^, NowPos);
        //----------------------------------------------------------------------
        // 如果前一次获得了有效信息片,那么本次继续测试是否有效
        // 这里没有使用TStringList来进行分行,原因是不会精确地测试比较两者的速度.
        //----------------------------------------------------------------------
        while FDiGuiPoint > NowPos do
        begin
            NewClip := copy(Fhtml^, NowPos + 1, (FDiGuiPoint - NowPos) - 1);
            NewClip := trim(degest(@NewClip));
            if (NewClip <> '') then
            begin
                if assigned(OnFindClip) then OnFindClip(NewClip);
                Inc(FClipCount);
            end;
            NowPos := FDiGuiPoint;
            FDiGuiPoint := sposex(#13, Fhtml^, NowPos + 1);
            if Length(Fhtml^) > 16 then
            begin
                i := NowPos div (Length(Fhtml^) div 16);
                if assigned(onProgress) and (FNowStep <> i) then
                begin
                    OnProgress(0, 20, 4 + i);
                    FNowStep := i;
                end;
            end;
        end;
    end;
    result := FClipCount;
end;

procedure CInformationClip.InsertSpliter;
var i               : integer;
begin
    //-----------------------------------------------------------------------
    //第二步，插入分行符
    //在拆分关键字后面加上拆分符号,换行
    //-----------------------------------------------------------------------
    if assigned(OnProgress) then
        OnProgress(0, 20, 1);

    for i := 0 to (SpilterList^).Count - 1 do
    begin
        if (Fhtml^ = '') then
        begin
            Break;
        end;
        StringReplaceEx(Fhtml^, (SpilterList^)[i], #13, [rfReplaceAll]);
    end;
    StringReplaceEx(Fhtml^, #13 + #13, #13, [rfReplaceAll]);

    if assigned(OnProgress) then
        OnProgress(0, 20, 2);
end;

procedure CInformationClip.LoadHtml(const html: PAnsiString);
begin
    Fhtml := html;
end;

procedure CInformationClip.Prepare;
begin
    FDiGuiPoint := 0;
    FClipCount := 0;
    //-------------------------------------------------------------------------
    //在准备的过程中替换注释和风格,脚本
    //-------------------------------------------------------------------------
    //第一步，清理不关心的字符
    if Fhtml^ <> '' then
    begin
        StringReplaceEx(Fhtml^, #13, '', [rfReplaceAll]);
        StringReplaceEx(Fhtml^, #10, '', [rfReplaceAll]);
        Fhtml^ := trim(Fhtml^);
    end;
end;

procedure CInformationClip.SentComplete;
begin
    //报告拆分完成
    if assigned(OnProgress) then
        OnProgress(0, 20, 20);
    if assigned(OnComplete) then
        OnComplete(FClipCount);
end;

end.
