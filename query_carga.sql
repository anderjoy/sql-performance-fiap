delete Boleto
delete Cliente
delete Sequencia
delete Monitor
delete MensagemItem
delete Mensagem
delete Arquivo
delete Situacao

INSERT INTO SITUACAO VALUES ('CI9', 'Cliente incluido com sucesso');
INSERT INTO SITUACAO VALUES ('MR9', 'Mensagem recebida com sucesso');
INSERT INTO SITUACAO VALUES ('MP9', 'Mensagem recebida com sucesso');
INSERT INTO SITUACAO VALUES ('AR9', 'Arquivo recebido com sucesso');
INSERT INTO SITUACAO VALUES ('AP9', 'Arquivo processado com sucesso');
INSERT INTO SITUACAO VALUES ('BP8', 'Boleto recebido com sucesso. Aguardando pagamento');

/*

select count(1) as qtd from Cliente with (nolock)

select * from Sequencia
select * from Cliente
select * from Monitor
select * from Mensagem
select * from MensagemItem
select * from Arquivo
select * from Boleto

*/