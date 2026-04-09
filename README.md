
DER



// =============================================
// SISGESC - MODELO ESTRUTURAL DE DADOS
// ERP Educacional - 1ª Entrega
// Com Chave Composta e Relacionamento N:N
// =============================================

// TABELA ÚNICA DE PESSOAS
Table tb_pessoas {
  pk_pessoa INT [pk, increment]
  nome_pessoa VARCHAR(100) [not null]
  data_nascimento DATE [not null]
  cpf CHAR(11) [not null, unique]
  email VARCHAR(100) [not null, unique]
  telefone VARCHAR(15)
  endereco VARCHAR(200)
  created_at DATETIME [default: `now()`]
}

// TABELAS BASE
Table tb_cursos {
  pk_curso INT [pk, increment]
  nome_curso VARCHAR(100) [not null]
  duracao_semestres TINYINT [not null]
  created_at DATETIME [default: `now()`]
}

Table tb_disciplinas {
  pk_disciplina INT [pk, increment]
  nome_disciplina VARCHAR(60) [not null]
  carga_horaria TINYINT [not null]
  fk_curso INT [not null, ref: > tb_cursos.pk_curso]
}

// TABELAS DE PAPÉIS
Table tb_alunos {
  pk_aluno INT [pk, increment]
  fk_pessoa INT [not null, unique, ref: > tb_pessoas.pk_pessoa]
  ra CHAR(10) [not null, unique]
  status_aluno VARCHAR(20) [default: 'ativo']
  data_ingresso DATE [not null]
  created_at DATETIME [default: `now()`]
}

Table tb_professores {
  pk_professor INT [pk, increment]
  fk_pessoa INT [not null, unique, ref: > tb_pessoas.pk_pessoa]
  registro_professor CHAR(10) [not null, unique]
  formacao VARCHAR(100)
  data_contratacao DATE [not null]
  created_at DATETIME [default: `now()`]
}

// TABELA COM CHAVE COMPOSTA (N:N entre Aluno e Disciplina)
Table tb_matriculas {
  fk_aluno INT [not null]
  fk_disciplina INT [not null]
  data_matricula DATE [not null]
  status_matricula VARCHAR(20) [default: 'ativa']
  created_at DATETIME [default: `now()`]
  
  indexes {
    (fk_aluno, fk_disciplina) [pk]
  }
}

// TABELA DE NOTAS
Table tb_notas {
  pk_nota INT [pk, increment]
  qtde_faltas TINYINT [not null, default: 0]
  fk_aluno INT [not null]
  fk_disciplina INT [not null]
  nota_final DECIMAL(4,2)
}

// TABELA COM RELACIONAMENTO N:N (Professor e Disciplina)
Table tb_vinculos_professor_disciplina {
  fk_professor INT [not null]
  fk_disciplina INT [not null]
  data_vinculo DATE [not null]
  carga_horaria TINYINT [not null]
  tipo_vinculo VARCHAR(20) [default: 'titular']
  
  indexes {
    (fk_professor, fk_disciplina) [pk]
  }
}

// MÓDULO FINANCEIRO
Table tb_contratos_educacionais {
  pk_contrato INT [pk, increment]
  fk_aluno INT [not null, ref: > tb_alunos.pk_aluno]
  data_inicio DATE [not null]
  data_fim DATE
  valor_mensalidade DECIMAL(10,2) [not null]
  created_at DATETIME [default: `now()`]
}

Table tb_mensalidades {
  pk_mensalidade INT [pk, increment]
  fk_contrato INT [not null, ref: > tb_contratos_educacionais.pk_contrato]
  competencia DATE [not null]
  data_vencimento DATE [not null]
  valor DECIMAL(10,2) [not null]
  status_pagamento VARCHAR(20) [default: 'pendente']
  
  indexes {
    (fk_contrato, competencia) [unique]
  }
}

Table tb_pagamentos {
  pk_pagamento INT [pk, increment]
  fk_mensalidade INT [not null, ref: > tb_mensalidades.pk_mensalidade]
  data_pagamento DATE [not null]
  valor_pago DECIMAL(10,2) [not null]
  forma_pagamento VARCHAR(20) [default: 'boleto']
  created_at DATETIME [default: `now()`]
}

// =============================================
// RELACIONAMENTOS
// =============================================
Ref: tb_matriculas.fk_aluno > tb_alunos.pk_aluno
Ref: tb_matriculas.fk_disciplina > tb_disciplinas.pk_disciplina

Ref: tb_notas.fk_aluno > tb_matriculas.fk_aluno
Ref: tb_notas.fk_disciplina > tb_matriculas.fk_disciplina

Ref: tb_vinculos_professor_disciplina.fk_professor > tb_professores.pk_professor
Ref: tb_vinculos_professor_disciplina.fk_disciplina > tb_disciplinas.pk_disciplina
