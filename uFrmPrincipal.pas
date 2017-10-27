unit uFrmPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, System.Rtti, System.Bindings.Outputs,
  Fmx.Bind.Editors, Data.Bind.EngExt, Fmx.Bind.DBEngExt, Data.Bind.Components,
  Data.Bind.DBScope, FMX.ListView, math;

type
  TfrmPrincipal = class(TForm)
    mtblPopulacao: TFDMemTable;
    mtblPopulacaoX: TFloatField;
    mtblPopulacaoY: TFloatField;
    mtblPopulacaoBINARIO: TStringField;
    mtblPopulacaoAPTIDAO: TFloatField;
    mtblPopulacaoTOTAL_APTIDAO: TAggregateField;
    Button1: TButton;
    ListView: TListView;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkListControlToField1: TLinkListControlToField;
    mtblExib: TFDMemTable;
    mtblExibBINARIO: TStringField;
    mtblExibAPTIDAO: TFloatField;
    BindSourceDB2: TBindSourceDB;
    ToolBar1: TToolBar;
    Label1: TLabel;
    StyleBook1: TStyleBook;
    procedure Button1Click(Sender: TObject);
    procedure mtblPopulacaoBeforePost(DataSet: TDataSet);
  private
    const
      TAMANHO_BINARIO = 22;
      NUM_GERACOES = 15;
      PONTO_CORTE = 30;
      FATOR_MUTACAO = 2;
      FATOR_CRUZAMENTO = 40;
      TAMANHO_POPULACAO = 120;
    procedure CriaExibicao;
    procedure SelecionaNovaPopulacao;
    procedure CruzaEMuta;
    procedure AdicionarMaisAptoExibicao;
    function F6(pX, pY: double): Double;
    function DecToBinStr(N: Integer): string;
    procedure CompletaPalavraBin(var pPalavra: string);
    function Cruzar(pRecnoA, pRecnoB: integer): TStringList;
    function Mutar(pBinario: string): string;
    procedure IniciarPopulacao;
    function ObterRecNoRoleta: integer;
    function Pow(i, k: Integer): Integer;
    function BinToDec(Str: string): Integer;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

{ TForm2 }

function TfrmPrincipal.F6(pX, pY: double): Double;
var
   lResultado, lNumerador, lDenominador : Double;
   lSomaQuadrados: Double;
begin
   lResultado   := 0;
   lNumerador   := 0;
   lDenominador := 0;
   lSomaQuadrados := (pX * pX) + (pY * pY);
   lNumerador := sin(lSomaQuadrados);
   lNumerador := (lNumerador * lNumerador) - 0.5;
   lDenominador := 1 + (0.001 * lSomaQuadrados);
   lDenominador := lDenominador * lDenominador;
   lResultado := 0.5 - (lNumerador / lDenominador);
   result := lResultado;
end;

procedure TfrmPrincipal.IniciarPopulacao;
var
   i: integer;
begin
   {Zerar população}
   mtblPopulacao.Close;
   mtblPopulacao.Open;
   mtblPopulacao.EmptyDataSet;
   i := 1;
   {Criar de maneira randomica}
   while i < TAMANHO_POPULACAO do
   begin
      mtblPopulacao.Append;
      mtblPopulacaoX.AsFloat := abs(Random(100));
      mtblPopulacaoY.AsFloat := abs(Random(100));
      mtblPopulacao.Post;
      Inc(i);
   end;
end;

procedure TfrmPrincipal.mtblPopulacaoBeforePost(DataSet: TDataSet);
var
   lBinx, lBinY: string;
begin
   {antes de gravar novo individuo}
   {F6 como aptidão}
   mtblPopulacaoAPTIDAO.AsFloat := F6(mtblPopulacaoX.AsFloat, mtblPopulacaoY.AsFloat);
   {compor novos binarios de 44 bits}
   lBinx := DecToBinStr(Abs(Round(mtblPopulacaoX.AsFloat)));
   CompletaPalavraBin(lBinx);
   lBinY := DecToBinStr(Abs(Round(mtblPopulacaoY.AsFloat)));
   CompletaPalavraBin(lBinY);
   mtblPopulacaoBINARIO.AsString := lBinx + lBinY;
end;

function TfrmPrincipal.Mutar(pBinario: string): string;
var
   lResultado: string;
   lPodeMutar: Boolean;
   lRandomico: Integer;
   lchar: Char;
begin
   lPodeMutar := False;
   {para cada gene}
   for lchar in pBinario do
   begin
      {Gera chance de mutar baseado no fator de mutação}
      lRandomico := Random(FATOR_MUTACAO);
      lPodeMutar := lRandomico = 2;
      if lPodeMutar then
      begin
         {"Bit Swap"}
         if lchar = '0' then
         begin
            lResultado.Insert(1, '1');
         end
         else
         begin
            lResultado.Insert(1, '0');
         end;
      end
      else
      begin
         lResultado.Insert(1, lchar);
      end;
   end;
   Result := lResultado;
end;

function TfrmPrincipal.ObterRecNoRoleta: integer;
var
   lChance: Double;
   lRandom: Integer;
   lSortudo: boolean;
begin
   {Obter índice elitista baseado no método de roleta}
   lSortudo := False;
   mtblPopulacao.First;
   while not mtblPopulacao.Eof do
   begin
      lChance := RoundTo(mtblPopulacaoAPTIDAO.AsFloat / mtblPopulacaoTOTAL_APTIDAO.Value, -2) * 100;
      lRandom := Abs(Random(100));
      lSortudo := lRandom <= lChance;
      if lSortudo then
      begin
         Result := mtblPopulacao.RecNo;
         Break
      end;
      mtblPopulacao.Next;
   end;
   if not lSortudo then
   begin
      Result := Abs(Random(mtblPopulacao.RecordCount));
   end;
end;

procedure TfrmPrincipal.CriaExibicao;
begin
  mtblExib.Close;
  mtblExib.CreateDataSet;
  mtblExib.EmptyDataSet;
end;

procedure TfrmPrincipal.SelecionaNovaPopulacao;
begin
  {população ja ordenada de forma crescente de aptidão}
  mtblPopulacao.First;
  while mtblPopulacao.RecordCount > TAMANHO_POPULACAO do
  begin
    Application.ProcessMessages;
    mtblPopulacao.Delete;
  end;
end;

procedure TfrmPrincipal.CruzaEMuta;
var
  lLimiteCruzar: Integer;
  lListaCromoFilhos: TStringList;
  i: integer;
begin
   for lLimiteCruzar := 0 to FATOR_CRUZAMENTO do
   begin
      {Lista com cromossomos filhos gerados}
      lListaCromoFilhos := Cruzar(ObterRecNoRoleta, ObterRecNoRoleta);
      try
         for i := 0 to lListaCromoFilhos.Count -1 do
         begin
            {Efetuar mutação no filho}
            lListaCromoFilhos[i] := Mutar(lListaCromoFilhos[i]);
            {Acrescentar filho à populaçao}
            mtblPopulacao.Append;
            mtblPopulacaoX.AsFloat := BinToDec(Copy(lListaCromoFilhos[i], 1, 22));
            mtblPopulacaoY.AsFloat := BinToDec(Copy(lListaCromoFilhos[i], 23, length(lListaCromoFilhos[0])));
            mtblPopulacao.Post;
         end;
         Application.ProcessMessages;
      finally
         lListaCromoFilhos.DisposeOf;
      end;
   end;
end;

procedure TfrmPrincipal.AdicionarMaisAptoExibicao;
begin
  mtblPopulacao.Last;
  mtblExib.Append;
  mtblExibBINARIO.AsString := mtblPopulacaoBINARIO.AsString;
  mtblExibAPTIDAO.AsFloat := mtblPopulacaoAPTIDAO.AsFloat;
  mtblExib.Post;
end;

function TfrmPrincipal.DecToBinStr(N: Integer): string;
var
  S: string;
  i: Integer;
  Negative: Boolean;
begin
   if N<0 then
   begin
      Negative:=True;
   end;
   N:=Abs(N);
   for i:=1 to SizeOf(N)*8 do
   begin
      if N<0 then
         S:=S+'1'
      else
      begin
         S:=S+'0';
      end;
      N:=N shl 1;
   end;
   Delete(S, 1, Pos('1', S)-1);
//   if Negative then
//   begin
//      S:='-'+S;
//   end;
   Result:=S;
end;

function TfrmPrincipal.Pow(i, k: Integer): Integer;
var
  j, Count: Integer;
begin
   if k>0 then
   begin
      j:=2
   end
   else
   begin
      j:=1;
   end;
   for Count:=1 to k-1 do
   begin
      j:=j*2;
   end;
   Result:=j;
end;

function TfrmPrincipal.BinToDec(Str: string): Integer;
var
  Len, Res, i: Integer;
  Error: Boolean;
begin
   Error:=False;
   Len:=Length(Str);
   Res:=0;
   for i:=1 to Len do
   begin
      if (Str[i]='0')or(Str[i]='1') then
      Res:=Res+Pow(2, Len-i)*StrToInt(Str[i])
      else
      begin
         Error:=True;
         Break;
      end;
   end;
   if Error = True then
   begin
      Result:=0
   end
   else
   begin
      Result:=Res;
   end;
end;

procedure TfrmPrincipal.Button1Click(Sender: TObject);
var
   lContador: Integer;
begin
   IniciarPopulacao;
   CriaExibicao;

   ListView.BeginUpdate;
   lContador := 0;
   while lContador <  NUM_GERACOES do
   begin
      AdicionarMaisAptoExibicao;
      CruzaEMuta;
      SelecionaNovaPopulacao;
      Inc(lContador);
   end;
   ListView.EndUpdate;
end;

procedure TfrmPrincipal.CompletaPalavraBin(var pPalavra: string);
var
   lNovaPalavra: string;
   lChar: Char;
   lTamanhoOrigem: Integer;
begin
   lTamanhoOrigem := Length(pPalavra);
   lNovaPalavra := '';
   lNovaPalavra.Insert(1, pPalavra);

   while Length(lNovaPalavra) <= TAMANHO_BINARIO do
   begin
      lNovaPalavra.Insert(1, '0');
   end;
   pPalavra := lNovaPalavra;
end;

function TfrmPrincipal.Cruzar(pRecnoA, pRecnoB: integer): TStringList;
var
   lBinA, lBinB   : string;
   lNovoA, lNovoB : string;
   lNovaStr       : string;
   i              : Integer;
   lLista         : TStringList;
begin
   {Selecionar item por índice e obter binario}
   mtblPopulacao.RecNo := pRecnoA;
   lBinA := mtblPopulacaoBINARIO.AsString;
   mtblPopulacao.RecNo := pRecnoB;
   lBinB := mtblPopulacaoBINARIO.AsString;
   {Copiar genoma até ponto de corte}
   lNovoA := lBinA.Substring(1, PONTO_CORTE);
   {Copiar genoma a partir}
   lNovoB := lBinB.Substring(PONTO_CORTE, Length(lBinB));
   {Retornar dupla de filhos gerados}
   lLista := TStringList.Create;
   lLista.Add(lNovoA + lNovoB);
   lLista.Add(lNovoB + lNovoA);
   Result := lLista;
end;





end.
