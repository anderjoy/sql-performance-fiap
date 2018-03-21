-- verifica se � cliente
SELECT 1 
FROM Cliente 
WHERE TPCliente = @TPCliente 
  AND CPFCNPJ   = @CPFCNPJ;

--atualiza a situa��o da mensagem
UPDATE Mensagem 
  SET Situacao =  @Situacao  
WHERE IDMensagem = @IDMensagem;

--carrega todos os itens da mensagem
SELECT IDMensagemItem, IDMensagem, IDMensagemPai, CDTag, Profundidade, ValorTag 
FROM MensagemItem 
WHERE IDMensagem = @IDMensagem;

--Atualiza a situa��o doa arquivo
UPDATE Arquivo 
  SET Situacao =  @Situacao  
WHERE IDArquivo = @IDArquivo;

--Lista todas as mensagens pendentes de processamento
SELECT IDMensagem, 
        DHMensagem, 
        CDMensagem, 
        EnvioRecebimento, 
        Situacao 
FROM MENSAGEM 
WHERE ENVIORECEBIMENTO = 'R' 
  AND SITUACAO         = 'MR9'

--lista todos arquivos pendentes de processamento
SELECT IDArquivo 
FROM Arquivo 
WHERE EnvioRecebimento = 'R' 
  AND SITUACAO         = 'AR9'

--Atualiza o boleto para enviado via mensagem
UPDATE BOLETO SET SITUACAO      = @SITUACAO, 
                  IDMensagemEnv = @IDMensagemEnv 
WHERE NRBOLETO  = @NRBOLETO 
  AND TPCLIENTE = @TPCLIENTE 
  AND CPFCNPJ   = @CPFCNPJ;

--Lista todos os boletos para envio por mensagem
SELECT * 
FROM BOLETO 
WHERE IDMensagemRec IS NOT NULL 
  AND Situacao  = 'BP9' 
  AND Cancelado = 'N'

--Atualiza o boleto para envio via arquivo
UPDATE BOLETO SET SITUACAO     = @SITUACAO, 
                  IDArquivoEnv = @IDArquivoEnv 
WHERE NRBOLETO  = @NRBOLETO 
  AND TPCLIENTE = @TPCLIENTE 
  AND CPFCNPJ   = @CPFCNPJ;

--Lista todos os boletos para envio via arquivo
SELECT * 
FROM BOLETO 
WHERE IDArquivoRec IS NOT NULL 
  AND Situacao  = 'BP9' 
  AND Cancelado = 'N'