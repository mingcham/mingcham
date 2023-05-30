unit NetThread;

interface

uses
    Classes, Forms, Windows, SysUtils, OverbyteIcsWndControl, OverbyteIcsPing,
    JwaIpHlpApi, JwaIpTypes, JclDebug;

type
    CNetInfoThread = class(TJclDebugThread)
    private
        FDefaultGateWay: TStringList;
        FDefaultDNS: TStringList;
        FExceptionLog: TStringList;
        FPingInterval: integer;
        FTrigInterval: integer;
        FPingTryTimes: integer;
        FNetWorkValid: integer;
    protected
        procedure Execute; override;
        procedure SyncMainFrame();
        function CheckNetWorkValid(const AList: TStringList): Boolean;
    public
        constructor Create(CreateSuspended: Boolean);
        destructor Destroy; override;
        procedure ThreadReportBug;
    end;

implementation

uses main;

procedure GetDNSServers(AList: TStringList);
var
    pFI             : PFIXED_INFO;
    pIPAddr         : PIPAddrString;
    OutLen          : ULONG;
begin
    OutLen := SizeOf(TFixedInfo);
    GetMem(pFI, SizeOf(TFixedInfo));
    try
        if GetNetworkParams(pFI, OutLen) = ERROR_BUFFER_OVERFLOW then
        begin
            ReallocMem(pFI, OutLen);
            if GetNetworkParams(pFI, OutLen) <> NO_ERROR then Exit;
        end;
        // If there is no network available there may be no DNS servers defined
        if pFI^.DnsServerList.IpAddress.S[0] = #0 then Exit;
        // Add first server
        AList.Add(pFI^.DnsServerList.IpAddress.S);
        // Add rest of servers
        pIPAddr := pFI^.DnsServerList.Next;

        while Assigned(pIPAddr) do
        begin
            AList.Add(pIPAddr^.IpAddress.S);
            pIPAddr := pIPAddr^.Next;
        end;
    finally
        FreeMem(pFI);
    end;
end;

procedure GetGateways(AList: TStringList);
var
    NumInterfaces   : Cardinal;
    AdapterInfo     : array of TIpAdapterInfo;
    OutBufLen       : ULONG;
    i               : integer;
    pIPAddr         : PIPAddrString;
begin
    GetNumberOfInterfaces(NumInterfaces);
    SetLength(AdapterInfo, NumInterfaces);
    OutBufLen := NumInterfaces * SizeOf(TIpAdapterInfo);
    GetAdaptersInfo(@AdapterInfo[0], OutBufLen);

    for i := 0 to NumInterfaces - 1 do
    begin
        if AdapterInfo[i].GatewayList.IpAddress.S[0] <> #0 then
        begin
            AList.Add(AdapterInfo[i].GatewayList.IpAddress.S);
            pIPAddr := AdapterInfo[i].GatewayList.Next;

            while Assigned(pIPAddr) do
            begin
                AList.Add(pIPAddr^.IpAddress.S);
                pIPAddr := pIPAddr^.Next;
            end;
        end
    end;
end;

function CNetInfoThread.CheckNetWorkValid(const AList: TStringList): Boolean;
var
    ping            : TPing;
    i               : Cardinal;
begin
    Result := False;
    if (AList.Count <= 0) then
    begin
        Result := True;
        Exit;
    end;

    for i := 0 to AList.Count - 1 do
    begin
        if (AList[i] <> '') then
        begin
            ping := TPing.Create(nil);
            try
                ping.Address := AList[i];
                ping.Flags := 0;
                ping.Size := $20;
                ping.Tag := 0;
                ping.Timeout := FPingInterval;
                ping.TTL := $40;

                Result := (ping.Ping() <> 0);
            finally
                ping.Free;
            end;
        end;

        // more than one ip is on
        if (Result) then
            Exit;
    end;
end;

constructor CNetInfoThread.Create(CreateSuspended: Boolean);
begin
    inherited Create(CreateSuspended);

    FDefaultGateWay := TStringList.Create;
    FDefaultDNS := TStringList.Create;
    FExceptionLog := TStringList.Create;
end;

destructor CNetInfoThread.Destroy;
begin
    FreeAndNil(FDefaultGateWay);
    FreeAndNil(FDefaultDNS);
    FreeAndNil(FExceptionLog);

    inherited Destroy;
end;

procedure CNetInfoThread.Execute;
var
    b1, b2          : Boolean;
begin
    try
        FNetWorkValid := 0;
        Synchronize(SyncMainFrame);

        // network init
        FDefaultGateWay.Clear;
        FDefaultDNS.Clear;
        FExceptionLog.Clear;
        GetGateways(FDefaultGateWay);
        GetDNSServers(FDefaultDNS);

        while (not Terminated) and (not Application.Terminated) do
        begin
            b1 := CheckNetWorkValid(FDefaultGateWay);

            if (b1) then
                b2 := CheckNetWorkValid(FDefaultDNS)
            else
                b2 := False;

            if (b1 and b2) then
            begin
                if (FNetWorkValid <= FPingTryTimes) then
                    inc(FNetWorkValid)
            end else
                FNetWorkValid := 0;

            Synchronize(SyncMainFrame);

            Sleep(FTrigInterval);
        end;
    except
        on E: Exception do
        begin
            DebugPrintf('严重错误(ENO0005):' + E.Message);

            FExceptionLog.Clear;
            FExceptionLog.Add('错误消息：' + E.Message);
            JclLastExceptStackListToStrings(FExceptionLog, False, True, True,
                True);
            if FExceptionLog.Count > 1 then
            begin
                FExceptionLog[1] := '调用堆栈：' + FExceptionLog[1];
            end;
            Synchronize(ThreadReportBug);
        end;
    end;
end;

procedure CNetInfoThread.SyncMainFrame;
begin
    if (TriggerSlow > TriggerInterval) and (TriggerInterval > 0) then
    begin
        FPingInterval := TriggerSlow - (TriggerSlow mod TriggerInterval);
        FTrigInterval := TriggerInterval;
        FPingTryTimes := (FPingInterval div FTrigInterval);
        IsNetWorkValid := (FNetWorkValid >= FPingTryTimes);

        if (FNetWorkValid <= FPingTryTimes) then
            somain.mStatus.Panels[1].Text := Format('正在等待网络恢复(%d%%)...',
                [FNetWorkValid * 100 div FPingTryTimes]);
    end else
    begin
        FPingInterval := 0;
        FTrigInterval := 0;
        FPingTryTimes := 0;
        IsNetWorkValid := False;
    end;
end;

procedure CNetInfoThread.ThreadReportBug;
begin
    somain.UindexWebThreadException(FExceptionLog.Text);
end;

end.
