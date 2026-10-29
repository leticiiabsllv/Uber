-- =========================================================================
-- AVALIAÇÃO: TRANSFORMAÇÃO DO MODELO CONCEITUAL (DER)
-- Contexto: Aplicativo de transporte/UBER
-- =========================================================================

-- Remove o banco de dados se ele já existir para evitar erros
DROP DATABASE IF EXISTS UBER;

-- Criação do banco de dados (o nosso "container" de tabelas)
CREATE DATABASE UBER;
USE UBER;

-- =========================================================================
-- 1. TABELA CLIENTE (Entidade Forte)
-- CONCEITO:
-- * No DER em papel, o Cliente tinha o CPF como identificador (Chave Natural).
-- * DECISÃO DE PROJETO: Adotamos um 'idCliente' artificial (Surrogate Key) do tipo INT UNSIGNED.
-- * POR QUE 'UNSIGNED'? Removemos os números negativos, dobrando o limite
--   de clientes que o sistema pode cadastrar (de 2 bilhões para 4 bilhões).
-- =========================================================================
-- SOBRE 1ª FORMA NORMAL (1FN - ATOMICIDADE):
--
-- CONCEITO INICIAL REPRESENTADO NO MODELO DE ENTIDADE E RELACIONAMENTO:
-- O Cliente possui Atributo Composto (Endereço) e Atributo Multivalorado (E-mail).
--
-- APLICAÇÃO DA 1ª FORMA NORMAL (1FN - ATOMICIDADE):
-- 1. Atributo Composto (Endereço): Foi DESMEMBRADO em suas partes simples e
--    atômicas: logradouro, numero, bairro, cidade, uf e cep.
-- 2. Atributo Multivalorado (E-mail): Um cliente pode ter N e-mails. Para não
--    violar a 1FN (evitando criar colunas email1, email2 ou colocar múltiplos
--    e-mails na mesma célula separados por vírgula), o e-mail FOI REMOVIDO
--    desta tabela e virou uma nova tabela relacionada ('ClienteEmail').

CREATE TABLE Cliente (
  -- idCliente: Chave Primária (PK). Identifica unicamente cada cliente de forma segura.
  idCliente INT UNSIGNED NOT NULL PRIMARY KEY,

  -- nome: Atributo simples/atômico obrigatório (NOT NULL).
  nome VARCHAR(125) NOT NULL,
  CPF VARCHAR(11) NOT NULL UNIQUE,

  -- ATRIBUTO COMPOSTO (ENDEREÇO) DESMEMBRADO (1FN):
  -- Todos os campos são atômicos e indivisíveis.
  logradouro VARCHAR(150) NOT NULL,
  numero VARCHAR(10) NOT NULL,
  bairro VARCHAR(60) NOT NULL,
  cidade VARCHAR(60) NOT NULL,
  uf CHAR(2) NOT NULL,
  cep CHAR(8) NOT NULL
);


-- =========================================================================
-- 1.1 TABELA CLIENTE_EMAIL (Solução da 1FN para Atributo Multivalorado)
--
-- CONCEITO:
-- Como um Cliente pode ter zero, um ou múltiplos e-mails, criamos esta
-- tabela associada. A chave primária é COMPOSTA (idCliente + email) para
-- evitar que o mesmo e-mail seja cadastrado duas vezes para o mesmo cliente.
-- =========================================================================
CREATE TABLE ClienteEmail (
  idCliente INT UNSIGNED NOT NULL,
  email VARCHAR(100) NOT NULL,

  -- Chave Primária Composta
  PRIMARY KEY (idCliente, email),

  -- Chave Estrangeira com Integridade Referencial
  CONSTRAINT fk_cliente_email
    FOREIGN KEY (idCliente)
    REFERENCES Cliente(idCliente)
);

-- =========================================================================
-- 2. TABELA CORRIDA (Relacionamento 1:1 com Cliente)
-- CONCEITO DE MAPEAMENTO (REGRA DE OURO):
-- - No relacionamento 1:1 ("Um cliente realiza apenas uma corrida por vez"), a chave
--   primária da entidade "1" (Cliente) "viaja" para a entidade "1" (Corrida)
--   transformando-se em uma Chave Estrangeira (Foreign Key).
-- =========================================================================
CREATE TABLE Corrida (

  -- idCorrida: Identificador único de cada corrida realizada.
  idCorrida int UNSIGNED NOT NULL PRIMARY KEY,

  -- dataCorrida: Armazena o momento em que a corrida foi solicitada.
  dataCorrida DATE NOT NULL,

  -- idCliente (FK): A "ponte" que liga a corrida ao seu respectivo cliente.
  -- Precisa ter EXATAMENTE o mesmo tipo de dado da origem (INT UNSIGNED).
  idCliente INT UNSIGNED NOT NULL,

  -- CONSTRAINT (Restrição de Integridade Referencial):
  -- Garante que nenhuma corrida seja cadastrada no sistema para um "fantasma"
  -- (ou seja, o idCliente informado precisa existir obrigatoriamente na tabela Cliente).
  CONSTRAINT fk_cliente
    FOREIGN KEY (idCliente)
    REFERENCES Cliente(idCliente)
);

-- =========================================================================
-- 3. POVOANDO O BANCO DE DADOS (INSERÇÃO DE DADOS - DML)
-- =========================================================================

-- CONCEITO DE ORDEM DE INSERÇÃO:
-- Como a tabela 'Corrida' depende da tabela 'Cliente' (devido à Chave Estrangeira),
-- DEVEMOS primeiro cadastrar os Clientes. Tentar solicitar uma Corrida para um
-- Cliente que ainda não existe resultará em erro de integridade referencial!

-- Cadastrando os Clientes na tabela Cliente:
INSERT INTO Cliente (idCliente, nome) VALUES (1, 'Letícia Bezerra Silva');
INSERT INTO Cliente (idCliente, nome) VALUES
(2, 'Udson Willian'),
(3, 'Jacinto da Luz');

-- Cadastrando os Corridas na tabela Corrida:
INSERT INTO Corrida (idCorrida, dataCorrida, idCliente) VALUES
(101, '2026-03-01', 1), -- Corrida 101 feita pela Letícia (idCliente = 1)
(102, '2026-03-02', 2), -- Corrida 102 feita pelo Udson (idCliente = 2)
(103, '2026-03-05', 3); -- Corrida 103 feita pelo Jacinto (idCliente = 3)

-- =========================================================================
-- TESTE DE SEGURANÇA / INTEGRIDADE REFERENCIAL (DESAFIO PARA OS ALUNOS)
-- =========================================================================
-- O comando abaixo está COMENTADO porque, se for executado, GERARÁ UM ERRO!
-- Motivo: O idCliente 99 não existe na tabela Cliente. A CONSTRAINT 'fk_cliente'
-- impede que o sistema aceite compras feitas por "clientes fantasmas".
-- INSERT INTO Corrida (idCorrida, dataCorrida, idCliente)
-- VALUES (104, '2026-03-10', 99);
-- Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails...

-- =========================================================================
-- 4. CONSULTANDO OS DADOS (SELECT & JOINs)
-- =========================================================================

-- -------------------------------------------------------------------------
-- CONSULTA 1: Listar todos os clientes cadastrados
-- -------------------------------------------------------------------------
SELECT * FROM Cliente;

SELECT idCliente, nome FROM Cliente;

SELECT IdCliente AS 'Codigo do Cliente', nome AS 'Nome' FROM Cliente;


-- -------------------------------------------------------------------------
-- CONSULTA 2: Listar todas as corridas solicitadas
-- -------------------------------------------------------------------------
SELECT * FROM Corrida;


-- -------------------------------------------------------------------------
-- CONSULTA 3: Cruzamento de Dados (INNER JOIN)
-- Exibe apenas as corridas que possuem um cliente associado
-- e apenas os clientes que solicitaram corridas.
-- -------------------------------------------------------------------------
SELECT
    c.idCorrida AS 'Código da Corrida',
    c.dataCorrida AS 'Data da Solicitação',
    c.nome AS 'Nome do Cliente'
FROM Corrida c
INNER JOIN Cliente c ON p.idCliente = c.idCliente;

-- EXPLICAÇÃO DO INNER JOIN:
-- 1. 'Corrida c' e 'Cliente c': Usamos "apelidos" (aliases) para facilitar a leitura.
-- 2. 'ON c.idCliente = c.idCliente': É a "ponte". Diz ao banco para ligar a FK da
--    tabela Corrida com a PK da tabela Cliente.


-- -------------------------------------------------------------------------
-- CONSULTA 4: Cruzamento Completo (LEFT JOIN)
-- Exibe TODOS os clientes, inclusive aqueles que NUNCA solicitaram corridas.
-- -------------------------------------------------------------------------
SELECT
    c.idCliente AS 'ID Cliente',
    c.nome AS 'Nome do Cliente',
    c.idCorrida AS 'Código da Corrida',
    c.dataCorrida AS 'Data'
FROM Cliente c
LEFT JOIN Corrida c ON c.idCliente = c.idCliente;

-- EXPLICAÇÃO DO LEFT JOIN:
-- A tabela da esquerda (Cliente) é a principal. Todos os seus registros aparecem.