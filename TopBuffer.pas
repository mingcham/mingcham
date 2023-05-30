unit TopBuffer;

interface

uses
    SysUtils, Classes, CoreString;

type
    CTopCliper = class(TComponent)
    private
        Fheap, FMaxHeap: integer;       //ע��heap�Ƕ�̬�仯��
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
        //������µĹ�ϣֵ�������÷�Ϊ1
        Clips.Add(shashclip);
        Rates[Fheap] := 1;              //ע�⣺����Fheap�ȱ��С1
        Fheap := Clips.Count;
        AdjustClip;
        result := -1;
    end else begin
        //-------------------------------------------------------------------
        // ��ϢƬ������1/4��ǰ�Ĳ�����
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
    //�״ε���
    needadjust := True;

    while needadjust do
    begin
        //Ĭ�ϲ���Ҫ����
        needadjust := false;

        for i := 1 to Fheap - 1 do
        begin
            if Rates[i] > Rates[i - 1] then
            begin
                //���Ƚ�����ϣ��¼
                tmphash := Clips[i - 1];
                Clips[i - 1] := Clips[i];
                Clips[i] := tmphash;
                //Ȼ�󽻻�����ֵ
                tmprate := Rates[i - 1];
                Rates[i - 1] := Rates[i];
                Rates[i] := tmprate;
                //��־Ϊ��Ҫ��������
                needadjust := true;
            end;
        end;
    end;
end;

procedure CTopCliper.AdjustClip;
var i               : integer;
begin
    //-------------------------------------------------------------------------
    // ����FheapΪ512���򵱵�ǰ�Ĺ�ϣ��¼�б���1536ʱ,ɾ����512-640=128�Ĳ���
    // ������Ŀ����Ϊ�˱�������ӽ����Ľϴ�Ĺ۲�ʱ��
    // Ҳ����˵Fheap����512-1024��仯,����һֱ����512
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
    //����Ѿ�����,����
    if Clips.Count > 0 then
        Clips.Clear;
    Fheap := 0;
end;

end.
