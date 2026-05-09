# 🎓 SISGESC - ERP Educacional

> Sistema de Gestão Escolar e Corporativa - Solução completa para gerenciamento acadêmico e financeiro

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?style=for-the-badge&logo=mysql)
![Version](https://img.shields.io/badge/Version-1.0-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production-success?style=for-the-badge)

---

## 🔗 Links Rápidos

| Recurso | Link |
|---------|------|
| 🌐 **Interface Web do Sistema** | [tables-sql.vercel.app](https://tables-sql.vercel.app/) |
| 📚 **Documentação Completa (Notion)** | [DOCUMENTAÇÃO COMPLETA DO PROJETO SISGESC](https://www.notion.so/DOCUMENTA-O-COMPLETA-DO-PROJETO-SISGESC-e518a24745ec47088054301d173ff5e8) |
| 🗺️ **Diagrama DER** | [dbdiagram.io/d/69daa4678089629684740b7c](https://dbdiagram.io/d/69daa4678089629684740b7c) |
| 📁 **Repositório GitHub** | [github.com/seu-usuario/sisgesc](https://github.com/seu-usuario/sisgesc) |

---

## 📌 Visão Geral

O **SISGESC** é um sistema de gestão educacional (ERP) projetado para controlar informações acadêmicas e financeiras de uma instituição de ensino. O banco de dados foi estruturado com foco em **normalização**, **integridade referencial** e **escalabilidade**, atendendo tanto operações do dia a dia (OLTP) quanto análises gerenciais (OLAP).

### 🎯 Objetivos do Projeto

- ✅ Gerenciar cadastro de pessoas (base do sistema)
- ✅ Controlar alunos, professores, cursos e disciplinas
- ✅ Registrar matrículas, notas e frequência
- ✅ Administrar contratos educacionais e mensalidades
- ✅ Processar pagamentos e controle de inadimplência
- ✅ Fornecer dados para análise com Star Schema (OLAP)

---

## 🌐 Interface Web do Projeto

O projeto conta com uma **interface web interativa** disponível no link abaixo:

🔗 **[Acesse a Interface Web do SisGESC](https://tables-sql.vercel.app/)**

Esta interface foi desenvolvida para demonstrar, de forma visual e organizada, todas as fases de implementação do banco de dados:

| Fase | Conteúdo Demonstrado |
| :--- | :--- |
| **1. DDL (Estrutura)** | Listagem de todos os módulos (Acadêmico, RH, Financeiro, OLAP) e tabela detalhada com PKs, FKs e constraints |
| **2. Carga de Dados** | Exibição de **todos os registros** inseridos nas tabelas principais, comprovando a idempotência |
| **3. OLTP (Operações)** | SELECTs, Subselects e **Transações ACID** (ROLLBACK/COMMIT) com resultados reais |
| **4. OLAP + ETL** | Star Schema, processo ETL detalhado (Extract, Transform, Load) e validação OLTP = OLAP |
| **5. Performance** | Lista de índices criados e aplicação do EXPLAIN |
| **6. Governança** | Padrões adotados (snake_case), script de reset e versionamento Git |

---

## 📚 Documentação Completa

A documentação completa do projeto está disponível no Notion, contendo:

- 📖 **Toda a documentação do código SQL** (Fases 1 a 6)
- 📊 **Explicação detalhada do ETL** (Extract, Transform, Load)
- 🔄 **Demonstração das transações** (ROLLBACK e COMMIT)
- ✅ **Validações e resultados** (OLTP vs OLAP)
- 📝 **Checklist de qualidade e pontuação final**

🔗 **[Acesse a Documentação Completa no Notion](https://www.notion.so/DOCUMENTA-O-COMPLETA-DO-PROJETO-SISGESC-e518a24745ec47088054301d173ff5e8)**

---

## 🧱 Estrutura do Banco de Dados

O banco é dividido em **módulos organizacionais** para facilitar manutenção e entendimento:

### 📦 Módulo Base

| Tabela | Descrição |
|--------|-----------|
| `tb_pessoas` | Cadastro central de todas as pessoas (alunos e professores) |

### 📚 Módulo Acadêmico

| Tabela | Descrição |
|--------|-----------|
| `tb_cursos` | Cursos oferecidos pela instituição |
| `tb_disciplinas` | Disciplinas vinculadas aos cursos |
| `tb_alunos` | Cadastro de alunos (vinculado a tb_pessoas) |
| `tb_professores` | Cadastro de professores (vinculado a tb_pessoas) |
| `tb_matriculas` | Matrículas de alunos em disciplinas |
| `tb_notas` | Notas e faltas por matrícula |
| `tb_vinculos_professor_disciplina` | Vínculo entre professores e disciplinas |

### 💰 Módulo Financeiro

| Tabela | Descrição |
|--------|-----------|
| `tb_contratos_educacionais` | Contratos financeiros dos alunos |
| `tb_mensalidades` | Mensalidades geradas por contrato |
| `tb_pagamentos` | Registro de pagamentos realizados |

### 📊 Módulo Analítico (OLAP - Star Schema)

| Tabela | Descrição |
|--------|-----------|
| `dim_aluno` | Dimensão aluno com faixa etária calculada |
| `dim_curso` | Dimensão curso |
| `dim_tempo` | Dimensão tempo (ano, mês, semestre) |
| `fato_financeiro` | Fato financeiro (valores previstos e pagos) |

---

## 🔗 Diagrama Entidade-Relacionamento (DER)

![DER - SISGESC](https://github.com/user-attachments/assets/69f89fbb-4ce2-4964-8dea-b061bc1c15c7)

🔗 **Link interativo:** [Visualizar DER no dbdiagram.io](https://dbdiagram.io/d/69daa4678089629684740b7c)

---

## 🔢 ENUMS Utilizados

O sistema utiliza **ENUMs** para padronizar valores e garantir integridade:

| Campo | Tabela | Valores Permitidos |
|-------|--------|-------------------|
| `status_aluno` | tb_alunos | `ativo`, `inativo`, `trancado` |
| `status_matricula` | tb_matriculas | `ativa`, `cancelada`, `concluida` |
| `tipo_vinculo` | tb_vinculos_professor_disciplina | `titular`, `auxiliar`, `convidado` |
| `status_pagamento` | tb_mensalidades | `pendente`, `pago`, `atrasado` |
| `forma_pagamento` | tb_pagamentos | `dinheiro`, `cartao`, `boleto`, `pix` |

---

## 🔗 Relacionamentos

### 📌 N:N (Muitos para Muitos)

| Relacionamento | Tabela de Ligação |
|----------------|-------------------|
| Aluno ↔ Disciplina | `tb_matriculas` |
| Professor ↔ Disciplina | `tb_vinculos_professor_disciplina` |

### 📌 1:N (Um para Muitos)

| Relacionamento | Descrição |
|----------------|-----------|
| Curso → Disciplinas | Um curso possui muitas disciplinas |
| Pessoa → Aluno / Professor | Uma pessoa pode ser aluno ou professor |
| Aluno → Contrato | Um aluno pode ter vários contratos (apenas 1 ativo) |
| Contrato → Mensalidades | Um contrato gera várias mensalidades |
| Mensalidade → Pagamentos | Uma mensalidade pode ter vários pagamentos |

### 📌 Relacionamento Composto

| Tabela | Chave Estrangeira | Referência |
|--------|-------------------|-------------|
| `tb_notas` | `(fk_aluno, fk_disciplina)` | `tb_matriculas` |

---

## ⚙️ Regras de Negócio

O sistema implementa as seguintes regras via **constraints** e **triggers**:

| Regra | Implementação |
|-------|---------------|
| ✅ Um aluno possui apenas um contrato ativo por vez | `TRIGGER tr_contratos_unico_ativo` |
| ✅ Uma disciplina pertence a apenas um curso | `FOREIGN KEY (fk_curso)` |
| ✅ Um aluno só pode ter uma nota por disciplina | `UNIQUE (fk_aluno, fk_disciplina)` |
| ✅ Nota final deve ser entre 0 e 10 | `CHECK (nota_final BETWEEN 0 AND 10)` |
| ✅ CPF e e-mail são únicos por pessoa | `UNIQUE (cpf)`, `UNIQUE (email)` |
| ✅ Aluno e professor possuem relação 1:1 com pessoa | `UNIQUE (fk_pessoa)` |
| ✅ Matrícula de aluno inadimplente é bloqueada | `TRIGGER tr_verificar_inadimplencia_antes_matricula` |
| ✅ Mensalidade única por contrato + competência | `UNIQUE (fk_contrato, competencia)` |

---

## 🎯 ETL - Data Warehouse (OLAP)

O projeto implementa um **processo ETL completo** para alimentar o Star Schema:

### 📥 Extract (Extração)

```sql
-- Dados de alunos e pessoas
FROM tb_alunos a JOIN tb_pessoas p

-- Dados de cursos
FROM tb_cursos

-- Datas de vencimento e pagamento
FROM tb_mensalidades UNION tb_pagamentos

-- Dados financeiros
FROM tb_mensalidades LEFT JOIN tb_pagamentos
