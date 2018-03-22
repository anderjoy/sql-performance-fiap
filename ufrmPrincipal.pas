unit ufrmPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.VCLUI.Wait, FireDAC.Phys.ODBCBase,
  FireDAC.Comp.UI, Data.DB, FireDAC.Comp.Client, FireDAC.DApt, System.Diagnostics;

type
  TForm1 = class(TForm)
    btnCarregar: TButton;
    edtServer: TLabeledEdit;
    edtUsername: TLabeledEdit;
    edtPassword: TLabeledEdit;
    edtDatabase: TLabeledEdit;
    FDConnection1: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink;
    Memo1: TMemo;
    btnProcBoleto: TButton;
    btnPagar: TButton;
    btnEnvBoleto: TButton;
    btnEnvBltArqv: TButton;
    FDConnection2: TFDConnection;
    procedure btnCarregarClick(Sender: TObject);
    procedure btnProcBoletoClick(Sender: TObject);
    procedure btnPagarClick(Sender: TObject);
    procedure btnEnvBoletoClick(Sender: TObject);
    procedure btnEnvBltArqvClick(Sender: TObject);
  private
    xTime: TStopWatch;

    function Conectar(): Boolean;

    procedure CarregaClientes();
    procedure ReceberMensagens();
    procedure ReceberArquivos();
    procedure ProcessaBoletosRec();
    procedure PagarBoletos();
    procedure EnviarBoletosMsg();
    procedure EnviarBoletosArqv();

    function GetCPFCNPJ(TPPessoa: string; SeqTit: Int64): Int64;

    function GetTimeFormated(): string;
    function GetNowAsString(): string;
    procedure AddLogInicio(Msg: String);
    procedure AddMsgLog(Msg: String);
    procedure AddLogFim(Msg: String);

    procedure GravarMonitor(CDMensagem: string; Mensagem: string; Prioridade: Integer = 1);

    function GetProximaSequencia(CDSequencia: string): Integer;
    function AlocarSequencia(CDSequencia: string; Quantidade: Integer): Integer;

    function GetYearMonthDayAsString: string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  FireDAC.Stan.Param, System.StrUtils, System.DateUtils;

  //ajesus.ddns.net,3312

{$R *.dfm}

const
  MAX_ARRAYSIZE: Integer = 1000;

  TOTAL_CLIENTE      : Integer = 10000;
  TOTAL_MENSAGEM     : Integer = 10000;
  TOTAL_MSGITEMPORMSG: Integer = 7;


function Zeros(Valor: string; Tamanho: integer; Esquerda: Boolean = True): string; overload;
var
  Negativo: Boolean;
begin
  Negativo := (Copy(Valor, 1, 1) = '-');
  if Negativo then
      Valor := StringReplace(Valor, '-', '', []);

  Result := Copy(Valor, 1, Tamanho);

  while Length(Result) < Tamanho do
      Result := ifthen(Esquerda, '0' + Result, Result + '0');

  if Negativo then
      Result := '-' + Result;
end;

function Zeros(Valor: Int64; Tamanho: integer; Esquerda: Boolean = True): string; overload;
begin
  Result := Zeros(InttoStr(Valor), Tamanho, Esquerda);
end;

function TForm1.Conectar: Boolean;
begin
  Result := False;

  FDConnection1.Close;
  FDConnection1.Params.Values['Database']  := edtDatabase.Text;
  FDConnection1.Params.Values['User_Name'] := edtUsername.Text;
  FDConnection1.Params.Values['Password']  := edtPassword.Text;
  FDConnection1.Params.Values['Server']    := edtServer.Text;
  FDConnection1.Open();

  FDConnection2.Close;
  FDConnection2.Params.Values['Database']  := edtDatabase.Text;
  FDConnection2.Params.Values['User_Name'] := edtUsername.Text;
  FDConnection2.Params.Values['Password']  := edtPassword.Text;
  FDConnection2.Params.Values['Server']    := edtServer.Text;
  FDConnection2.Open();

  Result := True;
end;

procedure TForm1.AddLogInicio(Msg: String);
begin
  Msg := GetTimeFormated() + ' -> Inicio : ' + Msg;

  Memo1.Lines.Add(Msg);

  xTime := TStopwatch.StartNew;

  GravarMonitor('INICIO', Msg);

  Application.ProcessMessages();
end;

procedure TForm1.AddMsgLog(Msg: String);
begin
  Msg := GetTimeFormated() + ' -> Log: ' + Msg;

  Memo1.Lines.Add(Msg);

  GravarMonitor('LOG', Msg);

  Application.ProcessMessages();
end;

procedure TForm1.AddLogFim(Msg: String);
begin
  xTime.Stop;

  Msg := GetTimeFormated() + ' -> FIM: ' + Msg + ' -> ' +

    Format('%s:%s:%s.%s',
    [
      Zeros(xTime.Elapsed.Hours, 2),
      Zeros(xTime.Elapsed.Minutes, 2),
      Zeros(xTime.Elapsed.Seconds, 2),
      Zeros(xTime.Elapsed.Milliseconds, 3)
    ]);

  Memo1.Lines.Add(Msg);

  GravarMonitor('FIM', Msg);

  Memo1.Lines.Add(StringOfChar('-', 30));

  Application.ProcessMessages();
end;

function TForm1.GetCPFCNPJ(TPPessoa: string; SeqTit: Int64): Int64;

  function DV_CPF(CPF_NUM: string): string;
  var
    CPFa, CPFb, CPFc, CPFd, CPFe, CPFf, CPFg, CPFh: integer;
    CPFi, CPFj, CPFk, p1, p2: integer;
  begin
    if length(CPF_NUM) = 9 then
    begin
      CPFa := StrToInt(CPF_NUM[1]);
      CPFb := StrToInt(CPF_NUM[2]);
      CPFc := StrToInt(CPF_NUM[3]);
      CPFd := StrToInt(CPF_NUM[4]);
      CPFe := StrToInt(CPF_NUM[5]);
      CPFf := StrToInt(CPF_NUM[6]);
      CPFg := StrToInt(CPF_NUM[7]);
      CPFh := StrToInt(CPF_NUM[8]);
      CPFi := StrToInt(CPF_NUM[9]);
      p1   := 10 * CPFa + 9 * CPFb + 8 * CPFc + 7 * CPFd + 6 * CPFe + 5 * CPFf + 4 * CPFg + 3 * CPFh + 2 * CPFi;
      if (p1 mod 11) < 2 then
        CPFj := 0
      else
        CPFj := 11 - (p1 mod 11);
      p2     := 11 * CPFa + 10 * CPFb + 9 * CPFc + 8 * CPFd + 7 * CPFe + 6 * CPFf + 5 * CPFg + 4 * CPFh + 3 * CPFi + 2 * CPFj;
      if (p2 mod 11) < 2 then
        CPFk := 0
      else
        CPFk := 11 - (p2 mod 11);
      result := FloatToStr(CPFj) + FloatToStr(CPFk);
    end;
  end;

  function DC_CNPJ(CNPJ: Int64): String;
  var
    I, code: integer;
    d2: array [1 .. 12] of integer;
    DF4, DF5, DF6, RESTO1, Pridig, Segdig: integer;
    Pridig2, Segdig2: string;
    t_texto: string;
  begin
    t_texto := Zeros(CNPJ, 12);

    for I := 1 to 12 do
      Val(t_texto[I], d2[I], code);

    // Cálculo DV
    DF4 := 5 * d2[1] + 4 * d2[2] + 3 * d2[3] + 2 * d2[4] + 9 * d2[5] + 8 * d2[6] + 7 * d2[7] + 6 * d2[8] + 5 * d2[9] + 4 * d2[10] + 3 * d2[11] + 2 * d2[12];

    DF5 := DF4 div 11;
    DF6 := DF5 * 11;

    RESTO1 := DF4 - DF6;
    if (RESTO1 = 0) or (RESTO1 = 1) then
      Pridig := 0
    else
      Pridig := 11 - RESTO1;

    for I := 1 to 12 do
      Val(t_texto[I], d2[I], code);

    DF4 := 6 * d2[1] + 5 * d2[2] + 4 * d2[3] + 3 * d2[4] + 2 * d2[5] + 9 * d2[6] + 8 * d2[7] + 7 * d2[8] + 6 * d2[9] + 5 * d2[10] + 4 * d2[11] + 3 * d2[12] + 2 * Pridig;

    DF5 := DF4 div 11;
    DF6 := DF5 * 11;

    RESTO1 := DF4 - DF6;
    if (RESTO1 = 0) or (RESTO1 = 1) then
      Segdig := 0
    else
      Segdig := 11 - RESTO1;

    Str(Pridig, Pridig2);
    Str(Segdig, Segdig2);

    Result := t_texto + Pridig2 + Segdig2;
  end;

begin
  Result := 0;
  case TPPessoa[1] of
    'F': Result := StrToInt64(Zeros(SeqTit, 9)  + DV_CPF (Zeros(SeqTit, 9)));
    'J': Result := StrToInt64(DC_CNPJ(SeqTit));
  end;
end;

function TForm1.GetYearMonthDayAsString: string;
begin
  Result := FormatDateTime('yyyymmdd', Now());
end;

function TForm1.GetNowAsString: string;
begin
  Result := FormatDateTime('yyyymmddhhnnss', Now());
end;

function TForm1.GetTimeFormated: string;
begin
  Result := FormatDateTime('HH:nn:ss.zzz', Now());
end;


procedure TForm1.btnCarregarClick(Sender: TObject);
begin
  if Conectar() then begin

    try

      FDConnection1.StartTransaction;

      CarregaClientes();
      ReceberMensagens();
      ReceberArquivos();

      FDConnection1.Commit;

    except
      on E: Exception do begin

        if FDConnection1.InTransaction then begin

          AddMsgLog('Error: ' + E.Message);

          FDConnection1.Rollback;
        end;
      end;

    end;
  end;

end;

procedure TForm1.btnProcBoletoClick(Sender: TObject);
begin
  if Conectar() then begin

    try

      FDConnection1.StartTransaction;

      ProcessaBoletosRec();

      FDConnection1.Commit;

    except
      on E: Exception do begin

        if FDConnection1.InTransaction then begin

          AddMsgLog('Error: ' + E.Message);

          FDConnection1.Rollback;
        end;
      end;

    end;
  end;
end;

procedure TForm1.btnPagarClick(Sender: TObject);
begin
  if Conectar() then begin

    try

      FDConnection1.StartTransaction;

      PagarBoletos();

      FDConnection1.Commit;

    except
      on E: Exception do begin

        if FDConnection1.InTransaction then begin

          AddMsgLog('Error: ' + E.Message);

          FDConnection1.Rollback;
        end;
      end;

    end;
  end;
end;

procedure TForm1.btnEnvBoletoClick(Sender: TObject);
begin
  if Conectar() then begin

    try

      FDConnection1.StartTransaction;

      EnviarBoletosMsg();

      FDConnection1.Commit;

    except
      on E: Exception do begin

        if FDConnection1.InTransaction then begin

          AddMsgLog('Error: ' + E.Message);

          FDConnection1.Rollback;
        end;
      end;

    end;
  end;
end;

procedure TForm1.btnEnvBltArqvClick(Sender: TObject);
begin
  if Conectar() then begin

    try

      FDConnection1.StartTransaction;

      EnviarBoletosArqv();

      FDConnection1.Commit;

    except
      on E: Exception do begin

        if FDConnection1.InTransaction then begin

          AddMsgLog('Error: ' + E.Message);

          FDConnection1.Rollback;
        end;
      end;

    end;
  end;
end;

function TForm1.GetProximaSequencia(CDSequencia: string): Integer;
var
  qryGetProximaSequencia: TFDQuery;
begin
  Result := 1;

  FDConnection2.StartTransaction;
  try

    qryGetProximaSequencia := TFDQuery.Create(nil);
    try
      qryGetProximaSequencia.Connection := FDConnection2;

      qryGetProximaSequencia.ExecSQL(
        'UPDATE SEQUENCIA SET VALOR = VALOR + 1 ' +
        'WHERE CDSEQUENCIA = ' + QuotedStr(CDSequencia)
      );

      if qryGetProximaSequencia.RowsAffected = 1 then begin

        qryGetProximaSequencia.Open(
          'SELECT VALOR ' +
          'FROM SEQUENCIA ' +
          'WHERE CDSEQUENCIA = ' + QuotedStr(CDSequencia)
        );

        Result := qryGetProximaSequencia.Fields[0].AsInteger;

      end else begin

        qryGetProximaSequencia.ExecSQL(

          'INSERT INTO Sequencia ' +
          ' (CDSequencia, ' +
          '  DTSequencia, ' +
          '  Valor, ' +
          '  Situacao) ' +
          'VALUES ' +
          ' (' + QuotedStr(CDSequencia) + ', ' +
          '  ' + GetYearMonthDayAsString() + ', ' +
          '  ' + '1' + ', ' +
          '  ' + QuotedStr('A') + ')'

        );
      end;

    finally
      FreeAndNil(qryGetProximaSequencia);
    end;
  finally
    FDConnection2.Commit;
  end;
end;

function TForm1.AlocarSequencia(CDSequencia: string; Quantidade: Integer): Integer;
var
  qryAlocarSequencia: TFDQuery;
begin
  Result := 1;

  FDConnection2.StartTransaction;
  try

    qryAlocarSequencia := TFDQuery.Create(nil);
    try
      qryAlocarSequencia.Connection := FDConnection2;

      qryAlocarSequencia.ExecSQL(
        'UPDATE SEQUENCIA SET VALOR = VALOR + 1 + ' + Quantidade.ToString() + ' ' +
        'WHERE CDSEQUENCIA = ' + QuotedStr(CDSequencia)
      );

      if qryAlocarSequencia.RowsAffected = 1 then begin

        qryAlocarSequencia.Open(
          'SELECT VALOR ' +
          'FROM SEQUENCIA ' +
          'WHERE CDSEQUENCIA = ' + QuotedStr(CDSequencia)
        );

        Result := qryAlocarSequencia.Fields[0].AsInteger - Quantidade;

      end else begin

        qryAlocarSequencia.ExecSQL(

          'INSERT INTO Sequencia ' +
          ' (CDSequencia, ' +
          '  DTSequencia, ' +
          '  Valor, ' +
          '  Situacao) ' +
          'VALUES ' +
          ' (' + QuotedStr(CDSequencia) + ', ' +
          '  ' + GetYearMonthDayAsString() + ', ' +
          '  ' + Quantidade.ToString() + ', ' +
          '  ' + QuotedStr('A') + ')'

        );
      end;

    finally
      FreeAndNil(qryAlocarSequencia);
    end;
  finally
    FDConnection2.Commit;
  end;
end;

procedure TForm1.GravarMonitor(CDMensagem, Mensagem: string; Prioridade: Integer);
var
  qryGravarMonitor: TFDQuery;
begin
  qryGravarMonitor := TFDQuery.Create(nil);
  try
    qryGravarMonitor.Connection := FDConnection1;

    qryGravarMonitor.ExecSQL(
      'INSERT INTO Monitor ' +
      '  (IDLog, ' +
      '  CDMensagem, ' +
      '  Texto, ' +
      '  Prioridade, ' +
      '  DHMensagem) ' +
      'VALUES ' +
      ' (' + GetProximaSequencia('Monitor').ToString() + ', ' +
      '  ' + QuotedStr(CDMensagem) + ', ' +
      '  ' + QuotedStr(Mensagem) + ', ' +
      '  ' + Prioridade.ToString() + ', ' +
      '  ' + GetNowAsString() + ')'
    );
  finally
    FreeAndNil(qryGravarMonitor);
  end;
end;

procedure TForm1.CarregaClientes;
const
  TPCliente   : Integer = 0;
  CPFCNPJ     : Integer = 1;
  DHIntegracao: Integer = 2;
  Situacao    : Integer = 3;
  TPCliente2  : Integer = 4;
  CPFCNPJ2    : Integer = 5;


var
  qryClientes: TFDQuery;
  i, iCliente: Integer;

  TPPessoa: string;
begin
  qryClientes := TFDQuery.Create(nil);
  try

    qryClientes.Connection := FDConnection1;

    qryClientes.Open(
      'SELECT COUNT(1) AS QTD FROM CLIENTE'
    );

    iCliente := qryClientes.Fields[0].AsInteger + 1;

    qryClientes.Close;
    qryClientes.SQL.Text   :=
      'INSERT INTO Cliente ' +
      ' (TPCliente, ' +
      '  CPFCNPJ, ' +
      '  DHIntegracao, ' +
      '  Situacao) ' +
      'SELECT ' +
      '  ' + ':TPCliente' + ', ' +
      '  ' + ':CPFCNPJ' + ', ' +
      '  ' + ':DHIntegracao' + ', ' +
      '  ' + ':Situacao' + ' ' +
      'WHERE NOT EXISTS (SELECT 1 ' +
      '                  FROM Cliente CLI ' +
      '                  WHERE CLI.TPCliente = :TPCliente2 ' +
      '                    AND CLI.CPFCNPJ   = :CPFCNPJ2)';

    qryClientes.Params.BindMode               := pbByNumber;
    qryClientes.Params[TPCliente].DataType    := ftString;
    qryClientes.Params[TPCliente].Size        := 1;
    qryClientes.Params[CPFCNPJ].DataType      := ftLargeint;
    qryClientes.Params[DHIntegracao].DataType := ftLargeint;
    qryClientes.Params[Situacao].DataType     := ftString;
    qryClientes.Params[Situacao].Size         := 3;
    qryClientes.Params[TPCliente2].DataType   := ftString;
    qryClientes.Params[TPCliente2].Size       := 1;
    qryClientes.Params[CPFCNPJ2].DataType     := ftLargeint;
    qryClientes.Prepare;

    qryClientes.Params.ArraySize := TOTAL_CLIENTE;

    AddLogInicio('Adicionando clientes');
    for I := 1 to qryClientes.Params.ArraySize  do begin

      if (iCliente mod 2) = 0 then begin
        TPPessoa := 'F';
      end else begin
        TPPessoa := 'J';
      end;

      qryClientes.Params[TPCliente].AsStrings[i - 1]      := TPPessoa;
      qryClientes.Params[CPFCNPJ].AsLargeInts[i - 1]      := GetCPFCNPJ(TPPessoa, iCliente);
      qryClientes.Params[DHIntegracao].AsLargeInts[i - 1] := StrToInt64(FormatDateTime('yyyymmddhhnnss', Now()));
      qryClientes.Params[Situacao].AsStrings[i - 1]       := 'CI9';
      qryClientes.Params[TPCliente2].AsStrings[i - 1]     := qryClientes.Params[TPCliente].AsStrings[i - 1];
      qryClientes.Params[CPFCNPJ2].AsLargeInts[i - 1]     := qryClientes.Params[CPFCNPJ].AsLargeInts[i - 1];

      Inc(iCliente);
    end;

    qryClientes.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;
    qryClientes.Execute(qryClientes.Params.ArraySize);

    AddLogFim(qryClientes.Params.ArraySize.ToString());
  finally
    FreeAndNil(qryClientes);
  end;

end;

procedure TForm1.ReceberMensagens;
const
  MSG_IDMensagem      : Integer = 0;
  MSG_DHMensagem      : Integer = 1;
  MSG_CDMensagem      : Integer = 2;
  MSG_EnvioRecebimento: Integer = 3;
  MSG_Situacao        : Integer = 4;

const
  ITEM_IDMensagemItem: Integer = 0;
  ITEM_IDMensagem    : Integer = 1;
  ITEM_CDTag         : Integer = 2;
  ITEM_Profundidade  : Integer = 3;
  ITEM_ValorTag      : Integer = 4;

var
  qryMensagem, qryMensagemItem: TFDQuery;
  i, iItem, iIndexItem, iSeqMsg, iSeqMsgItem: Integer;
begin

  qryMensagem     := TFDQuery.Create(nil);
  qryMensagemItem := TFDQuery.Create(nil);
  try

    qryMensagem.Connection     := FDConnection1;
    qryMensagemItem.Connection := FDConnection1;

    qryMensagem.SQL.Text   :=
      'INSERT INTO Mensagem ' +
      ' (IDMensagem, ' +
      '  DHMensagem, ' +
      '  CDMensagem, ' +
      '  EnvioRecebimento, ' +
      '  Situacao) ' +
      'VALUES ' +
      ' (' + ':IDMensagem' + ', ' +
      '  ' + ':DHMensagem' + ', ' +
      '  ' + ':CDMensagem' + ', ' +
      '  ' + ':EnvioRecebimento' + ', ' +
      '  ' + ':Situacao' + ')';

    qryMensagem.Params.BindMode                       := pbByNumber;
    qryMensagem.Params[MSG_IDMensagem].DataType       := ftInteger;
    qryMensagem.Params[MSG_DHMensagem].DataType       := ftLargeint;
    qryMensagem.Params[MSG_CDMensagem].DataType       := ftString;
    qryMensagem.Params[MSG_CDMensagem].Size           := 20;
    qryMensagem.Params[MSG_EnvioRecebimento].DataType := ftString;
    qryMensagem.Params[MSG_EnvioRecebimento].Size     := 1;
    qryMensagem.Params[MSG_Situacao].DataType         := ftString;
    qryMensagem.Params[MSG_Situacao].Size             := 3;
    qryMensagem.Prepare;

    qryMensagemItem.SQL.Text :=
      'INSERT INTO MensagemItem ' +
      '  (IDMensagemItem, ' +
      '  IDMensagem, ' +
      '  CDTag, ' +
      '  Profundidade, ' +
      '  ValorTag) ' +
      'VALUES ' +
      ' (' + ':IDMensagemItem' + ', ' +
      '  ' + ':IDMensagem' + ', ' +
      '  ' + ':CDTag' + ', ' +
      '  ' + ':Profundidade' + ', ' +
      '  ' + ':ValorTag' + ')';

    qryMensagemItem.Params.BindMode                      := pbByNumber;
    qryMensagemItem.Params[ITEM_IDMensagemItem].DataType := ftInteger;
    qryMensagemItem.Params[ITEM_IDMensagem].DataType     := ftInteger;
    qryMensagemItem.Params[ITEM_CDTag].DataType          := ftString;
    qryMensagemItem.Params[ITEM_CDTag].Size              := 50;
    qryMensagemItem.Params[ITEM_Profundidade].DataType   := ftInteger;
    qryMensagemItem.Params[ITEM_ValorTag].DataType       := ftString;
    qryMensagemItem.Params[ITEM_ValorTag].Size           := 4000;
    qryMensagemItem.Prepare;

    //-------------------------------------------------------------------------\\

    qryMensagem.Params.ArraySize     := TOTAL_MENSAGEM;
    qryMensagemItem.Params.ArraySize := TOTAL_MENSAGEM * TOTAL_MSGITEMPORMSG;

    iIndexItem := 0;

    iSeqMsg     := AlocarSequencia('MENSAGEM', TOTAL_MENSAGEM);
    iSeqMsgItem := AlocarSequencia('MSGITEM' , TOTAL_MENSAGEM * TOTAL_MSGITEMPORMSG);

    AddLogInicio('Adicionando mensagens');
    for I := 0 to TOTAL_MENSAGEM - 1 do begin

      qryMensagem.Params[MSG_IDMensagem].AsIntegers[i]      := iSeqMsg;
      qryMensagem.Params[MSG_DHMensagem].AsLargeInts[i]     := StrToInt64(FormatDateTime('yyyymmddhhnnss', Now()));
      qryMensagem.Params[MSG_CDMensagem].AsStrings[i]       := 'REC' + IntToStr(I);
      qryMensagem.Params[MSG_EnvioRecebimento].AsStrings[i] := 'R';
      qryMensagem.Params[MSG_Situacao].AsStrings[i]         := 'MR9';

      for iItem := 0 to TOTAL_MSGITEMPORMSG - 1 do begin

        qryMensagemItem.Params[ITEM_IDMensagemItem].AsIntegers[iIndexItem] := iSeqMsgItem;
        qryMensagemItem.Params[ITEM_IDMensagem].AsIntegers[iIndexItem]     := qryMensagem.Params[MSG_IDMensagem].AsIntegers[i];
        qryMensagemItem.Params[ITEM_CDTag].AsStrings[iIndexItem]           := 'Tag' + IntToStr(iItem);
        qryMensagemItem.Params[ITEM_Profundidade].AsIntegers[iIndexItem]   := 1;
        qryMensagemItem.Params[ITEM_ValorTag].AsStrings[iIndexItem]        := '<Tag' + IntToStr(iItem) + '> Algum conteudo qualquer ' + IntToStr(iItem) + '</Tag' + IntToStr(iItem) + '>';

        inc(iIndexItem);
        Inc(iSeqMsgItem);
      end;

      inc(iSeqMsg);
    end;

    qryMensagem.ResourceOptions.ArrayDMLSize     := MAX_ARRAYSIZE;
    qryMensagemItem.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;

    qryMensagem.Execute(qryMensagem.Params.ArraySize);
    qryMensagemItem.Execute(qryMensagemItem.Params.ArraySize);

    AddLogFim((TOTAL_MENSAGEM * TOTAL_MSGITEMPORMSG).ToString());
  finally
    FreeAndNil(qryMensagem);
    FreeAndNil(qryMensagemItem);
  end;
end;

procedure TForm1.ReceberArquivos;
const
  IDArquivo       : Integer = 0;
  Path            : Integer = 1;
  FileName        : Integer = 2;
  ConteudoXML     : Integer = 3;
  DHRecebimento   : Integer = 4;
  TPArquivo       : Integer = 5;
  EnvioRecebimento: Integer = 6;
  Situacao        : Integer = 7;

var
  qryArquivo: TFDQuery;
  i, iItem, iSeqArquivo: Integer;

  TPPessoa: string;
begin

  qryArquivo := TFDQuery.Create(nil);
  try
    qryArquivo.Connection := FDConnection1;

    qryArquivo.SQL.Text   :=
      'INSERT INTO Arquivo ' +
      ' (IDArquivo, ' +
      '  Path, ' +
      '  FileName, ' +
      '  ConteudoXML, ' +
      '  DHRecebimento, ' +
      '  TPArquivo, ' +
      '  EnvioRecebimento, ' +
      '  Situacao) ' +
      'VALUES ' +
      ' (' + ':IDArquivo' + ', ' +
      '  ' + ':Path' + ', ' +
      '  ' + ':FileName' + ', ' +
      '  ' + ':ConteudoXML' + ', ' +
      '  ' + ':DHRecebimento' + ', ' +
      '  ' + ':TPArquivo' + ', ' +
      '  ' + ':EnvioRecebimento' + ', ' +
      '  ' + ':Situacao' + ')';

    qryArquivo.Params.BindMode                   := pbByNumber;
    qryArquivo.Params[IDArquivo].DataType        := ftInteger;
    qryArquivo.Params[Path].DataType             := ftString;
    qryArquivo.Params[Path].Size                 := 255;
    qryArquivo.Params[FileName].DataType         := ftString;
    qryArquivo.Params[FileName].Size             := 255;
    qryArquivo.Params[ConteudoXML].DataType      := ftMemo;
    qryArquivo.Params[DHRecebimento].DataType    := ftLargeint;
    qryArquivo.Params[TPArquivo].DataType        := ftString;
    qryArquivo.Params[TPArquivo].Size            := 10;
    qryArquivo.Params[EnvioRecebimento].DataType := ftString;
    qryArquivo.Params[EnvioRecebimento].Size     := 1;
    qryArquivo.Params[Situacao].DataType         := ftString;
    qryArquivo.Params[Situacao].Size             := 3;
    qryArquivo.Prepare;

    //-------------------------------------------------------------------------\\

    qryArquivo.Params.ArraySize := TOTAL_MENSAGEM;

    iSeqArquivo := AlocarSequencia('ARQUIVO', TOTAL_MENSAGEM);

    AddLogInicio('Adicionando arquivos');
    for I := 0 to TOTAL_MENSAGEM - 1 do begin

      qryArquivo.Params[IDArquivo].AsIntegers[i]       := iSeqArquivo;
      qryArquivo.Params[Path].AsStrings[i]             := 'C:\ARQV_REC\Connect';
      qryArquivo.Params[FileName].AsStrings[i]         := 'ARQ_REC_' + IntToStr(i) + '.xml';
      qryArquivo.Params[ConteudoXML].AsMemos[i]        := '<Tag' + IntToStr(iItem) + '> Algum conteudo qualquer ' + IntToStr(iItem) + '</Tag' + IntToStr(iItem) + '>';
      qryArquivo.Params[DHRecebimento].AsLargeInts[i]  := StrToInt64(FormatDateTime('yyyymmddhhnnss', Now()));
      qryArquivo.Params[TPArquivo].AsStrings[i]        := 'AREC' + IntToStr(I);
      qryArquivo.Params[EnvioRecebimento].AsStrings[i] := 'R';
      qryArquivo.Params[Situacao].AsStrings[i]         := 'AR9';

      Inc(iSeqArquivo);
    end;

    qryArquivo.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;
    qryArquivo.Execute(qryArquivo.Params.ArraySize);

    AddLogFim(qryArquivo.Params.ArraySize.ToString());
  finally
    FreeAndNil(qryArquivo);
  end;
end;

procedure TForm1.ProcessaBoletosRec;
const
  NrBoleto           : Integer = 0;
  TPCliente          : Integer = 1;
  CPFCNPJ            : Integer = 2;
  IDMensagemRec      : Integer = 3;
  IDArquivoRec       : Integer = 4;
  LinhaDigitavel     : Integer = 5;
  CodBarras          : Integer = 6;
  Valor              : Integer = 7;
  CDProduto          : Integer = 8;
  NMProduto          : Integer = 9;
  DSProduto          : Integer = 10;
  Observacoes        : Integer = 11;
  DTVencimento       : Integer = 12;
  Juros              : Integer = 13;
  TPDestinatario     : Integer = 14;
  CPFCNPJDestinatario: Integer = 15;
  Cancelado          : Integer = 16;
  Situacao           : Integer = 17;

const
  ATLM_IDMensagem: Integer = 1;
  ATLM_Situacao  : Integer = 0;

const
  ATLA_IDArquivo: Integer = 1;
  ATLA_Situacao : Integer = 0;

var
  qryBoleto: TFDQuery;
  qryArquivos, qryMensagens, qryMensagemItem, qryExisteCliente, qryAtualizaMensagem, qryAtualizaArquivo: TFDQuery;
  iDML: Integer;

  i, iItem: Integer;

  TPPessoa: string;
  iCPFCNPJ: Int64;
begin
  Randomize;

  qryBoleto           := TFDQuery.Create(nil);
  qryArquivos         := TFDQuery.Create(nil);
  qryMensagens        := TFDQuery.Create(nil);
  qryMensagemItem     := TFDQuery.Create(nil);
  qryExisteCliente    := TFDQuery.Create(nil);
  qryAtualizaMensagem := TFDQuery.Create(nil);
  qryAtualizaArquivo  := TFDQuery.Create(nil);
  try
    qryBoleto.Connection           := FDConnection1;
    qryArquivos.Connection         := FDConnection1;
    qryMensagens.Connection        := FDConnection1;
    qryMensagemItem.Connection     := FDConnection1;
    qryExisteCliente.Connection    := FDConnection1;
    qryAtualizaMensagem.Connection := FDConnection1;
    qryAtualizaArquivo.Connection  := FDConnection1;

    qryExisteCliente.SQL.Text :=
      'SELECT 1 ' +
      'FROM Cliente ' +
      'WHERE TPCliente = :TPCliente ' +
      '  AND CPFCNPJ   = :CPFCNPJ';
    qryExisteCliente.Params.BindMode    := pbByNumber;
    qryExisteCliente.Params[0].DataType := ftString;
    qryExisteCliente.Params[0].Size     := 1;
    qryExisteCliente.Params[1].DataType := ftLargeint;
    qryExisteCliente.Prepare;

    qryAtualizaMensagem.SQL.Text :=
      'UPDATE Mensagem ' +
      '  SET Situacao = ' + ':Situacao' + ' ' +
      'WHERE IDMensagem = :IDMensagem';
    qryAtualizaMensagem.Params.BindMode                  := pbByNumber;
    qryAtualizaMensagem.Params[ATLM_IDMensagem].DataType := ftInteger;
    qryAtualizaMensagem.Params[ATLM_Situacao].DataType   := ftString;
    qryAtualizaMensagem.Params[ATLM_Situacao].Size       := 3;
    qryAtualizaMensagem.Prepare;

    qryMensagemItem.SQL.Text :=
      'SELECT IDMensagemItem, IDMensagem, IDMensagemPai, CDTag, Profundidade, ValorTag ' +
      'FROM MensagemItem ' +
      'WHERE IDMensagem = :IDMensagem';
    qryMensagemItem.Params.BindMode    := pbByNumber;
    qryMensagemItem.Params[0].DataType := ftInteger;
    qryMensagemItem.Prepare;

    qryAtualizaArquivo.SQL.Text :=
      'UPDATE Arquivo ' +
      '  SET Situacao = ' + ':Situacao' + ' ' +
      'WHERE IDArquivo = :IDArquivo';
    qryAtualizaArquivo.Params.BindMode                 := pbByNumber;
    qryAtualizaArquivo.Params[ATLA_IDArquivo].DataType := ftInteger;
    qryAtualizaArquivo.Params[ATLA_Situacao].DataType  := ftString;
    qryAtualizaArquivo.Params[ATLA_Situacao].Size      := 3;
    qryAtualizaArquivo.Prepare;

    qryBoleto.SQL.Text   :=
      'INSERT INTO Boleto ' +
      ' (NrBoleto, ' +
      '  TPCliente, ' +
      '  CPFCNPJ, ' +
      '  IDMensagemRec, ' +
      '  IDArquivoRec, ' +
      '  LinhaDigitavel, ' +
      '  CodBarras, ' +
      '  Valor, ' +
      '  CDProduto, ' +
      '  NMProduto, ' +
      '  DSProduto, ' +
      '  Observacoes, ' +
      '  DTVencimento, ' +
      '  Juros, ' +
      '  TPDestinatario, ' +
      '  CPFCNPJDestinatario, ' +
      '  Cancelado, ' +
      '  Situacao) ' +
      'VALUES ' +
      ' (' + ':NrBoleto' + ', ' +
      '  ' + ':TPCliente' + ', ' +
      '  ' + ':CPFCNPJ' + ', ' +
      '  ' + ':IDMensagemRec' + ', ' +
      '  ' + ':IDArquivoRec' + ', ' +
      '  ' + ':LinhaDigitavel' + ', ' +
      '  ' + ':CodBarras' + ', ' +
      '  ' + ':Valor' + ', ' +
      '  ' + ':CDProduto' + ', ' +
      '  ' + ':NMProduto' + ', ' +
      '  ' + ':DSProduto' + ', ' +
      '  ' + ':Observacoes' + ', ' +
      '  ' + ':DTVencimento' + ', ' +
      '  ' + ':Juros' + ', ' +
      '  ' + ':TPDestinatario' + ', ' +
      '  ' + ':CPFCNPJDestinatario' + ', ' +
      '  ' + ':Cancelado' + ', ' +
      '  ' + ':Situacao' + ')';

    qryBoleto.Params.BindMode                      := pbByNumber;
    qryBoleto.Params[NrBoleto].DataType            := ftInteger;
    qryBoleto.Params[TPCliente].DataType           := ftString;
    qryBoleto.Params[TPCliente].Size               := 1;
    qryBoleto.Params[CPFCNPJ].DataType             := ftLargeint;
    qryBoleto.Params[IDMensagemRec].DataType       := ftInteger;
    qryBoleto.Params[IDArquivoRec].DataType        := ftInteger;
    qryBoleto.Params[LinhaDigitavel].DataType      := ftString;
    qryBoleto.Params[LinhaDigitavel].Size          := 35;
    qryBoleto.Params[CodBarras].DataType           := ftString;
    qryBoleto.Params[CodBarras].Size               := 41;
    qryBoleto.Params[Valor].DataType               := ftBCD;
    qryBoleto.Params[CDProduto].DataType           := ftString;
    qryBoleto.Params[CDProduto].Size               := 10;
    qryBoleto.Params[NMProduto].DataType           := ftString;
    qryBoleto.Params[NMProduto].Size               := 100;
    qryBoleto.Params[DSProduto].DataType           := ftString;
    qryBoleto.Params[DSProduto].Size               := 400;
    qryBoleto.Params[Observacoes].DataType         := ftString;
    qryBoleto.Params[Observacoes].Size             := 4000;
    qryBoleto.Params[DTVencimento].DataType        := ftInteger;
    qryBoleto.Params[Juros].DataType               := ftBCD;
    qryBoleto.Params[TPDestinatario].DataType      := ftString;
    qryBoleto.Params[TPDestinatario].Size          := 1;
    qryBoleto.Params[CPFCNPJDestinatario].DataType := ftLargeint;
    qryBoleto.Params[Cancelado].DataType           := ftString;
    qryBoleto.Params[Cancelado].Size               := 1;
    qryBoleto.Params[Situacao].DataType            := ftString;
    qryBoleto.Params[Situacao].Size                := 3;
    qryBoleto.Prepare;

    qryBoleto.Params.ArraySize := 0;

    //-------------------------------------------------------------------------\\

    AddLogInicio('Adicionando boletos originados de mensagens');

    qryMensagens.Open(
      'SELECT IDMensagem, ' +
      '       DHMensagem, ' +
      '       CDMensagem, ' +
      '       EnvioRecebimento, ' +
      '       Situacao ' +
      'FROM MENSAGEM ' +
      'WHERE ENVIORECEBIMENTO = ''R'' ' +
      '  AND SITUACAO         = ''MR9'''
    );

    while not qryMensagens.Eof do begin

      iItem := qryMensagens.FieldByName('IDMensagem').AsInteger;

      if (iItem mod 2) = 0 then begin
        TPPessoa := 'F';
      end else begin
        TPPessoa := 'J';
      end;

      iCPFCNPJ := GetCPFCNPJ(TPPessoa, iItem);

      qryExisteCliente.Close;
      qryExisteCliente.Params[0].AsString   := TPPessoa;
      qryExisteCliente.Params[1].AsLargeInt := iCPFCNPJ;
      qryExisteCliente.Open();

      if not qryExisteCliente.IsEmpty then begin

        qryMensagemItem.Close;
        qryMensagemItem.Params[0].AsInteger := qryMensagens.FieldByName('IDMensagem').AsInteger;
        qryMensagemItem.Open();

        qryBoleto.Params.ArraySize := qryBoleto.Params.ArraySize + 1;
        iDML                       :=  qryBoleto.Params.ArraySize - 1;

        qryBoleto.Params[NrBoleto].AsIntegers[iDML]      := GetProximaSequencia('Boleto');
        qryBoleto.Params[TPCliente].AsStrings[iDML]      := TPPessoa;
        qryBoleto.Params[CPFCNPJ].AsLargeInts[iDML]      := iCPFCNPJ;
        qryBoleto.Params[IDMensagemRec].AsIntegers[iDML] := qryMensagens.FieldByName('IDMensagem').AsInteger;
        qryBoleto.Params[LinhaDigitavel].AsStrings[iDML] := Zeros(iItem, 35);
        qryBoleto.Params[CodBarras].AsStrings[iDML]      := Zeros(iItem, 41);
        qryBoleto.Params[Valor].AsBCDs[iDML]             := iDML * 2.98;
        qryBoleto.Params[CDProduto].AsStrings[iDML]      := 'ACP';
        qryBoleto.Params[NMProduto].AsStrings[iDML]      := 'Alguma coisa';
        qryBoleto.Params[DSProduto].AsStrings[iDML]      := 'Descricao do produto';
        qryBoleto.Params[Observacoes].AsStrings[iDML]    := 'As observações vão aqui haha';
        qryBoleto.Params[DTVencimento].AsIntegers[iDML]  := StrToInt(FormatDateTime('yyyymmdd', IncDay(Now, iDML)));
        qryBoleto.Params[Juros].AsBCDs[iDML]             := 0.46;

        if (iItem + 1 mod 2) = 0 then begin
          TPPessoa := 'F';
        end else begin
          TPPessoa := 'J';
        end;

        iCPFCNPJ := GetCPFCNPJ(TPPessoa, iItem + 1);

        qryBoleto.Params[TPDestinatario].AsStrings[iDML]        := TPPessoa;
        qryBoleto.Params[CPFCNPJDestinatario].AsLargeInts[iDML] := iCPFCNPJ;
        qryBoleto.Params[Cancelado].AsStrings[iDML]             := 'N';
        qryBoleto.Params[Situacao].AsStrings[iDML]              := 'BP8';

        qryAtualizaMensagem.Close;
        qryAtualizaMensagem.Params[ATLM_IDMensagem].AsInteger := qryMensagens.FieldByName('IDMensagem').AsInteger;
        qryAtualizaMensagem.Params[ATLM_Situacao].AsString    := 'MP9';
        qryAtualizaMensagem.ExecSQL;
      end;

      Inc(iItem);
      qryMensagens.Next;
    end;

    if qryBoleto.Params.ArraySize > 0 then begin

      qryBoleto.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;
      qryBoleto.Execute(qryBoleto.Params.ArraySize);
    end;

    AddLogFim(qryBoleto.Params.ArraySize.ToString());

    qryBoleto.Params.ArraySize := 0;

    //-------------------------------------------------------------------------\\

    AddLogInicio('Adicionando boletos originados de arquivo');

    qryMensagens.Close;
    qryMensagens.Open(
      'SELECT IDArquivo ' +
      'FROM Arquivo ' +
      'WHERE EnvioRecebimento = ''R'' ' +
      '  AND SITUACAO         = ''AR9'''
    );

    while not qryMensagens.Eof do begin

      iItem := qryMensagens.FieldByName('IDArquivo').AsInteger;

      if (iItem mod 2) = 0 then begin
        TPPessoa := 'F';
      end else begin
        TPPessoa := 'J';
      end;

      iCPFCNPJ := GetCPFCNPJ(TPPessoa, iItem);

      qryExisteCliente.Close;
      qryExisteCliente.Params[0].AsString   := TPPessoa;
      qryExisteCliente.Params[1].AsLargeInt := iCPFCNPJ;
      qryExisteCliente.Open();

      if not qryExisteCliente.IsEmpty then begin

        qryBoleto.Params.ArraySize := qryBoleto.Params.ArraySize + 1;
        iDML                       := qryBoleto.Params.ArraySize - 1;

        qryBoleto.Params[NrBoleto].AsIntegers[iDML]      := GetProximaSequencia('Boleto');
        qryBoleto.Params[TPCliente].AsStrings[iDML]      := TPPessoa;
        qryBoleto.Params[CPFCNPJ].AsLargeInts[iDML]      := iCPFCNPJ;
        qryBoleto.Params[IDArquivoRec].AsIntegers[iDML]  := qryMensagens.FieldByName('IDArquivo').AsInteger;
        qryBoleto.Params[LinhaDigitavel].AsStrings[iDML] := Zeros(iItem, 35);
        qryBoleto.Params[CodBarras].AsStrings[iDML]      := Zeros(iItem, 41);
        qryBoleto.Params[Valor].AsBCDs[iDML]             := 0.98;
        qryBoleto.Params[CDProduto].AsStrings[iDML]      := 'MCP';
        qryBoleto.Params[NMProduto].AsStrings[iDML]      := 'Alguma coisa';
        qryBoleto.Params[DSProduto].AsStrings[iDML]      := 'Descricao do produto';
        qryBoleto.Params[Observacoes].AsStrings[iDML]    := 'As observações vão aqui haha';
        qryBoleto.Params[DTVencimento].AsIntegers[iDML]  := StrToInt(FormatDateTime('yyyymmdd', IncDay(Now, 1)));
        qryBoleto.Params[Juros].AsBCDs[iDML]             := 0.46;

        if (iItem + 1 mod 2) = 0 then begin
          TPPessoa := 'F';
        end else begin
          TPPessoa := 'J';
        end;

        iCPFCNPJ := GetCPFCNPJ(TPPessoa, iItem + 1);

        qryBoleto.Params[TPDestinatario].AsStrings[iDML]        := TPPessoa;
        qryBoleto.Params[CPFCNPJDestinatario].AsLargeInts[iDML] := iCPFCNPJ;
        qryBoleto.Params[Cancelado].AsStrings[iDML]             := 'N';
        qryBoleto.Params[Situacao].AsStrings[iDML]              := 'BP8';

        qryAtualizaArquivo.Close;
        qryAtualizaArquivo.Params[ATLA_IDArquivo].AsInteger := qryMensagens.FieldByName('IDArquivo').AsInteger;
        qryAtualizaArquivo.Params[ATLA_Situacao].AsString   := 'AP9';
        qryAtualizaArquivo.ExecSQL;
      end;

      Inc(iItem);
      qryMensagens.Next;
    end;

    if qryBoleto.Params.ArraySize > 0 then begin

      qryBoleto.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;
      qryBoleto.Execute(qryBoleto.Params.ArraySize);
    end;

    AddLogFim(qryBoleto.Params.ArraySize.ToString());
  finally
    FreeAndNil(qryBoleto);
    FreeAndNil(qryArquivos);
    FreeAndNil(qryMensagens);
    FreeAndNil(qryMensagemItem);
    FreeAndNil(qryExisteCliente);
    FreeAndNil(qryAtualizaMensagem);
    FreeAndNil(qryAtualizaArquivo);
  end;
end;

procedure TForm1.PagarBoletos;
var
  qryPagarBoletos: TFDQuery;
begin
  qryPagarBoletos := TFDQuery.Create(nil);
  try
    qryPagarBoletos.Connection := FDConnection1;

    AddLogInicio('Pagando todos os boletos');

    qryPagarBoletos.ExecSQL(
      'UPDATE BOLETO SET ValorPago        = VALOR, ' +
      '                  DHPagamento      = ' + GetNowAsString() + ', ' +
      '                  Situacao         = ''BP9'', ' +
      '                  CDBancoRecebedor = ''ITAU'' ' +
      'WHERE Situacao  = ''BP8'' ' +
      '  AND Cancelado = ''N'''
    );

    AddLogFim(qryPagarBoletos.RowsAffected.ToString());
  finally
    FreeAndNil(qryPagarBoletos);
  end;
end;

procedure TForm1.EnviarBoletosMsg;
const
  MSG_IDMensagem      : Integer = 0;
  MSG_DHMensagem      : Integer = 1;
  MSG_CDMensagem      : Integer = 2;
  MSG_EnvioRecebimento: Integer = 3;
  MSG_Situacao        : Integer = 4;

const
  ITEM_IDMensagemItem: Integer = 0;
  ITEM_IDMensagem    : Integer = 1;
  ITEM_CDTag         : Integer = 2;
  ITEM_Profundidade  : Integer = 3;
  ITEM_ValorTag      : Integer = 4;

const
  BLT_NrBoleto     : Integer = 2;
  BLT_TPCliente    : Integer = 3;
  BLT_CPFCNPJ      : Integer = 4;
  BLT_IDMensagemEnv: Integer = 1;
  BLT_Situacao     : Integer = 0;

var
  qryEnviarBoletos: TFDQuery;
  qryMensagem, qryMensagemItem, qryAtualizaBoleto: TFDQuery;
  iDML, iDMLItem, iDMLAtu, iIDMensagemEnv, iItem: Integer;
begin
  qryEnviarBoletos  := TFDQuery.Create(nil);
  qryMensagem       := TFDQuery.Create(nil);
  qryMensagemItem   := TFDQuery.Create(nil);
  qryAtualizaBoleto := TFDQuery.Create(nil);
  try
    qryEnviarBoletos.Connection   := FDConnection1;
    qryMensagem.Connection        := FDConnection1;
    qryMensagemItem.Connection    := FDConnection1;
    qryAtualizaBoleto.Connection  := FDConnection1;

    AddLogInicio('Enviando boletos via mensagem');

    qryMensagem.SQL.Text   :=
      'INSERT INTO Mensagem ' +
      ' (IDMensagem, ' +
      '  DHMensagem, ' +
      '  CDMensagem, ' +
      '  EnvioRecebimento, ' +
      '  Situacao) ' +
      'VALUES ' +
      ' (' + ':IDMensagem' + ', ' +
      '  ' + ':DHMensagem' + ', ' +
      '  ' + ':CDMensagem' + ', ' +
      '  ' + ':EnvioRecebimento' + ', ' +
      '  ' + ':Situacao' + ')';

    qryMensagem.Params.BindMode                       := pbByNumber;
    qryMensagem.Params[MSG_IDMensagem].DataType       := ftInteger;
    qryMensagem.Params[MSG_DHMensagem].DataType       := ftLargeint;
    qryMensagem.Params[MSG_CDMensagem].DataType       := ftString;
    qryMensagem.Params[MSG_CDMensagem].Size           := 20;
    qryMensagem.Params[MSG_EnvioRecebimento].DataType := ftString;
    qryMensagem.Params[MSG_EnvioRecebimento].Size     := 1;
    qryMensagem.Params[MSG_Situacao].DataType         := ftString;
    qryMensagem.Params[MSG_Situacao].Size             := 3;
    qryMensagem.Prepare;

    qryMensagemItem.SQL.Text :=
      'INSERT INTO MensagemItem ' +
      '  (IDMensagemItem, ' +
      '  IDMensagem, ' +
      '  CDTag, ' +
      '  Profundidade, ' +
      '  ValorTag) ' +
      'VALUES ' +
      ' (' + ':IDMensagemItem' + ', ' +
      '  ' + ':IDMensagem' + ', ' +
      '  ' + ':CDTag' + ', ' +
      '  ' + ':Profundidade' + ', ' +
      '  ' + ':ValorTag' + ')';

    qryMensagemItem.Params.BindMode                      := pbByNumber;
    qryMensagemItem.Params[ITEM_IDMensagemItem].DataType := ftInteger;
    qryMensagemItem.Params[ITEM_IDMensagem].DataType     := ftInteger;
    qryMensagemItem.Params[ITEM_CDTag].DataType          := ftString;
    qryMensagemItem.Params[ITEM_CDTag].Size              := 50;
    qryMensagemItem.Params[ITEM_Profundidade].DataType   := ftInteger;
    qryMensagemItem.Params[ITEM_ValorTag].DataType       := ftString;
    qryMensagemItem.Params[ITEM_ValorTag].Size           := 4000;
    qryMensagemItem.Prepare;

    qryAtualizaBoleto.SQL.Text :=
      'UPDATE BOLETO SET SITUACAO      = :SITUACAO, ' +
      '                  IDMensagemEnv = :IDMensagemEnv ' +
      'WHERE NRBOLETO  = :NRBOLETO ' +
      '  AND TPCLIENTE = :TPCLIENTE ' +
      '  AND CPFCNPJ   = :CPFCNPJ';

    qryAtualizaBoleto.Params.BindMode                    := pbByNumber;
    qryAtualizaBoleto.Params[BLT_NrBoleto].DataType      := ftInteger;
    qryAtualizaBoleto.Params[BLT_TPCliente].DataType     := ftString;
    qryAtualizaBoleto.Params[BLT_TPCliente].Size         := 1;
    qryAtualizaBoleto.Params[BLT_CPFCNPJ].DataType       := ftLargeint;
    qryAtualizaBoleto.Params[BLT_IDMensagemEnv].DataType := ftInteger;
    qryAtualizaBoleto.Params[BLT_Situacao].DataType      := ftString;
    qryAtualizaBoleto.Params[BLT_Situacao].Size          := 3;
    qryAtualizaBoleto.Prepare;

    qryMensagem.Params.ArraySize       := 0;
    qryMensagemItem.Params.ArraySize   := 0;
    qryAtualizaBoleto.Params.ArraySize := 0;

    //-------------------------------------------------------------------------\\

    qryEnviarBoletos.Open(
      'SELECT * ' +
      'FROM BOLETO ' +
      'WHERE IDMensagemRec IS NOT NULL ' +
      '  AND Situacao  = ''BP9'' ' +
      '  AND Cancelado = ''N'''
    );

    while not qryEnviarBoletos.Eof do begin

      iIDMensagemEnv := GetProximaSequencia('MENSAGEM');

      qryMensagem.Params.ArraySize := qryMensagem.Params.ArraySize + 1;
      iDML                         :=  qryMensagem.Params.ArraySize - 1;

      qryMensagem.Params[MSG_IDMensagem].AsIntegers[iDML]      := iIDMensagemEnv;
      qryMensagem.Params[MSG_DHMensagem].AsLargeInts[iDML]     := StrToInt64(FormatDateTime('yyyymmddhhnnss', Now()));
      qryMensagem.Params[MSG_CDMensagem].AsStrings[iDML]       := 'ENV' + IntToStr(iDML);
      qryMensagem.Params[MSG_EnvioRecebimento].AsStrings[iDML] := 'E';
      qryMensagem.Params[MSG_Situacao].AsStrings[iDML]         := 'ME9';

      for iItem := 0 to TOTAL_MSGITEMPORMSG - 1 do begin

        qryMensagemItem.Params.ArraySize := qryMensagemItem.Params.ArraySize + 1;
        iDMLItem                         :=  qryMensagemItem.Params.ArraySize - 1;

        qryMensagemItem.Params[ITEM_IDMensagemItem].AsIntegers[iDMLItem] := GetProximaSequencia('MSGITEM');
        qryMensagemItem.Params[ITEM_IDMensagem].AsIntegers[iDMLItem]     := iIDMensagemEnv;
        qryMensagemItem.Params[ITEM_CDTag].AsStrings[iDMLItem]           := 'Tag' + IntToStr(iItem);
        qryMensagemItem.Params[ITEM_Profundidade].AsIntegers[iDMLItem]   := 1;
        qryMensagemItem.Params[ITEM_ValorTag].AsStrings[iDMLItem]        := '<Tag' + IntToStr(iItem) + '> Algum conteudo qualquer ' + IntToStr(iItem) + '</Tag' + IntToStr(iItem) + '>';
      end;

      qryAtualizaBoleto.Params.ArraySize := qryAtualizaBoleto.Params.ArraySize + 1;
      iDMLAtu                            :=  qryAtualizaBoleto.Params.ArraySize - 1;

      qryAtualizaBoleto.Params[BLT_NrBoleto].AsIntegers[iDMLAtu]      := qryEnviarBoletos.FieldByName('NrBoleto').AsInteger;
      qryAtualizaBoleto.Params[BLT_TPCliente].AsStrings[iDMLAtu]      := qryEnviarBoletos.FieldByName('TPCliente').AsString;
      qryAtualizaBoleto.Params[BLT_CPFCNPJ].AsLargeInts[iDMLAtu]      := qryEnviarBoletos.FieldByName('CPFCNPJ').AsLargeInt;
      qryAtualizaBoleto.Params[BLT_IDMensagemEnv].AsIntegers[iDMLAtu] := iIDMensagemEnv;
      qryAtualizaBoleto.Params[BLT_Situacao].AsStrings[iDMLAtu]       := 'BE9';

      qryEnviarBoletos.Next;
    end;

    qryMensagem.ResourceOptions.ArrayDMLSize       := MAX_ARRAYSIZE;
    qryMensagemItem.ResourceOptions.ArrayDMLSize   := MAX_ARRAYSIZE;
    qryAtualizaBoleto.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;

    if qryMensagem.Params.ArraySize > 0 then begin

      qryMensagem.Execute(qryMensagem.Params.ArraySize);
      qryMensagemItem.Execute(qryMensagemItem.Params.ArraySize);
      qryAtualizaBoleto.Execute(qryAtualizaBoleto.Params.ArraySize);
    end;

    AddLogFim(qryEnviarBoletos.RowsAffected.ToString());
  finally
    FreeAndNil(qryEnviarBoletos);
    FreeAndNil(qryMensagem);
    FreeAndNil(qryMensagemItem);
    FreeAndNil(qryAtualizaBoleto);
  end;
end;

procedure TForm1.EnviarBoletosArqv;
const
  IDArquivo       : Integer = 0;
  Path            : Integer = 1;
  FileName        : Integer = 2;
  ConteudoXML     : Integer = 3;
  DHRecebimento   : Integer = 4;
  TPArquivo       : Integer = 5;
  EnvioRecebimento: Integer = 6;
  Situacao        : Integer = 7;

const
  BLT_NrBoleto     : Integer = 2;
  BLT_TPCliente    : Integer = 3;
  BLT_CPFCNPJ      : Integer = 4;
  BLT_IDArquivoEnv : Integer = 1;
  BLT_Situacao     : Integer = 0;

var
  qryEnviarBoletos: TFDQuery;
  qryArquivo, qryAtualizaBoleto: TFDQuery;
  iDML, iDMLAtu: Integer;
begin
  qryEnviarBoletos  := TFDQuery.Create(nil);
  qryAtualizaBoleto := TFDQuery.Create(nil);
  qryArquivo        := TFDQuery.Create(nil);
  try
    qryEnviarBoletos.Connection  := FDConnection1;
    qryArquivo.Connection        := FDConnection1;
    qryAtualizaBoleto.Connection := FDConnection1;

    AddLogInicio('Enviando boletos via arquivo');

    qryArquivo.SQL.Text   :=
      'INSERT INTO Arquivo ' +
      ' (IDArquivo, ' +
      '  Path, ' +
      '  FileName, ' +
      '  ConteudoXML, ' +
      '  DHRecebimento, ' +
      '  TPArquivo, ' +
      '  EnvioRecebimento, ' +
      '  Situacao) ' +
      'VALUES ' +
      ' (' + ':IDArquivo' + ', ' +
      '  ' + ':Path' + ', ' +
      '  ' + ':FileName' + ', ' +
      '  ' + ':ConteudoXML' + ', ' +
      '  ' + ':DHRecebimento' + ', ' +
      '  ' + ':TPArquivo' + ', ' +
      '  ' + ':EnvioRecebimento' + ', ' +
      '  ' + ':Situacao' + ')';

    qryArquivo.Params.BindMode                   := pbByNumber;
    qryArquivo.Params[IDArquivo].DataType        := ftInteger;
    qryArquivo.Params[Path].DataType             := ftString;
    qryArquivo.Params[Path].Size                 := 255;
    qryArquivo.Params[FileName].DataType         := ftString;
    qryArquivo.Params[FileName].Size             := 255;
    qryArquivo.Params[ConteudoXML].DataType      := ftMemo;
    qryArquivo.Params[DHRecebimento].DataType    := ftLargeint;
    qryArquivo.Params[TPArquivo].DataType        := ftString;
    qryArquivo.Params[TPArquivo].Size            := 10;
    qryArquivo.Params[EnvioRecebimento].DataType := ftString;
    qryArquivo.Params[EnvioRecebimento].Size     := 1;
    qryArquivo.Params[Situacao].DataType         := ftString;
    qryArquivo.Params[Situacao].Size             := 3;
    qryArquivo.Prepare;

    qryAtualizaBoleto.SQL.Text :=
      'UPDATE BOLETO SET SITUACAO     = :SITUACAO, ' +
      '                  IDArquivoEnv = :IDArquivoEnv ' +
      'WHERE NRBOLETO  = :NRBOLETO ' +
      '  AND TPCLIENTE = :TPCLIENTE ' +
      '  AND CPFCNPJ   = :CPFCNPJ';

    qryAtualizaBoleto.Params.BindMode                    := pbByNumber;
    qryAtualizaBoleto.Params[BLT_NrBoleto].DataType      := ftInteger;
    qryAtualizaBoleto.Params[BLT_TPCliente].DataType     := ftString;
    qryAtualizaBoleto.Params[BLT_TPCliente].Size         := 1;
    qryAtualizaBoleto.Params[BLT_CPFCNPJ].DataType       := ftLargeint;
    qryAtualizaBoleto.Params[BLT_IDArquivoEnv].DataType  := ftInteger;
    qryAtualizaBoleto.Params[BLT_Situacao].DataType      := ftString;
    qryAtualizaBoleto.Params[BLT_Situacao].Size          := 3;
    qryAtualizaBoleto.Prepare;

    qryArquivo.Params.ArraySize        := 0;
    qryAtualizaBoleto.Params.ArraySize := 0;

    //-------------------------------------------------------------------------\\

    qryEnviarBoletos.Open(
      'SELECT * ' +
      'FROM BOLETO ' +
      'WHERE IDArquivoRec IS NOT NULL ' +
      '  AND Situacao  = ''BP9'' ' +
      '  AND Cancelado = ''N'''
    );

    while not qryEnviarBoletos.Eof do begin

      qryArquivo.Params.ArraySize := qryArquivo.Params.ArraySize + 1;
      iDML                        :=  qryArquivo.Params.ArraySize - 1;

      qryArquivo.Params[IDArquivo].AsIntegers[iDML]       := GetProximaSequencia('ARQUIVO');
      qryArquivo.Params[Path].AsStrings[iDML]             := 'C:\ARQV_ENV\Connect';
      qryArquivo.Params[FileName].AsStrings[iDML]         := 'ARQ_ENV_' + IntToStr(iDML) + '.xml';
      qryArquivo.Params[ConteudoXML].AsMemos[iDML]        := '<Tag' + IntToStr(iDML) + '> Algum conteudo qualquer ' + IntToStr(iDML) + '</Tag' + IntToStr(iDML) + '>';
      qryArquivo.Params[DHRecebimento].AsLargeInts[iDML]  := StrToInt64(FormatDateTime('yyyymmddhhnnss', Now()));
      qryArquivo.Params[TPArquivo].AsStrings[iDML]        := 'AENV' + IntToStr(iDML);
      qryArquivo.Params[EnvioRecebimento].AsStrings[iDML] := 'E';
      qryArquivo.Params[Situacao].AsStrings[iDML]         := 'AE9';

      qryAtualizaBoleto.Params.ArraySize := qryAtualizaBoleto.Params.ArraySize + 1;
      iDMLAtu                            :=  qryAtualizaBoleto.Params.ArraySize - 1;

      qryAtualizaBoleto.Params[BLT_NrBoleto].AsIntegers[iDMLAtu]     := qryEnviarBoletos.FieldByName('NrBoleto').AsInteger;
      qryAtualizaBoleto.Params[BLT_TPCliente].AsStrings[iDMLAtu]     := qryEnviarBoletos.FieldByName('TPCliente').AsString;
      qryAtualizaBoleto.Params[BLT_CPFCNPJ].AsLargeInts[iDMLAtu]     := qryEnviarBoletos.FieldByName('CPFCNPJ').AsLargeInt;
      qryAtualizaBoleto.Params[BLT_IDArquivoEnv].AsIntegers[iDMLAtu] := qryArquivo.Params[IDArquivo].AsIntegers[iDML];
      qryAtualizaBoleto.Params[BLT_Situacao].AsStrings[iDMLAtu]      := 'BE9';

      qryEnviarBoletos.Next;
    end;

    qryArquivo.ResourceOptions.ArrayDMLSize        := MAX_ARRAYSIZE;
    qryAtualizaBoleto.ResourceOptions.ArrayDMLSize := MAX_ARRAYSIZE;

    if qryArquivo.Params.ArraySize > 0 then begin

      qryArquivo.Execute(qryArquivo.Params.ArraySize);
      qryAtualizaBoleto.Execute(qryAtualizaBoleto.Params.ArraySize);
    end;

    AddLogFim((qryArquivo.Params.ArraySize + qryAtualizaBoleto.Params.ArraySize).ToString());
  finally
    FreeAndNil(qryEnviarBoletos);
    FreeAndNil(qryArquivo);
    FreeAndNil(qryAtualizaBoleto);
  end;
end;

end.
