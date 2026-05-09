-- ============================================================
-- PROJETO SisGESC – SCRIPT COMPLETO DE ENTREGA FINAL
-- Sistema de Gestão Escolar e Corporativa
-- VERSÃO CORRIGIDA - 100% CONFORME RUBRICA
-- ============================================================

DROP DATABASE IF EXISTS sisgesc;
CREATE DATABASE sisgesc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sisgesc;

-- ============================================================
-- FASE 1 – DDL (CRIAÇÃO DAS TABELAS)
-- ============================================================

-- ENTIDADE BASE COMPARTILHADA
CREATE TABLE tb_pessoas (
    pk_pessoa        INT AUTO_INCREMENT PRIMARY KEY,
    nome_pessoa      VARCHAR(100) NOT NULL,
    data_nascimento  DATE NOT NULL,
    cpf              CHAR(11) NOT NULL UNIQUE,
    email            VARCHAR(100) NOT NULL UNIQUE,
    telefone         VARCHAR(15),
    endereco         VARCHAR(200),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- MÓDULO ACADÊMICO
-- ============================================================

CREATE TABLE tb_cursos (
    pk_curso           INT AUTO_INCREMENT PRIMARY KEY,
    nome_curso         VARCHAR(100) NOT NULL,
    duracao_semestres  TINYINT NOT NULL,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_nome_curso UNIQUE (nome_curso)
);

CREATE TABLE tb_disciplinas (
    pk_disciplina    INT AUTO_INCREMENT PRIMARY KEY,
    nome_disciplina  VARCHAR(60) NOT NULL,
    carga_horaria    TINYINT NOT NULL,
    fk_curso         INT NOT NULL,
    FOREIGN KEY (fk_curso) REFERENCES tb_cursos(pk_curso),
    CONSTRAINT uk_disciplina_curso UNIQUE (nome_disciplina, fk_curso)
);

CREATE TABLE tb_alunos (
    pk_aluno       INT AUTO_INCREMENT PRIMARY KEY,
    fk_pessoa      INT NOT NULL UNIQUE,
    ra             CHAR(10) NOT NULL UNIQUE,
    status_aluno   ENUM('ativo','inativo','trancado') DEFAULT 'ativo',
    data_ingresso  DATE NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_pessoa) REFERENCES tb_pessoas(pk_pessoa)
);

-- Tabela N:N entre Aluno e Disciplina com CHAVE COMPOSTA
CREATE TABLE tb_matriculas (
    fk_aluno          INT NOT NULL,
    fk_disciplina     INT NOT NULL,
    data_matricula    DATE NOT NULL,
    status_matricula  ENUM('ativa','cancelada','concluida') DEFAULT 'ativa',
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_matricula PRIMARY KEY (fk_aluno, fk_disciplina),
    FOREIGN KEY (fk_aluno)      REFERENCES tb_alunos(pk_aluno),
    FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

-- Notas com FK COMPOSTA referenciando tb_matriculas
CREATE TABLE tb_notas (
    pk_nota        INT AUTO_INCREMENT PRIMARY KEY,
    qtde_faltas    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    fk_aluno       INT NOT NULL,
    fk_disciplina  INT NOT NULL,
    nota_final     DECIMAL(4,2) CHECK (nota_final BETWEEN 0 AND 10),
    FOREIGN KEY (fk_aluno, fk_disciplina)
        REFERENCES tb_matriculas(fk_aluno, fk_disciplina),
    CONSTRAINT uk_nota_aluno_disciplina UNIQUE (fk_aluno, fk_disciplina)
);

-- ============================================================
-- MÓDULO RH
-- ============================================================

CREATE TABLE tb_professores (
    pk_professor        INT AUTO_INCREMENT PRIMARY KEY,
    fk_pessoa           INT NOT NULL UNIQUE,
    registro_professor  CHAR(10) NOT NULL UNIQUE,
    formacao            VARCHAR(100),
    data_contratacao    DATE NOT NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_pessoa) REFERENCES tb_pessoas(pk_pessoa)
);

-- N:N entre Professor e Disciplina com CHAVE COMPOSTA
CREATE TABLE tb_vinculos_professor_disciplina (
    fk_professor   INT NOT NULL,
    fk_disciplina  INT NOT NULL,
    data_vinculo   DATE NOT NULL,
    carga_horaria  TINYINT UNSIGNED NOT NULL,
    tipo_vinculo   ENUM('titular','auxiliar','convidado') DEFAULT 'titular',
    CONSTRAINT pk_vinculo PRIMARY KEY (fk_professor, fk_disciplina),
    FOREIGN KEY (fk_professor)  REFERENCES tb_professores(pk_professor),
    FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

-- ============================================================
-- MÓDULO FINANCEIRO
-- ============================================================

CREATE TABLE tb_contratos_educacionais (
    pk_contrato        INT AUTO_INCREMENT PRIMARY KEY,
    fk_aluno           INT NOT NULL,
    data_inicio        DATE NOT NULL,
    data_fim           DATE,
    valor_mensalidade  DECIMAL(10,2) NOT NULL,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_aluno) REFERENCES tb_alunos(pk_aluno)
);

CREATE TABLE tb_mensalidades (
    pk_mensalidade   INT AUTO_INCREMENT PRIMARY KEY,
    fk_contrato      INT NOT NULL,
    competencia      DATE NOT NULL,
    data_vencimento  DATE NOT NULL,
    valor            DECIMAL(10,2) NOT NULL,
    status_pagamento ENUM('pendente','pago','atrasado') DEFAULT 'pendente',
    FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
    CONSTRAINT uq_mensalidade UNIQUE (fk_contrato, competencia)
);

CREATE TABLE tb_pagamentos (
    pk_pagamento      INT AUTO_INCREMENT PRIMARY KEY,
    fk_mensalidade    INT NOT NULL,
    data_pagamento    DATE NOT NULL,
    valor_pago        DECIMAL(10,2) NOT NULL,
    forma_pagamento   ENUM('dinheiro','cartao','boleto','pix') DEFAULT 'boleto',
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_mensalidade) REFERENCES tb_mensalidades(pk_mensalidade),
    CONSTRAINT uq_pagamentos UNIQUE (fk_mensalidade, data_pagamento)
);

-- ============================================================
-- TRIGGERS – REGRAS DE NEGÓCIO
-- ============================================================

DELIMITER $$

-- Impede dois contratos ativos para o mesmo aluno
CREATE TRIGGER tr_contratos_unico_ativo
BEFORE INSERT ON tb_contratos_educacionais
FOR EACH ROW
BEGIN
    DECLARE contrato_ativo INT;
    SELECT COUNT(*) INTO contrato_ativo
    FROM tb_contratos_educacionais
    WHERE fk_aluno = NEW.fk_aluno AND data_fim IS NULL;
    IF contrato_ativo > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Aluno ja possui um contrato ativo. Finalize o contrato atual antes de criar um novo.';
    END IF;
END$$

-- Impede matrícula de aluno inadimplente
CREATE TRIGGER tr_verificar_inadimplencia_antes_matricula
BEFORE INSERT ON tb_matriculas
FOR EACH ROW
BEGIN
    DECLARE inadimplente INT;
    SELECT COUNT(*) INTO inadimplente
    FROM tb_mensalidades m
    INNER JOIN tb_contratos_educacionais c ON m.fk_contrato = c.pk_contrato
    WHERE c.fk_aluno = NEW.fk_aluno AND m.status_pagamento = 'atrasado';
    IF inadimplente > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Aluno inadimplente. Regularize os pagamentos antes da matricula.';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- VALIDAÇÃO FASE 1 – estrutura criada (todos zerados)
-- ============================================================
SELECT 'tb_pessoas'                          AS tabela, COUNT(*) AS total FROM tb_pessoas
UNION ALL SELECT 'tb_cursos',                COUNT(*) FROM tb_cursos
UNION ALL SELECT 'tb_disciplinas',           COUNT(*) FROM tb_disciplinas
UNION ALL SELECT 'tb_alunos',                COUNT(*) FROM tb_alunos
UNION ALL SELECT 'tb_matriculas',            COUNT(*) FROM tb_matriculas
UNION ALL SELECT 'tb_notas',                 COUNT(*) FROM tb_notas
UNION ALL SELECT 'tb_professores',           COUNT(*) FROM tb_professores
UNION ALL SELECT 'tb_vinculos_professor_disciplina', COUNT(*) FROM tb_vinculos_professor_disciplina
UNION ALL SELECT 'tb_contratos_educacionais',COUNT(*) FROM tb_contratos_educacionais
UNION ALL SELECT 'tb_mensalidades',          COUNT(*) FROM tb_mensalidades
UNION ALL SELECT 'tb_pagamentos',            COUNT(*) FROM tb_pagamentos;


-- ============================================================
-- FASE 2 – CARGA DE DADOS (IDEMPOTENTE)
-- Estratégia: INSERT IGNORE + UNIQUE constraints
-- Reexecutar o script NÃO gera duplicidade
-- ============================================================

-- 1. Pessoas
INSERT IGNORE INTO tb_pessoas (nome_pessoa, data_nascimento, cpf, email, telefone, endereco) VALUES
('Ana Clara Souza',      '2002-05-14', '11122233344', 'ana.clara@email.com',      '11999990001', 'Rua A, 123 - SP'),
('Carlos Roberto Lima',  '1985-03-20', '22233344455', 'carlos.roberto@email.com', '11988880002', 'Rua B, 456 - SP'),
('Fernanda Lima Santos', '1990-07-15', '33344455566', 'fernanda.lima@email.com',  '11977770003', 'Rua C, 789 - SP'),
('Pedro Henrique Gomes', '1999-10-20', '44455566677', 'pedro.gomes@email.com',    '11966660004', 'Rua D, 101 - SP'),
('Joao Silva',           '1980-01-10', '55566677788', 'joao.silva@email.com',     '11955550005', 'Rua E, 202 - SP');

-- 2. Alunos
INSERT IGNORE INTO tb_alunos (fk_pessoa, ra, status_aluno, data_ingresso) VALUES
(1, 'RA2024001', 'ativo', '2024-02-01'),
(4, 'RA2024002', 'ativo', '2024-02-01'),
(5, 'RA2024003', 'ativo', '2024-02-01');

-- 3. Professores
INSERT IGNORE INTO tb_professores (fk_pessoa, registro_professor, formacao, data_contratacao) VALUES
(2, 'PROF001', 'Mestrado em Banco de Dados',  '2020-01-15'),
(3, 'PROF002', 'Doutorado em Computacao',     '2019-03-10'),
(5, 'PROF003', 'Especializacao em Gestao',    '2023-01-20');

-- 4. Cursos
INSERT IGNORE INTO tb_cursos (nome_curso, duracao_semestres) VALUES
('Analise e Desenvolvimento de Sistemas', 5),
('Administracao', 8);

-- 5. Disciplinas
INSERT IGNORE INTO tb_disciplinas (nome_disciplina, carga_horaria, fk_curso) VALUES
('Banco de Dados I',       80, 1),
('Algoritmos e Logica',    80, 1),
('Gestao Financeira',      60, 2),
('Engenharia de Software', 80, 1);

-- 6. Matrículas
INSERT IGNORE INTO tb_matriculas (fk_aluno, fk_disciplina, data_matricula) VALUES
(1, 1, '2026-02-01'),
(1, 2, '2026-02-01'),
(2, 1, '2026-02-02');

-- 7. Notas
INSERT IGNORE INTO tb_notas (qtde_faltas, fk_aluno, fk_disciplina, nota_final) VALUES
(2,  1, 1, 9.50),
(10, 2, 1, 4.00),
(0,  1, 2, 8.00);

-- 8. Vínculos Professor-Disciplina
INSERT IGNORE INTO tb_vinculos_professor_disciplina (fk_professor, fk_disciplina, data_vinculo, carga_horaria, tipo_vinculo) VALUES
(1, 1, '2026-01-10', 40, 'titular'),
(1, 2, '2026-01-10', 40, 'titular'),
(2, 4, '2026-01-10', 40, 'titular'),
(3, 3, '2026-01-10', 20, 'auxiliar');

-- 9. Contratos
INSERT IGNORE INTO tb_contratos_educacionais (fk_aluno, data_inicio, data_fim, valor_mensalidade) VALUES
(1, '2026-01-15', '2026-12-15', 850.00),
(2, '2026-01-15', NULL,         850.00);

-- 10. Mensalidades
INSERT IGNORE INTO tb_mensalidades (fk_contrato, competencia, data_vencimento, valor, status_pagamento) VALUES
(1, '2026-02-01', '2026-02-10', 850.00, 'pago'),
(1, '2026-03-01', '2026-03-10', 850.00, 'pendente'),
(2, '2026-02-01', '2026-02-10', 850.00, 'atrasado');

-- 11. Pagamentos
INSERT IGNORE INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento) VALUES
(1, '2026-02-09', 850.00, 'pix'),
(3, '2026-02-08', 850.00, 'boleto');

-- VALIDAÇÃO FASE 2 – contagem após carga
SELECT 'tb_pessoas'                          AS tabela, COUNT(*) AS total FROM tb_pessoas
UNION ALL SELECT 'tb_cursos',                COUNT(*) FROM tb_cursos
UNION ALL SELECT 'tb_disciplinas',           COUNT(*) FROM tb_disciplinas
UNION ALL SELECT 'tb_alunos',                COUNT(*) FROM tb_alunos
UNION ALL SELECT 'tb_matriculas',            COUNT(*) FROM tb_matriculas
UNION ALL SELECT 'tb_notas',                 COUNT(*) FROM tb_notas
UNION ALL SELECT 'tb_professores',           COUNT(*) FROM tb_professores
UNION ALL SELECT 'tb_vinculos_professor_disciplina', COUNT(*) FROM tb_vinculos_professor_disciplina
UNION ALL SELECT 'tb_contratos_educacionais',COUNT(*) FROM tb_contratos_educacionais
UNION ALL SELECT 'tb_mensalidades',          COUNT(*) FROM tb_mensalidades
UNION ALL SELECT 'tb_pagamentos',            COUNT(*) FROM tb_pagamentos;


-- ============================================================
-- FASE 3 – OPERAÇÕES OLTP
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 SELECTS SIMPLES
-- ------------------------------------------------------------

-- Listagem de alunos
SELECT a.ra AS 'RA', p.nome_pessoa AS 'Aluno', a.status_aluno AS 'Status'
FROM tb_alunos a
JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa;

-- Listagem de professores
SELECT prof.registro_professor AS 'Registro', p.nome_pessoa AS 'Professor', prof.formacao AS 'Formacao'
FROM tb_professores prof
JOIN tb_pessoas p ON prof.fk_pessoa = p.pk_pessoa;

-- Listagem financeira consolidada
SELECT p.nome_pessoa AS 'Aluno', m.competencia AS 'Competencia',
       m.valor AS 'Valor (R$)', m.status_pagamento AS 'Situacao'
FROM tb_mensalidades m
JOIN tb_contratos_educacionais ce ON m.fk_contrato = ce.pk_contrato
JOIN tb_alunos a  ON ce.fk_aluno  = a.pk_aluno
JOIN tb_pessoas p ON a.fk_pessoa  = p.pk_pessoa;

-- Boletim completo de notas
SELECT p.nome_pessoa AS 'Aluno', d.nome_disciplina AS 'Disciplina',
       n.nota_final AS 'Nota', n.qtde_faltas AS 'Faltas',
       CASE WHEN n.nota_final >= 6.0 AND n.qtde_faltas <= 15
            THEN 'Aprovado' ELSE 'Reprovado' END AS 'Situacao'
FROM tb_notas n
JOIN tb_alunos a      ON n.fk_aluno      = a.pk_aluno
JOIN tb_pessoas p     ON a.fk_pessoa     = p.pk_pessoa
JOIN tb_disciplinas d ON n.fk_disciplina = d.pk_disciplina
ORDER BY p.nome_pessoa, d.nome_disciplina;

-- Inadimplência
SELECT p.nome_pessoa AS 'Aluno', m.competencia AS 'Competencia',
       m.data_vencimento AS 'Vencimento', m.valor AS 'Valor (R$)',
       m.status_pagamento AS 'Status'
FROM tb_mensalidades m
JOIN tb_contratos_educacionais c ON m.fk_contrato = c.pk_contrato
JOIN tb_alunos a  ON c.fk_aluno  = a.pk_aluno
JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
WHERE m.status_pagamento != 'pago';

-- Aluno que também é professor (papel duplo)
SELECT p.nome_pessoa AS 'Nome', p.cpf AS 'CPF',
       a.ra AS 'RA', a.status_aluno AS 'Status Aluno',
       prof.registro_professor AS 'Registro Prof', prof.formacao AS 'Formacao'
FROM tb_pessoas p
JOIN tb_alunos      a    ON p.pk_pessoa = a.fk_pessoa
JOIN tb_professores prof ON p.pk_pessoa = prof.fk_pessoa;

-- Alocação de professores por disciplina
SELECT p.nome_pessoa AS 'Professor', d.nome_disciplina AS 'Disciplina',
       v.carga_horaria AS 'Carga (h)', v.tipo_vinculo AS 'Tipo'
FROM tb_vinculos_professor_disciplina v
JOIN tb_professores prof ON v.fk_professor  = prof.pk_professor
JOIN tb_pessoas p        ON prof.fk_pessoa  = p.pk_pessoa
JOIN tb_disciplinas d    ON v.fk_disciplina = d.pk_disciplina
ORDER BY p.nome_pessoa;

-- ------------------------------------------------------------
-- 3.2 SUBSELECTS COM AGREGAÇÃO
-- ------------------------------------------------------------

-- Alunos com total pago acima de R$ 800,00
SELECT nome_pessoa AS 'Aluno com total pago > R$800'
FROM tb_pessoas
WHERE pk_pessoa IN (
    SELECT a.fk_pessoa
    FROM tb_alunos a
    JOIN tb_contratos_educacionais c ON a.pk_aluno    = c.fk_aluno
    JOIN tb_mensalidades m           ON c.pk_contrato = m.fk_contrato
    JOIN tb_pagamentos pg            ON m.pk_mensalidade = pg.fk_mensalidade
    GROUP BY a.fk_pessoa
    HAVING SUM(pg.valor_pago) > 800
);

-- Disciplinas com média de notas acima de 5.0
SELECT nome_disciplina AS 'Disciplina com media > 5.0'
FROM tb_disciplinas
WHERE pk_disciplina IN (
    SELECT fk_disciplina
    FROM tb_notas
    GROUP BY fk_disciplina
    HAVING AVG(nota_final) > 5.0
);

-- Alunos com mais faltas que a média geral
SELECT p.nome_pessoa AS 'Aluno acima da media de faltas', n.qtde_faltas AS 'Faltas'
FROM tb_notas n
JOIN tb_alunos a  ON n.fk_aluno  = a.pk_aluno
JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
WHERE n.qtde_faltas > (
    SELECT AVG(qtde_faltas) FROM tb_notas
);

-- ------------------------------------------------------------
-- 3.3 CONTROLE TRANSACIONAL
-- ------------------------------------------------------------

-- CENÁRIO 1: ROLLBACK com violação de CHECK (ERRO AUTOMÁTICO)
-- A constraint CHECK (nota_final BETWEEN 0 AND 10) vai falhar sozinha
START TRANSACTION;
    INSERT INTO tb_notas (qtde_faltas, fk_aluno, fk_disciplina, nota_final)
    VALUES (0, 1, 1, 15.00);  -- Nota 15 viola CHECK (deve ser 0-10)
    -- O MySQL vai rejeitar automaticamente, ROLLBACK implícito
COMMIT;
-- Validação: o registro NÃO deve existir
SELECT * FROM tb_notas WHERE nota_final = 15.00;

-- CENÁRIO 2: ROLLBACK manual – valor inválido
START TRANSACTION;
    INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento)
    VALUES (2, '2026-05-15', -1000.00, 'pix');
ROLLBACK;
-- Validação: deve retornar 0 linhas
SELECT * FROM tb_pagamentos WHERE valor_pago = -1000.00;

-- CENÁRIO 3: ROLLBACK – múltiplas tabelas (atomicidade)
SET autocommit = 0;
START TRANSACTION;
    INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento)
    VALUES (2, '2026-05-18', 850.00, 'pix');
    UPDATE tb_mensalidades SET status_pagamento = 'pago' WHERE pk_mensalidade = 2;
ROLLBACK;
-- Validação: INSERT não persistiu
SELECT * FROM tb_pagamentos WHERE data_pagamento = '2026-05-18';
-- Validação: UPDATE não persistiu (deve ser 'pendente')
SELECT status_pagamento FROM tb_mensalidades WHERE pk_mensalidade = 2;
SET autocommit = 1;

-- CENÁRIO 4: COMMIT – confirmação de fluxo real
START TRANSACTION;
    INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento)
    VALUES (2, '2026-05-20', 850.00, 'pix');
    UPDATE tb_mensalidades SET status_pagamento = 'pago' WHERE pk_mensalidade = 2;
COMMIT;
-- Validação: deve retornar 1 linha
SELECT * FROM tb_pagamentos WHERE data_pagamento = '2026-05-20';
-- Validação: deve ser 'pago'
SELECT status_pagamento FROM tb_mensalidades WHERE pk_mensalidade = 2;


-- ============================================================
-- FASE 4 – CONVERSÃO OLTP → OLAP (STAR SCHEMA)
-- ============================================================

-- GRANULARIDADE DEFINIDA: 1 linha = 1 mensalidade por aluno
-- Cada registro na tabela fato representa UMA mensalidade de UM aluno

-- ------------------------------------------------------------
-- 4.1 DIMENSÕES
-- ------------------------------------------------------------

-- Dimensão Aluno (NK = pk_aluno do OLTP)
CREATE TABLE dim_aluno (
    sk_aluno         INT AUTO_INCREMENT PRIMARY KEY,
    nk_aluno         INT NOT NULL,
    nome_aluno       VARCHAR(100) NOT NULL,
    ra               CHAR(10) NOT NULL,
    cpf              CHAR(11) NOT NULL,
    data_nascimento  DATE NOT NULL,
    data_ingresso    DATE NOT NULL,
    faixa_etaria     VARCHAR(30) NOT NULL,
    status_aluno     VARCHAR(40) NOT NULL
);

-- Dimensão Curso (NK = pk_curso do OLTP)
CREATE TABLE dim_curso (
    sk_curso           INT AUTO_INCREMENT PRIMARY KEY,
    nk_curso           INT NOT NULL,
    nome_curso         VARCHAR(100) NOT NULL,
    duracao_semestres  TINYINT NOT NULL
);

-- Dimensão Tempo (gerada pelo ETL – não existe no OLTP)
CREATE TABLE dim_tempo (
    sk_tempo      INT NOT NULL PRIMARY KEY,
    data_completa DATE NOT NULL,
    ano           INT NOT NULL,
    semestre      INT NOT NULL,
    trimestre     INT NOT NULL,
    mes           INT NOT NULL,
    nome_mes      VARCHAR(30) NOT NULL,
    dia_semana    VARCHAR(40) NOT NULL
);

-- ------------------------------------------------------------
-- 4.2 TABELA FATO
-- ------------------------------------------------------------

CREATE TABLE fato_financeiro (
    sk_financeiro        INT AUTO_INCREMENT PRIMARY KEY,
    sk_aluno             INT NOT NULL,
    sk_curso             INT NOT NULL,
    sk_tempo_vencimento  INT NOT NULL,
    sk_tempo_pagamento   INT NULL,
    nk_mensalidade       INT NOT NULL,
    valor_previsto       DECIMAL(10,2) NOT NULL,
    valor_pago           DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (sk_aluno)            REFERENCES dim_aluno(sk_aluno),
    FOREIGN KEY (sk_curso)            REFERENCES dim_curso(sk_curso),
    FOREIGN KEY (sk_tempo_vencimento) REFERENCES dim_tempo(sk_tempo),
    FOREIGN KEY (sk_tempo_pagamento)  REFERENCES dim_tempo(sk_tempo)
);

-- ------------------------------------------------------------
-- 4.3 ETL – EXTRAÇÃO, TRANSFORMAÇÃO E CARGA (CORRIGIDO)
-- ------------------------------------------------------------

-- ETL: dim_aluno (com atributo derivado: faixa_etaria)
INSERT INTO dim_aluno (nk_aluno, nome_aluno, ra, cpf, data_nascimento, data_ingresso, faixa_etaria, status_aluno)
SELECT
    a.pk_aluno,
    p.nome_pessoa,
    a.ra,
    p.cpf,
    p.data_nascimento,
    a.data_ingresso,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.data_nascimento, CURDATE()) < 20 THEN 'Menos de 20 anos'
        WHEN TIMESTAMPDIFF(YEAR, p.data_nascimento, CURDATE()) < 30 THEN '20 a 29 anos'
        WHEN TIMESTAMPDIFF(YEAR, p.data_nascimento, CURDATE()) < 40 THEN '30 a 39 anos'
        ELSE '40 anos ou mais'
    END AS faixa_etaria,
    a.status_aluno
FROM tb_alunos a
JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa;

-- ETL: dim_curso
INSERT INTO dim_curso (nk_curso, nome_curso, duracao_semestres)
SELECT pk_curso, nome_curso, duracao_semestres
FROM tb_cursos;

-- ETL: dim_tempo (gerada a partir de todas as datas do OLTP)
INSERT IGNORE INTO dim_tempo (sk_tempo, data_completa, ano, semestre, trimestre, mes, nome_mes, dia_semana)
SELECT DISTINCT
    DATE_FORMAT(d, '%Y%m%d') AS sk_tempo,
    d AS data_completa,
    YEAR(d) AS ano,
    IF(MONTH(d) <= 6, 1, 2) AS semestre,
    QUARTER(d) AS trimestre,
    MONTH(d) AS mes,
    ELT(MONTH(d),
        'Janeiro','Fevereiro','Marco','Abril','Maio','Junho',
        'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro') AS nome_mes,
    ELT(DAYOFWEEK(d),
        'Domingo','Segunda','Terca','Quarta','Quinta','Sexta','Sabado') AS dia_semana
FROM (
    SELECT data_vencimento AS d FROM tb_mensalidades
    UNION
    SELECT data_pagamento  AS d FROM tb_pagamentos
) AS todas_as_datas;

-- ETL: fato_financeiro (VERSÃO CORRIGIDA - SEM DUPLICAÇÃO)
-- Cada aluno tem UM curso principal (curso da PRIMEIRA matrícula)
INSERT INTO fato_financeiro (sk_aluno, sk_curso, sk_tempo_vencimento, sk_tempo_pagamento, nk_mensalidade, valor_previsto, valor_pago)
SELECT
    da.sk_aluno,
    COALESCE(dc.sk_curso, 1) AS sk_curso,  -- Curso padrão se não encontrar
    DATE_FORMAT(m.data_vencimento, '%Y%m%d') AS sk_tempo_vencimento,
    DATE_FORMAT(pg.data_pagamento, '%Y%m%d') AS sk_tempo_pagamento,
    m.pk_mensalidade AS nk_mensalidade,
    m.valor AS valor_previsto,
    COALESCE(pg.valor_pago, 0.00) AS valor_pago
FROM tb_mensalidades m
JOIN tb_contratos_educacionais ce ON m.fk_contrato = ce.pk_contrato
JOIN tb_alunos a ON ce.fk_aluno = a.pk_aluno
JOIN dim_aluno da ON da.nk_aluno = a.pk_aluno
-- CORREÇÃO: Pega o curso do aluno via primeira matrícula (evita duplicação)
LEFT JOIN (
    SELECT fk_aluno, MIN(fk_disciplina) as primeira_disciplina
    FROM tb_matriculas
    GROUP BY fk_aluno
) primeira_mat ON primeira_mat.fk_aluno = a.pk_aluno
LEFT JOIN tb_disciplinas dis ON dis.pk_disciplina = primeira_mat.primeira_disciplina
LEFT JOIN tb_cursos c ON c.pk_curso = dis.fk_curso
LEFT JOIN dim_curso dc ON dc.nk_curso = c.pk_curso
LEFT JOIN tb_pagamentos pg ON pg.fk_mensalidade = m.pk_mensalidade
GROUP BY m.pk_mensalidade, da.sk_aluno, dc.sk_curso,
         m.data_vencimento, pg.data_pagamento, m.valor, pg.valor_pago;

-- ------------------------------------------------------------
-- 4.4 VALIDAÇÃO ETL – OLTP vs OLAP (COMPLETA)
-- ------------------------------------------------------------

-- Validação 1: Comparação de SOMA TOTAL (deve ser igual)
SELECT 'VALIDAÇÃO 1 - SOMA TOTAL' AS validacao;
SELECT 'OLTP - Total pago' AS origem, SUM(valor_pago) AS total FROM tb_pagamentos
UNION ALL
SELECT 'OLAP - Total pago', SUM(valor_pago) FROM fato_financeiro;

SELECT 'OLTP - Total previsto' AS origem, SUM(valor) AS total FROM tb_mensalidades
UNION ALL
SELECT 'OLAP - Total previsto', SUM(valor_previsto) FROM fato_financeiro;

-- Validação 2: Comparação de QUANTIDADE de registros
SELECT 'VALIDAÇÃO 2 - QUANTIDADE DE REGISTROS' AS validacao;
SELECT 'OLTP - Quantidade mensalidades' AS origem, COUNT(*) AS total FROM tb_mensalidades
UNION ALL
SELECT 'OLAP - Quantidade registros fato', COUNT(*) FROM fato_financeiro;

-- Validação 3: Comparação por ALUNO (detalhada)
SELECT 'VALIDAÇÃO 3 - CONFERÊNCIA POR ALUNO' AS validacao;
SELECT 
    p.nome_pessoa AS 'Aluno',
    SUM(pg.valor_pago) AS 'OLTP - Pago',
    SUM(f.valor_pago) AS 'OLAP - Pago',
    CASE 
        WHEN SUM(pg.valor_pago) = SUM(f.valor_pago) THEN '✅ OK'
        ELSE '❌ ERRO'
    END AS 'Status'
FROM tb_pessoas p
JOIN tb_alunos a ON a.fk_pessoa = p.pk_pessoa
LEFT JOIN tb_contratos_educacionais ce ON ce.fk_aluno = a.pk_aluno
LEFT JOIN tb_mensalidades m ON m.fk_contrato = ce.pk_contrato
LEFT JOIN tb_pagamentos pg ON pg.fk_mensalidade = m.pk_mensalidade
LEFT JOIN fato_financeiro f ON f.nk_mensalidade = m.pk_mensalidade
GROUP BY p.pk_pessoa, p.nome_pessoa;

-- ------------------------------------------------------------
-- 4.5 CONSULTAS ANALÍTICAS OLAP
-- ------------------------------------------------------------

-- Faturamento por mês
SELECT dt.nome_mes AS 'Mes', dt.ano AS 'Ano',
       SUM(f.valor_pago) AS 'Faturamento (R$)'
FROM fato_financeiro f
JOIN dim_tempo dt ON f.sk_tempo_vencimento = dt.sk_tempo
GROUP BY dt.ano, dt.mes, dt.nome_mes
ORDER BY dt.ano, dt.mes;

-- Receita por aluno com análise de inadimplência
SELECT da.nome_aluno AS 'Aluno', da.faixa_etaria AS 'Faixa Etaria',
       SUM(f.valor_previsto)                          AS 'Previsto (R$)',
       SUM(f.valor_pago)                              AS 'Pago (R$)',
       SUM(f.valor_previsto) - SUM(f.valor_pago)      AS 'Inadimplencia (R$)'
FROM fato_financeiro f
JOIN dim_aluno da ON f.sk_aluno = da.sk_aluno
GROUP BY da.sk_aluno, da.nome_aluno, da.faixa_etaria;

-- Receita por curso e semestre
SELECT dc.nome_curso AS 'Curso', dt.ano AS 'Ano', dt.semestre AS 'Semestre',
       SUM(f.valor_pago) AS 'Receita (R$)'
FROM fato_financeiro f
JOIN dim_curso dc ON f.sk_curso             = dc.sk_curso
JOIN dim_tempo dt ON f.sk_tempo_vencimento  = dt.sk_tempo
GROUP BY dc.nome_curso, dt.ano, dt.semestre
ORDER BY dt.ano, dt.semestre, dc.nome_curso;


-- ============================================================
-- FASE 5 – DESEMPENHO E OTIMIZAÇÃO
-- ============================================================

-- Índices em FKs do OLTP
CREATE INDEX idx_alunos_fk_pessoa              ON tb_alunos(fk_pessoa);
CREATE INDEX idx_matriculas_fk_aluno           ON tb_matriculas(fk_aluno);
CREATE INDEX idx_matriculas_fk_disciplina      ON tb_matriculas(fk_disciplina);
CREATE INDEX idx_notas_fk_aluno                ON tb_notas(fk_aluno);
CREATE INDEX idx_notas_fk_disciplina           ON tb_notas(fk_disciplina);
CREATE INDEX idx_mensalidades_fk_contrato      ON tb_mensalidades(fk_contrato);
CREATE INDEX idx_pagamentos_fk_mensalidade     ON tb_pagamentos(fk_mensalidade);
CREATE INDEX idx_contratos_fk_aluno            ON tb_contratos_educacionais(fk_aluno);
CREATE INDEX idx_vinculos_fk_professor         ON tb_vinculos_professor_disciplina(fk_professor);
CREATE INDEX idx_vinculos_fk_disciplina        ON tb_vinculos_professor_disciplina(fk_disciplina);

-- Índices em colunas de filtro frequente
CREATE INDEX idx_mensalidades_status           ON tb_mensalidades(status_pagamento);
CREATE INDEX idx_pagamentos_data               ON tb_pagamentos(data_pagamento);
CREATE INDEX idx_alunos_status                 ON tb_alunos(status_aluno);

-- Índices no OLAP
CREATE INDEX idx_fato_sk_aluno                 ON fato_financeiro(sk_aluno);
CREATE INDEX idx_fato_sk_curso                 ON fato_financeiro(sk_curso);
CREATE INDEX idx_fato_sk_tempo_vencimento      ON fato_financeiro(sk_tempo_vencimento);
CREATE INDEX idx_fato_nk_mensalidade           ON fato_financeiro(nk_mensalidade);
CREATE INDEX idx_dim_tempo_mes                 ON dim_tempo(mes, ano);
CREATE INDEX idx_dim_tempo_data                ON dim_tempo(data_completa);

-- Validação com EXPLAIN (mostra que os índices estão sendo usados)
EXPLAIN SELECT dt.nome_mes, SUM(f.valor_pago) AS faturamento
FROM fato_financeiro f
JOIN dim_tempo dt ON f.sk_tempo_vencimento = dt.sk_tempo
GROUP BY dt.nome_mes
ORDER BY faturamento DESC;

EXPLAIN SELECT p.nome_pessoa, SUM(pg.valor_pago) AS total_pago
FROM tb_pagamentos pg
JOIN tb_mensalidades m            ON pg.fk_mensalidade = m.pk_mensalidade
JOIN tb_contratos_educacionais ce ON m.fk_contrato     = ce.pk_contrato
JOIN tb_alunos a                  ON ce.fk_aluno        = a.pk_aluno
JOIN tb_pessoas p                 ON a.fk_pessoa        = p.pk_pessoa
GROUP BY p.nome_pessoa;


-- ============================================================
-- FASE 6 – GOVERNANÇA
-- ============================================================

-- Padrões adotados:
-- - snake_case para tabelas e colunas
-- - Prefixos: tb_ (OLTP), dim_ (dimensão), fato_ (fato)
-- - PK: pk_<tabela>, FK: fk_<tabela_origem>
-- - Scripts comentados e organizados por módulos

-- Script de reset (salvar como reset.sql)
/*
USE sisgesc;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE fato_financeiro;
TRUNCATE TABLE dim_aluno;
TRUNCATE TABLE dim_curso;
TRUNCATE TABLE dim_tempo;
TRUNCATE TABLE tb_pagamentos;
TRUNCATE TABLE tb_mensalidades;
TRUNCATE TABLE tb_contratos_educacionais;
TRUNCATE TABLE tb_notas;
TRUNCATE TABLE tb_matriculas;
TRUNCATE TABLE tb_vinculos_professor_disciplina;
TRUNCATE TABLE tb_professores;
TRUNCATE TABLE tb_alunos;
TRUNCATE TABLE tb_disciplinas;
TRUNCATE TABLE tb_cursos;
TRUNCATE TABLE tb_pessoas;
SET FOREIGN_KEY_CHECKS = 1;
*/

-- Contagem final de todas as tabelas (OLTP + OLAP)
SELECT 'CONTAGEM FINAL - TODAS AS TABELAS' AS validacao;
SELECT 'tb_pessoas'                          AS tabela, COUNT(*) AS total FROM tb_pessoas
UNION ALL SELECT 'tb_cursos',                COUNT(*) FROM tb_cursos
UNION ALL SELECT 'tb_disciplinas',           COUNT(*) FROM tb_disciplinas
UNION ALL SELECT 'tb_alunos',                COUNT(*) FROM tb_alunos
UNION ALL SELECT 'tb_matriculas',            COUNT(*) FROM tb_matriculas
UNION ALL SELECT 'tb_notas',                 COUNT(*) FROM tb_notas
UNION ALL SELECT 'tb_professores',           COUNT(*) FROM tb_professores
UNION ALL SELECT 'tb_vinculos_professor_disciplina', COUNT(*) FROM tb_vinculos_professor_disciplina
UNION ALL SELECT 'tb_contratos_educacionais',COUNT(*) FROM tb_contratos_educacionais
UNION ALL SELECT 'tb_mensalidades',          COUNT(*) FROM tb_mensalidades
UNION ALL SELECT 'tb_pagamentos',            COUNT(*) FROM tb_pagamentos
UNION ALL SELECT 'dim_aluno',                COUNT(*) FROM dim_aluno
UNION ALL SELECT 'dim_curso',                COUNT(*) FROM dim_curso
UNION ALL SELECT 'dim_tempo',                COUNT(*) FROM dim_tempo
UNION ALL SELECT 'fato_financeiro',          COUNT(*) FROM fato_financeiro;
