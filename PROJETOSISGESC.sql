-- ============================================
-- CONTINUAR DAQUI (depois do erro do CHECK)
-- ============================================

-- Verificar que o registro NÃO foi inserido (deve retornar 0 linhas)
SELECT * FROM tb_notas WHERE nota_final = 15.00;

-- CENÁRIO 2: ROLLBACK manual
START TRANSACTION;
    INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento)
    VALUES (2, '2026-05-15', -1000.00, 'pix');
ROLLBACK;

SELECT * FROM tb_pagamentos WHERE valor_pago = -1000.00;

-- CENÁRIO 3: ROLLBACK múltiplas tabelas
SET autocommit = 0;
START TRANSACTION;
    INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento)
    VALUES (2, '2026-05-18', 850.00, 'pix');
    UPDATE tb_mensalidades SET status_pagamento = 'pago' WHERE pk_mensalidade = 2;
ROLLBACK;

SELECT * FROM tb_pagamentos WHERE data_pagamento = '2026-05-18';
SELECT status_pagamento FROM tb_mensalidades WHERE pk_mensalidade = 2;
SET autocommit = 1;

-- CENÁRIO 4: COMMIT
START TRANSACTION;
    INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento)
    VALUES (2, '2026-05-20', 850.00, 'pix');
    UPDATE tb_mensalidades SET status_pagamento = 'pago' WHERE pk_mensalidade = 2;
COMMIT;

SELECT * FROM tb_pagamentos WHERE data_pagamento = '2026-05-20';
SELECT status_pagamento FROM tb_mensalidades WHERE pk_mensalidade = 2;

-- ============================================
-- FASE 4: OLAP (Star Schema)
-- ============================================

-- Dimensão Aluno
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

-- Dimensão Curso
CREATE TABLE dim_curso (
    sk_curso           INT AUTO_INCREMENT PRIMARY KEY,
    nk_curso           INT NOT NULL,
    nome_curso         VARCHAR(100) NOT NULL,
    duracao_semestres  TINYINT NOT NULL
);

-- Dimensão Tempo
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

-- Tabela Fato
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

-- ETL: dim_aluno
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

-- ETL: dim_tempo
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
    SELECT data_pagamento AS d FROM tb_pagamentos
) AS todas_as_datas;

-- ETL: fato_financeiro (CORRIGIDO)
INSERT INTO fato_financeiro (sk_aluno, sk_curso, sk_tempo_vencimento, sk_tempo_pagamento, nk_mensalidade, valor_previsto, valor_pago)
SELECT
    da.sk_aluno,
    COALESCE(dc.sk_curso, 1) AS sk_curso,
    DATE_FORMAT(m.data_vencimento, '%Y%m%d') AS sk_tempo_vencimento,
    DATE_FORMAT(pg.data_pagamento, '%Y%m%d') AS sk_tempo_pagamento,
    m.pk_mensalidade AS nk_mensalidade,
    m.valor AS valor_previsto,
    COALESCE(pg.valor_pago, 0.00) AS valor_pago
FROM tb_mensalidades m
JOIN tb_contratos_educacionais ce ON m.fk_contrato = ce.pk_contrato
JOIN tb_alunos a ON ce.fk_aluno = a.pk_aluno
JOIN dim_aluno da ON da.nk_aluno = a.pk_aluno
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

-- VALIDAÇÕES ETL
SELECT 'OLTP - Total pago' AS origem, SUM(valor_pago) AS total FROM tb_pagamentos
UNION ALL
SELECT 'OLAP - Total pago', SUM(valor_pago) FROM fato_financeiro;

-- ============================================
-- FASE 5: ÍNDICES
-- ============================================

CREATE INDEX idx_alunos_fk_pessoa ON tb_alunos(fk_pessoa);
CREATE INDEX idx_mensalidades_fk_contrato ON tb_mensalidades(fk_contrato);
CREATE INDEX idx_pagamentos_fk_mensalidade ON tb_pagamentos(fk_mensalidade);
CREATE INDEX idx_fato_sk_aluno ON fato_financeiro(sk_aluno);
CREATE INDEX idx_fato_sk_curso ON fato_financeiro(sk_curso);
CREATE INDEX idx_fato_sk_tempo_vencimento ON fato_financeiro(sk_tempo_vencimento);

-- ============================================
-- FASE 6: CONTAGEM FINAL
-- ============================================

SELECT 'CONTAGEM FINAL' AS validacao;
SELECT 'dim_aluno' AS tabela, COUNT(*) AS total FROM dim_aluno
UNION ALL SELECT 'dim_curso', COUNT(*) FROM dim_curso
UNION ALL SELECT 'dim_tempo', COUNT(*) FROM dim_tempo
UNION ALL SELECT 'fato_financeiro', COUNT(*) FROM fato_financeiro;