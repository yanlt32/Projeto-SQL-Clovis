-- criação do banco de dados
drop database if exists sisgesc;
create database sisgesc character set utf8mb4 collate utf8mb4_unicode_ci;
use sisgesc;

-- =============================================
-- TABELA ÚNICA DE PESSOAS (BASE)
-- =============================================
create table tb_pessoas(
    pk_pessoa int auto_increment primary key,
    nome_pessoa varchar(100) not null,
    data_nascimento date not null,
    cpf char(11) not null unique,
    email varchar(100) not null unique,
    telefone varchar(15),
    endereco varchar(200),
    created_at timestamp default current_timestamp
);

-- =============================================
-- TABELAS BASE
-- =============================================
create table tb_cursos(
    pk_curso int auto_increment primary key,
    nome_curso varchar(100) not null,
    duracao_semestres tinyint not null,
    created_at timestamp default current_timestamp
);

create table tb_disciplinas(
    pk_disciplina int auto_increment primary key,
    nome_disciplina varchar(60) not null,
    carga_horaria tinyint not null,
    fk_curso int not null,
    foreign key(fk_curso) references tb_cursos(pk_curso)
);

-- =============================================
-- TABELAS DE PAPÉIS (ALUNO E PROFESSOR)
-- =============================================
create table tb_alunos(
    pk_aluno int auto_increment primary key,
    fk_pessoa int not null unique,
    ra char(10) not null unique,
    status_aluno enum('ativo', 'inativo', 'trancado') default 'ativo',
    data_ingresso date not null,
    created_at timestamp default current_timestamp,
    
    foreign key(fk_pessoa) references tb_pessoas(pk_pessoa)
);

create table tb_professores(
    pk_professor int auto_increment primary key,
    fk_pessoa int not null unique,
    registro_professor char(10) not null unique,
    formacao varchar(100),
    data_contratacao date not null,
    created_at timestamp default current_timestamp,
    
    foreign key(fk_pessoa) references tb_pessoas(pk_pessoa)
);

-- =============================================
-- TABELA COM CHAVE COMPOSTA (N:N entre Aluno e Disciplina)
-- =============================================
create table tb_matriculas(
    fk_aluno int not null,
    fk_disciplina int not null,
    data_matricula date not null,
    status_matricula enum('ativa', 'cancelada', 'concluida') default 'ativa',
    created_at timestamp default current_timestamp,
    
    -- CHAVE COMPOSTA
    constraint pk_matricula primary key (fk_aluno, fk_disciplina),
    
    foreign key(fk_aluno) references tb_alunos(pk_aluno),
    foreign key(fk_disciplina) references tb_disciplinas(pk_disciplina)
);

-- =============================================
-- TABELA DE NOTAS (COM FK COMPOSTA)
-- =============================================
create table tb_notas(
    pk_nota int auto_increment primary key,
    qtde_faltas tinyint unsigned not null default 0,
    fk_aluno int not null,
    fk_disciplina int not null,
    nota_final decimal(4,2) check(nota_final between 0 and 10),
    
    -- CHAVE ESTRANGEIRA COMPOSTA
    foreign key(fk_aluno, fk_disciplina) 
        references tb_matriculas(fk_aluno, fk_disciplina)
);

-- =============================================
-- TABELA COM RELACIONAMENTO N:N (Professor e Disciplina) - CHAVE COMPOSTA
-- =============================================
create table tb_vinculos_professor_disciplina(
    fk_professor int not null,
    fk_disciplina int not null,
    data_vinculo date not null,
    carga_horaria tinyint unsigned not null,
    tipo_vinculo enum('titular', 'auxiliar', 'convidado') default 'titular',
    
    -- CHAVE COMPOSTA (resolve o N:N)
    constraint pk_vinculo primary key (fk_professor, fk_disciplina),
    
    foreign key(fk_professor) references tb_professores(pk_professor),
    foreign key(fk_disciplina) references tb_disciplinas(pk_disciplina)
);

-- =============================================
-- MÓDULO FINANCEIRO
-- =============================================
create table tb_contratos_educacionais(
    pk_contrato int auto_increment primary key,
    fk_aluno int not null,
    data_inicio date not null,
    data_fim date,
    valor_mensalidade decimal(10,2) not null,
    created_at timestamp default current_timestamp,
    
    foreign key(fk_aluno) references tb_alunos(pk_aluno)
);

create table tb_mensalidades(
    pk_mensalidade int auto_increment primary key,
    fk_contrato int not null,
    competencia date not null,
    data_vencimento date not null,
    valor decimal(10,2) not null,
    status_pagamento enum('pendente', 'pago', 'atrasado') default 'pendente',
    
    foreign key(fk_contrato) references tb_contratos_educacionais(pk_contrato),
    constraint uq_mensalidade unique(fk_contrato, competencia)
);

create table tb_pagamentos(
    pk_pagamento int auto_increment primary key,
    fk_mensalidade int not null,
    data_pagamento date not null,
    valor_pago decimal(10,2) not null,
    forma_pagamento enum('dinheiro', 'cartao', 'boleto', 'pix') default 'boleto',
    created_at timestamp default current_timestamp,
    
    foreign key(fk_mensalidade) references tb_mensalidades(pk_mensalidade)
);

-- =============================================
-- TESTES INSERT
-- =============================================

-- 1. Inserir PESSOAS (base única)
INSERT INTO tb_pessoas (nome_pessoa, data_nascimento, cpf, email, telefone, endereco) VALUES 
('Ana Clara Souza', '2002-05-14', '11122233344', 'ana.clara@email.com', '11999990001', 'Rua A, 123 - SP'),
('Carlos Roberto Lima', '1985-03-20', '22233344455', 'carlos.roberto@email.com', '11988880002', 'Rua B, 456 - SP'),
('Fernanda Lima Santos', '1990-07-15', '33344455566', 'fernanda.lima@email.com', '11977770003', 'Rua C, 789 - SP'),
('Pedro Henrique Gomes', '1999-10-20', '44455566677', 'pedro.gomes@email.com', '11966660004', 'Rua D, 101 - SP'),
('João Silva', '1980-01-10', '55566677788', 'joao.silva@email.com', '11955550005', 'Rua E, 202 - SP');

-- 2. Definir quem é ALUNO
INSERT INTO tb_alunos (fk_pessoa, ra, status_aluno, data_ingresso) VALUES 
(1, 'RA2024001', 'ativo', '2024-02-01'),
(4, 'RA2024002', 'ativo', '2024-02-01');

-- 3. Definir quem é PROFESSOR
INSERT INTO tb_professores (fk_pessoa, registro_professor, formacao, data_contratacao) VALUES 
(2, 'PROF001', 'Mestrado em Banco de Dados', '2020-01-15'),
(3, 'PROF002', 'Doutorado em Computação', '2019-03-10');

-- 4. PESSOA que é ALUNO E PROFESSOR ao mesmo tempo (João Silva)
INSERT INTO tb_alunos (fk_pessoa, ra, status_aluno, data_ingresso) VALUES 
(5, 'RA2024003', 'ativo', '2024-02-01');

INSERT INTO tb_professores (fk_pessoa, registro_professor, formacao, data_contratacao) VALUES 
(5, 'PROF003', 'Especialização em Gestão', '2023-01-20');

-- 5. Cursos
INSERT INTO tb_cursos (nome_curso, duracao_semestres) VALUES 
('Análise e Desenvolvimento de Sistemas', 5),
('Administração', 8);

-- 6. Disciplinas
INSERT INTO tb_disciplinas (nome_disciplina, carga_horaria, fk_curso) VALUES 
('Banco de Dados I', 80, 1),
('Algoritmos e Lógica', 80, 1),
('Gestão Financeira', 60, 2),
('Engenharia de Software', 80, 1);

-- 7. Matrículas (CHAVE COMPOSTA)
INSERT INTO tb_matriculas (fk_aluno, fk_disciplina, data_matricula) VALUES 
(1, 1, '2026-02-01'),
(1, 2, '2026-02-01'),
(2, 1, '2026-02-02');

-- 8. Notas (com FK COMPOSTA)
INSERT INTO tb_notas (qtde_faltas, fk_aluno, fk_disciplina, nota_final) VALUES 
(2, 1, 1, 9.50),
(10, 2, 1, 4.00),
(0, 1, 2, 8.00);

-- 9. Vínculos Professor-Disciplina (N:N com CHAVE COMPOSTA)
INSERT INTO tb_vinculos_professor_disciplina (fk_professor, fk_disciplina, data_vinculo, carga_horaria, tipo_vinculo) VALUES 
(1, 1, '2026-01-10', 40, 'titular'),
(1, 2, '2026-01-10', 40, 'titular'),
(2, 4, '2026-01-10', 40, 'titular'),
(3, 3, '2026-01-10', 20, 'auxiliar');

-- 10. Contratos Financeiros
INSERT INTO tb_contratos_educacionais (fk_aluno, data_inicio, data_fim, valor_mensalidade) VALUES 
(1, '2026-01-15', '2026-12-15', 850.00),
(2, '2026-01-15', '2026-12-15', 850.00);

-- 11. Mensalidades
INSERT INTO tb_mensalidades (fk_contrato, competencia, data_vencimento, valor, status_pagamento) VALUES 
(1, '2026-02-01', '2026-02-10', 850.00, 'pago'),
(1, '2026-03-01', '2026-03-10', 850.00, 'pendente'),
(2, '2026-02-01', '2026-02-10', 850.00, 'pago');

-- 12. Pagamentos
INSERT INTO tb_pagamentos (fk_mensalidade, data_pagamento, valor_pago, forma_pagamento) VALUES 
(1, '2026-02-09', 850.00, 'pix'),
(3, '2026-02-08', 850.00, 'boleto');

-- =============================================
-- CONSULTAS (SELECTS)
-- =============================================

-- Ver todas as pessoas e seus papéis
SELECT 
    p.nome_pessoa,
    p.cpf,
    p.email,
    CASE WHEN a.pk_aluno IS NOT NULL THEN 'Sim' ELSE 'Não' END AS eh_aluno,
    CASE WHEN prof.pk_professor IS NOT NULL THEN 'Sim' ELSE 'Não' END AS eh_professor
FROM tb_pessoas p
LEFT JOIN tb_alunos a ON p.pk_pessoa = a.fk_pessoa
LEFT JOIN tb_professores prof ON p.pk_pessoa = prof.fk_pessoa;

-- Boletim do Aluno
SELECT 
    p.nome_pessoa AS 'Aluno',
    c.nome_curso AS 'Curso',
    d.nome_disciplina AS 'Disciplina',
    n.qtde_faltas AS 'Faltas',
    n.nota_final AS 'Nota',
    CASE 
        WHEN n.nota_final >= 6.0 AND n.qtde_faltas <= 15 THEN 'Aprovado'
        ELSE 'Reprovado'
    END AS 'Situação'
FROM tb_alunos a
INNER JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
INNER JOIN tb_matriculas m ON a.pk_aluno = m.fk_aluno
INNER JOIN tb_disciplinas d ON m.fk_disciplina = d.pk_disciplina
INNER JOIN tb_cursos c ON d.fk_curso = c.pk_curso
INNER JOIN tb_notas n ON n.fk_aluno = a.pk_aluno AND n.fk_disciplina = d.pk_disciplina
WHERE p.nome_pessoa = 'Ana Clara Souza';

-- Inadimplência financeira
SELECT 
    p.nome_pessoa AS 'Aluno',
    p.cpf AS 'CPF',
    m.competencia AS 'Competência',
    m.data_vencimento AS 'Vencimento',
    m.valor AS 'Valor (R$)',
    m.status_pagamento AS 'Status'
FROM tb_mensalidades m
INNER JOIN tb_contratos_educacionais c ON m.fk_contrato = c.pk_contrato
INNER JOIN tb_alunos a ON c.fk_aluno = a.pk_aluno
INNER JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
WHERE m.status_pagamento != 'pago';

-- Relatório de Matrículas
SELECT 
    p.nome_pessoa AS 'Nome do Aluno',
    d.nome_disciplina AS 'Disciplina Matriculada',
    m.data_matricula AS 'Data da Matrícula'
FROM tb_matriculas m
INNER JOIN tb_alunos a ON m.fk_aluno = a.pk_aluno
INNER JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
INNER JOIN tb_disciplinas d ON m.fk_disciplina = d.pk_disciplina
ORDER BY p.nome_pessoa;

-- Relatório de Notas
SELECT 
    p.nome_pessoa AS 'Aluno',
    d.nome_disciplina AS 'Disciplina',
    n.nota_final AS 'Nota',
    n.qtde_faltas AS 'Faltas',
    CASE 
        WHEN n.nota_final >= 6.0 AND n.qtde_faltas <= 15 THEN 'Aprovado'
        ELSE 'Reprovado'
    END AS 'Situação'
FROM tb_notas n
INNER JOIN tb_alunos a ON n.fk_aluno = a.pk_aluno
INNER JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
INNER JOIN tb_disciplinas d ON n.fk_disciplina = d.pk_disciplina
ORDER BY p.nome_pessoa, d.nome_disciplina;

-- Relatório financeiro completo
SELECT 
    p.nome_pessoa AS 'Aluno',
    m.valor AS 'Valor Original (R$)',
    m.data_vencimento AS 'Vencimento',
    m.status_pagamento AS 'Status',
    pg.data_pagamento AS 'Data Pago',
    pg.valor_pago AS 'Valor Pago (R$)'
FROM tb_mensalidades m
INNER JOIN tb_contratos_educacionais c ON m.fk_contrato = c.pk_contrato
INNER JOIN tb_alunos a ON c.fk_aluno = a.pk_aluno
INNER JOIN tb_pessoas p ON a.fk_pessoa = p.pk_pessoa
LEFT JOIN tb_pagamentos pg ON pg.fk_mensalidade = m.pk_mensalidade
ORDER BY m.data_vencimento ASC;

-- Alocação de professores (relacionamento N:N)
SELECT 
    p.nome_pessoa AS 'Professor',
    d.nome_disciplina AS 'Disciplina Lecionada',
    v.carga_horaria AS 'Carga Horária (Horas)',
    v.data_vinculo AS 'Data de Vínculo',
    v.tipo_vinculo AS 'Tipo'
FROM tb_vinculos_professor_disciplina v
INNER JOIN tb_professores prof ON v.fk_professor = prof.pk_professor
INNER JOIN tb_pessoas p ON prof.fk_pessoa = p.pk_pessoa
INNER JOIN tb_disciplinas d ON v.fk_disciplina = d.pk_disciplina
ORDER BY p.nome_pessoa;

-- Aluno que também é Professor (pessoa com dois papéis)
SELECT 
    p.nome_pessoa AS 'Nome',
    p.cpf AS 'CPF',
    p.email AS 'Email',
    a.ra AS 'RA do Aluno',
    a.status_aluno AS 'Status Aluno',
    prof.registro_professor AS 'Registro do Professor',
    prof.formacao AS 'Formação'
FROM tb_pessoas p
INNER JOIN tb_alunos a ON p.pk_pessoa = a.fk_pessoa
INNER JOIN tb_professores prof ON p.pk_pessoa = prof.fk_pessoa;

use sisgesc;
-- adicionando restrições, para evitar duplicatas

-- restrição no nome do curso, evitando nomes iguais
alter table tb_cursos add constraint uk_nome_curso unique (nome_curso);

-- restrição no nome da disciplina, evitando que tenha duas disciplinas com o nome idêntico
alter table tb_disciplinas add constraint uk_disciplina_curso unique (nome_disciplina, fk_curso);

-- restrição na nota final do aluno, para que o aluno tenha apenas uma nota final por disciplina
alter table tb_notas add constraint uk_nota_aluno_disciplina unique (fk_aluno, fk_disciplina);



-- impedindo contratos duplicados ativos
DELIMITER $$

create trigger tr_contratos_unico_ativo
before insert on tb_contratos_educacionais
for each row
begin
	declare contrato_ativo int;
    
    select count(*) into contrato_ativo
    from tb_contratos_educacionais
    where fk_aluno = new.fk_aluno
    and data_fim is NULL;
    
    if contrato_ativo > 0 then
    signal sqlstate '45000'
    set message_text = 'Aluno ja possui um contrato ativo. Finalize o contrato atual antes de criar um novo';
    
    end if;
end$$


-- Impedir matrícula em disciplina se o aluno está inadimplente


create trigger tr_verificar_inadimplencia_antes_matricula
before insert on tb_matriculas
for each row
begin
	declare inadimplente int;
    
    select count(*) into inadimplente
    from tb_mensalidades m
    inner join tb_contratos_educacionais c on m.fk_contrato = c.pk_contrato
    where c.fk_aluno = new.fk_aluno
    and m.status_pagamento = 'atrasado';
    
    if inadimplente > 0 then
    signal sqlstate '45000'
    set message_text = 'Aluno inadimplente. Regularize os pagamentos antes da matrícula.';
    
    end if;
end$$

delimiter ;
    