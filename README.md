<img width="2644" height="1098" alt="Untitled" src="https://github.com/user-attachments/assets/9bddf992-8a76-4c4e-b6f9-b0027c8e72ee" />



---

📚 SISGESC - ERP Educacional

Sistema de gestão educacional (ERP) projetado para controlar informações acadêmicas e financeiras de uma instituição de ensino.


---

📌 Visão Geral

O SISGESC é um banco de dados estruturado para gerenciar:

Cadastro de pessoas (base do sistema)

Alunos e professores

Cursos e disciplinas

Matrículas e notas

Vínculo entre professores e disciplinas

Contratos educacionais e mensalidades

Pagamentos


O modelo foi desenvolvido com foco em normalização, integridade referencial e escalabilidade.


---

🧱 Estrutura do Sistema

O banco é dividido em módulos principais:

🔹 Módulo Base

Responsável pelo cadastro central de pessoas.

tb_pessoas



---

🔹 Módulo Acadêmico

📘 Cursos e Disciplinas

tb_cursos

tb_disciplinas


👨‍🎓 Alunos e 👨‍🏫 Professores

tb_alunos

tb_professores


📝 Matrículas e Notas

tb_matriculas

tb_notas


🔗 Vínculo Professor-Disciplina

tb_vinculos_professor_disciplina



---

🔹 Módulo Financeiro

tb_contratos_educacionais

tb_mensalidades

tb_pagamentos



---

🔢 ENUMS Utilizados

O sistema utiliza ENUMs para padronizar valores:

status_aluno: ativo, inativo, trancado

status_matricula: ativa, cancelada, concluida

tipo_vinculo: titular, auxiliar, convidado

status_pagamento: pendente, pago, atrasado

forma_pagamento: dinheiro, cartao, boleto, pix



---

🔗 Relacionamentos

📌 N:N (Muitos para Muitos)

Alunos ↔ Disciplinas (via tb_matriculas)

Professores ↔ Disciplinas (via tb_vinculos_professor_disciplina)



---

📌 1:N (Um para Muitos)

Curso → Disciplinas

Pessoa → Aluno / Professor

Aluno → Contrato

Contrato → Mensalidades

Mensalidade → Pagamentos



---

📌 Relacionamento Composto

tb_notas possui chave estrangeira composta:

(fk_aluno, fk_disciplina)

Referencia tb_matriculas




---

⚙️ Regras de Negócio

Um aluno possui apenas um contrato ativo por vez

Uma disciplina pertence a apenas um curso

Um aluno só pode ter uma nota por disciplina

Uma mensalidade é única por contrato + competência

CPF e e-mail são únicos por pessoa

Aluno e professor possuem relação 1:1 com pessoa



---

🧠 Boas Práticas Aplicadas

Normalização até pelo menos 3FN

Uso de chaves primárias compostas

Integridade referencial com foreign keys

Uso de índices únicos

Separação por módulos (acadêmico e financeiro)

Campos de auditoria (created_at)



---

🚀 Possíveis Evoluções

Controle de turmas e horários

Sistema de frequência detalhado

Integração com APIs (ex: pagamentos)

Dashboard analítico (BI)

Controle de usuários e permissões



---

💻 Tecnologias Compatíveis

Esse modelo pode ser implementado com:

MySQL / MariaDB

PostgreSQL

SQL Server

SQLite (para versões simplificadas)



---

📎 Observações

Este modelo foi pensado para ser:

Didático (para estudo e portfólio)

Escalável (para projetos reais)

Adaptável (pode virar API, sistema web ou app)



---

 
