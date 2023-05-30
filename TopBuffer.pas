unit TopBuffer;

interface

uses
    SysUtils, Classes, CoreString;

type
    CTopCliper = class(TComponent)
    private
        Fheap, FMaxHeap: integer;       //注意heap是动态变化的
        Clips: TStringList;
        Rates: array of integer;
        FDefaultMax: integer;
        Fexceedheap: integer;
        procedure setmaxheap(const value: integer);
    protected
        procedure SortClip();
        procedure AdjustClip();
        procedure reset();
    public
        constructor Create(Owner: TComponent); override;
        destructor Destroy; override;
        function process(const clip: PAnsiString): integer;
    published
        property Heap: integer read Fheap write Fheap;
        property MaxHeap: integer read FMaxHeap write setmaxheap;
        property ExceedHeap: integer read Fexceedheap write Fexceedheap;
        property DefaultMax: integer read FDefaultMax;
    end;

procedure Register;

implementation

procedure Register;
begin
    RegisterComponents('Uindex', [CTopCliper]);
end;

{ CTopCliper }

constructor CTopCliper.Create(Owner: TComponent);
begin
    inherited Create(Owner);
    Clips := TStringList.Create;
    Fheap := 0;
    FMaxHeap := 512;
    FDefaultMax := FMaxHeap;
    Fexceedheap := FMaxHeap * 4;
    SetLength(Rates, Fexceedheap + 1);
end;

destructor CTopCliper.Destroy;
begin
    Clips.Free;
    SetLength(Rates, 0);
    Rates := nil;
    inherited Destroy;
end;

function CTopCliper.process(const clip: PAnsiString): integer;
var index           : integer;
    shashclip       : string;
begin
    shashclip := HashClip32(clip);

    if shashclip = '' then
    begin
        result := 1;
        Exit;
    end;

    index := Clips.IndexOf(shashclip);

    if (index < 0) then
    begin
        //将这个新的哈希值放于最后得分为1
        Clips.Add(shashclip);
        Rates[Fheap] := 1;              //注意：索引Fheap比编号小1
        Fheap := Clips.Count;
        AdjustClip;
        result := -1;
    end else begin
        //-------------------------------------------------------------------
        // 信息片排名在1/4以前的才跳过
        //-------------------------------------------------------------------
        if index > (Fheap shr 2) then
            result := -1
        else
            result := Rates[index];
        Rates[index] := Rates[index] + 1;
        SortClip;
    end;
end;

procedure CTopCliper.SortClip;
var i, tmprate      : integer;
    needadjust      : boolean;
    tmphash         : string;
begin
    //首次调整
    needadjust := True;

    while needadjust do
    begin
        //默认不需要调整
        needadjust := false;

        for i := 1 to Fheap - 1 do
        begin
            if Rates[i] > Rates[i - 1] then
            begin
                //首先交换哈希记录
                tmphash := Clips[i - 1];
                Clips[i - 1] := Clips[i];
                Clips[i] := tmphash;
                //然后交换概率值
                tmprate := Rates[i - 1];
                Rates[i - 1] := Rates[i];
                Rates[i] := tmprate;
                //标志为需要继续排序
                needadjust := true;
            end;
        end;
    end;
end;

procedure CTopCliper.AdjustClip;
var i               : integer;
begin
    //-------------------------------------------------------------------------
    // 比如Fheap为512，则当当前的哈希记录列表超过1536时,删除从512-640=128的部分
    // 这样做目的是为了保留新添加进来的较大的观察时间
    // 也就是说Fheap会在512-1024间变化,或者一直不到512
    //-------------------------------------------------------------------------
    if Fheap > Fexceedheap then
    begin
        for i := (FMaxHeap + (FMaxHeap shr 3)) downto FMaxHeap do
        begin
            Clips.Delete(i);
            Rates[i] := 0;
        end;
        Fheap := Clips.Count;
        SortClip;
    end;
end;

procedure CTopCliper.setmaxheap(const value: integer);
begin
    if FMaxHeap > 20 then
    begin
        FMaxHeap := value;
        Fexceedheap := FMaxHeap * 4;
        SetLength(Rates, Fexceedheap + 1);
        reset;
    end;
end;

procedure CTopCliper.reset;
begin
    //如果已经存在,重置
    if Clips.Count > 0 then
        Clips.Clear;
    Fheap := 0;
end;

end.
