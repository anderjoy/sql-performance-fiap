-- verifica se é cliente
SELECT 1 
FROM Cliente 
WHERE TPCliente = @TPCliente 
  AND CPFCNPJ   = @CPFCNPJ;

--atualiza a situação da mensagem
UPDATE Mensagem 
  SET Situacao =  @Situacao  
WHERE IDMensagem = @IDMensagem;

--carrega todos os itens da mensagem
SELECT IDMensagemItem, IDMensagem, IDMensagemPai, CDTag, Profundidade, ValorTag 
FROM MensagemItem 
WHERE IDMensagem = @IDMensagem;

--Atualiza a situação doa arquivo
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