unit SearchTest;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, ExtCtrls, StdCtrls, ComCtrls, Buttons, DateUtils,
    OverbyteIcsHttpSrv,
    DB, ADODB, StrUtils, CoreString, OverbyteIcsWndControl, Spin;

type
    TMyHttpConnection = class(THttpConnection)
    protected
        FPostedDataBuffer: PChar; { Will hold dynamically allocated buffer }
        FPostedDataSize: Integer; { Databuffer size                        }
        FDataLen: Integer; { Keep track of received byte count.     }
        FDataFile: TextFile; { Used for datafile display              }
    public
        destructor Destroy; override;
    end;
    TSearchTST = class(TForm)
        GroupBox1: TGroupBox;
        HttpServer1: THttpServer;
        mStatus: TStatusBar;
        ServerPort: TSpinEdit;
        ResultNum: TSpinEdit;
        ServerPort_Ticket: TLabel;
        ResultNum_Ticket: TLabel;
        StartSearch: TBitBtn;
        procedure StartSearchClick(Sender: TObject);
        procedure ServerPortKeyPress(Sender: TObject; var Key: Char);
        procedure HttpServer1GetDocument(Sender, Client: TObject;
            var Flags: THttpGetFlag);
        procedure ServerPortChange(Sender: TObject);
        procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    private
        procedure ResetHttpServer();
    public
        { Public declarations }
    end;

var
    SearchTST       : TSearchTST;

implementation

uses main;

{$R *.dfm}

function URLdecode(str: string): string;
var
    temp            : string;
    i, j            : integer;
begin
    setlength(temp, length(str));
    i := 1;
    j := 1;
    while (i <= length(str)) do
    begin
        if (str[i] = '%') and ((length(str) - i) >= 2) then
        begin
            temp[j] := char(strtoint('$' + str[i + 1] + str[i + 2]));
            inc(i, 3);
            inc(j);
        end else if (str[i] = '+') then
        begin
            temp[j] := #32;
            inc(i);
            inc(j);
        end else begin
            temp[j] := str[i];
            inc(i);
            inc(j);
        end;
    end;
    //正常情况下应为:Copy(temp,1,j-1);这里为避免剔除'/'
    if temp[1] = '/' then
        Result := Copy(temp, 2, j - 2)
    else
        Result := Copy(temp, 1, j - 1);
end;

procedure TSearchTST.StartSearchClick(Sender: TObject);
begin
    if StartSearch.Tag = 0 then
    begin
        StartSearch.Caption := '正在启动..';
        StartSearch.Tag := 1;
        HttpServer1.Port := ServerPort.Text;
        try
            HttpServer1.Start;
            somain.StatusPrintf('开始:' + somain.IndexWeb.Caption);
        except
            on e: exception do
            begin
                somain.StatusPrintf('测试搜索(ENO0004):' + e.Message);
                if (e.Message = 'Address already in use (#10048 in Bind)') then
                    ServerPort.Font.Color := clred;
                StartSearch.Caption := '重新启动';
                StartSearch.Tag := 0;
                exit;
            end;
        end;
        somain.ShellOpen('http://localhost:' + ServerPort.Text + '/?q=' +
            IntToStr(YearOf(Date)));
        StartSearch.Caption := '停止测试';
        mStatus.Panels[1].Text := '正在运行..';
    end else begin
        ResetHttpServer;
    end;
end;

procedure TSearchTST.ServerPortKeyPress(Sender: TObject; var Key: Char);
begin
    if not (Key in ['0'..'9', #8]) then
    begin
        Key := #0;
        beep();
    end;
end;

procedure TSearchTST.HttpServer1GetDocument(Sender, Client: TObject;
    var Flags: THttpGetFlag);
var ClientCnx       : TMyHttpConnection;
    key, content    : string;
    cnt, dft        : integer;
begin
    if Flags = hg401 then
        Exit;
    ClientCnx := TMyHttpConnection(Client);
    if ClientCnx.Params <> '' then
    begin
        key := URLdecode(ClientCnx.Params);
        StringReplaceEx(key, 'q=', '', [rfReplaceAll, rfIgnoreCase]);
    end else begin
        key := URLdecode(ClientCnx.Path);
        if AutoConvert2Ansi(@key) <> '' then
            key := AutoConvert2Ansi(@key);
    end;
    dft := StringToIntDef(ResultNum.Text, 10);
    mStatus.Panels[1].Text := '搜索关键字: ' + key;
    content := content + '<html>' + #13;
    content := content + '<head>' + #13
        + '<meta http-equiv="Content-Type" content="text/html; charset=GB2312" />' +
        #13
        + '<meta http-equiv="Content-Language" content="zh-CN" />' + #13
        + '<title>' + key + ' Powered By ' + ShortCopyRight + '</title>' + #13
        + '</head>' + #13
        + '<body>' + #13
        + ' <form name=search action="/" method="get">' + key + ' 的搜索结果(前'
        + IntToStr(dft) + ')'
        + '<input name=q size="35" value="' + key + '" maxlength=30>'
        + '<input type=submit value=' + ShortCopyRight + '搜索>'
        + '</form><hr>' + #13;
    //--------------------------------------------------------------------------
    //搜索标题
    //--------------------------------------------------------------------------
    SemaphoreAcquire(DBtoken);
    try
        cnt := 0;

        with adolink do
        begin
            Close;
            SQL.Clear;
            SQL.Text := 'Select Top ' + IntToStr(dft) +
                ' WPId,WPRealTitle,WPContent,WPUrl From UindexWeb_WebPage Where WPRealTitle Like ' + #39
                + #37 + key + #37 + #39;
            Open;
            if (not Eof) then
                while (not Eof) and (cnt < dft) and (not Application.Terminated)
                    do
                begin
                    content := content + ' <a href="' + Recordset.Fields[3].Value
                        + '" target=_blank><b><font color=blue>' +
                        AnsiLeftStr(Recordset.Fields[1].Value, 30) +
                        '</font></b></a><br>' +
                        AnsiLeftStr(Recordset.Fields[2].Value, 100) + '...<br>'
                        +
                        #13;
                    inc(cnt);
                    adolink.Next;
                end
            else
                content := content + '<br>没有搜索到.<br><br>' + #13;
            content := content + ' <hr><br>' + #13;
            content := content + ' <div align=center>Copyrigh (C) 2005-' +
                IntToStr(YearOf(Date)) + ' ' + CopyRightStr + '</div>' + #13;
            content := content + '</body>' + #13;
            content := content + '</html>' + #13;
            ClientCnx.AnswerString(Flags, '', '', '', content);
            SQL.Clear;
            Close;
        end;
    except
        on e: exception do
            ClientCnx.AnswerString(Flags, '', '', '', e.Message);
    end;
    SemaphoreRelease(DBtoken);
end;

destructor TMyHttpConnection.Destroy;
begin
    if Assigned(FPostedDataBuffer) then begin
        FreeMem(FPostedDataBuffer, FPostedDataSize);
        FPostedDataBuffer := nil;
        FPostedDataSize := 0;
    end;
    inherited Destroy;
end;

procedure TSearchTST.ServerPortChange(Sender: TObject);
begin
    ServerPort.Font.Color := clWindowText;
end;

procedure TSearchTST.FormCloseQuery(Sender: TObject;
    var CanClose: Boolean);
begin
    ResetHttpServer;
end;

procedure TSearchTST.ResetHttpServer;
begin
    if StartSearch.Tag > 0 then
    begin
        HttpServer1.Stop;
        StartSearch.Tag := 0;
        somain.StatusPrintf('停止:' + somain.IndexWeb.Caption);
    end;
    StartSearch.Caption := '开始测试';
    mStatus.Panels[1].Text := '准备就绪.';
end;

end.
