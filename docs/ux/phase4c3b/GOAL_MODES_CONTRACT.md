# Contrato técnico proposto — três modos de metas

**Especificação para aprovação separada. Não implementada.** A Fase 4C.3B mantém SQLite v5 e cria apenas metas numéricas explícitas. Não existe migração executável neste documento.

## Diagnóstico exacto do v5

Goals tem target REAL NOT NULL CHECK(target > initial), initial/current REAL NOT NULL com default 0, unit TEXT NOT NULL com default «unidades», title/created NOT NULL. Description/category/horizon/status têm defaults; due e parent_id são opcionais. A interface antiga acrescentava unit=unidades e target=1; esses defaults da interface não representavam uma escolha de acompanhamento da pessoa. O v5 não tem discriminador de modo.

O nome vazio não é impedido pelo NOT NULL; é validado na interface. Uma unidade vazia também não é impedida pela base, mas não explica uma métrica à pessoa. A criação nesta fase exige nome, unidade explícita e alvo finito superior ao inicial. O inicial zero é mostrado, editável e não representa uma percentagem. O armazenamento não permite uma meta apenas com nome sem preencher um alvo numérico. Não se usam convenções escondidas para contornar esse facto.

O CHECK target > initial não exclui infinitos. A validação de parsing/finitude deve ocorrer na operação, mesmo quando opções avançadas estão recolhidas; o formulário 4C.3B aplica essa verificação antes de gravar.

GoalProgress regista valores numéricos absolutos com recorded_at; GoalMilestones guarda etapas auxiliares independentes. Tasks e Habits têm FKs para Goals; a hierarquia usa parent_id. Concluir etapas/tarefas não deve actualizar current. updateMetric conserva a operação actual: grava valor absoluto, deriva status pelo alvo e acrescenta histórico; não atribui XP.

## Modelo futuro recomendado e decisão necessária

| Elemento | Contrato proposto |
| --- | --- |
| tracking_mode explícito | NULL = legado numérico; numeric/binary/steps apenas por escolha explícita em novas metas. Nunca inferir por unit, target, título ou presença de etapas |
| Campos comuns | Mesmo id/title/description/category/horizon/due/created/parent_id/status. Preservar todos os valores antigos e FKs |
| numeric | initial/current/target/unit finitos/legíveis; target > initial; GoalProgress existente preservado |
| binary | Métrica ausente: initial/current/target/unit NULL; estado Em curso/Alcançada. Nenhuma fracção ou barra numérica |
| steps | Métrica ausente; GoalMilestones existente, contagem concluídas/total derivada. Zero etapas mostra vazio, nunca 0/0 nem conclusão automática |
| GoalLifecycleEvents, nova tabela | id/goal_id/action/recorded_at, com acções explícitas created/completed/reopened. Eventos novos desde activação; não fabricar acontecimentos históricos ou converter GoalProgress em eventos de estado |

**Uma migração puramente aditiva de colunas não chega para esta recomendação.** O CHECK/NOT NULL de target continuará a exigir números. Metadados e histórico podem ser aditivos; permitir NULL nas métricas de novos modos exige relaxar restrições da tabela Goals. Em SQLite isso requer reconstrução controlada da tabela e cópia integral, com FKs/índices/triggers/IDs/sequência preservados. É uma operação de risco que precisa de projecto de migração e autorização próprios; não chamar a uma reconstrução «só adicionar modo».

Alternativa técnica: manter um envelope numérico 0/1 nos novos modos, acompanhado de discriminador explícito. Essa alternativa guarda números sem significado métrico para a pessoa e necessita de aprovação específica; **não é adoptada nem recomendada automaticamente nesta entrega**. Uma tabela separada para metas simples também não resolve sozinha as FKs actuais de tarefas/hábitos/hierarquia. A decisão entre estas alternativas permanece bloqueada.

## Operações de criação e edição

A API futura deve receber um tipo explícito: CreateNumericGoal(nome, inicial, alvo, unidade, prazo…), CreateBinaryGoal(nome, prazo…) ou CreateStepsGoal(nome, etapas opcionais, prazo…). Fazer validação e gravação numa transacção; nunca gravar um rascunho de meta inválido para obter um ID. Criar etapas e meta atomicamente quando ambas são submetidas juntas.

Editar campos comuns não altera modo, métrica, estado ou histórico. Editar um resultado numérico usa updateMetric, com valor absoluto e timestamp novo. Alterar alvo conserva o comportamento numérico aprovado, documentando qualquer mudança de status. Não converter uma meta numérica com histórico apenas porque alguém apagou a unidade. Mudança de modo exige fluxo próprio, pré-visualização e autorização; inicialmente deve ficar indisponível quando há histórico ou dados incompatíveis.

O prazo fica como NULL ou data civil absoluta; datas antigas mantêm o texto exacto se não forem tocadas. Não guardar uma contagem que reinicie a cada abertura. Tarefas, hábitos e submetas ligados continuam independentes e com os mesmos IDs.

## Conclusão, reabertura e histórico

- Binary: concluir/reabrir só por acção explícita, com evento próprio na mesma transacção. Não chamar updateMetric(1/0) nem inventar GoalProgress.
- Steps: marcar etapa actualiza apenas essa etapa. A última oferece «Marcar meta como alcançada»; não conclui automaticamente. Desmarcar/eliminar uma etapa de meta alcançada informa divergência e oferece reabrir, sem reabrir silenciosamente. Sem etapas continua em curso.
- Numeric/legado: preserva updateMetric e o histórico absoluto. Registar valor abaixo do alvo pode reabrir conforme a operação actual. Um nome editado não recalcula o estado.
- Nenhum modo novo altera XP, conquistas, regras de hábitos ou finanças. O reconhecimento passado não é apagado ao reabrir. Eventos não são uma fonte retroactiva completa de actividade.

Eliminar uma meta mantém o contrato actual de cascata do seu histórico/etapas, preservando submetas/tarefas/hábitos sem associação; a nova tabela de eventos deve declarar o mesmo ON DELETE. Exportação deve incluir modo e eventos com versão de esquema explícita; não prometer importação/restauro que a aplicação ainda não oferece.

## Migração futura e testes de integridade obrigatórios

Antes de escrever uma migração: confirmar fixtures v1–v5 e esquema/triggers efectivos, copiar todos os campos antigos byte a byte, manter NULL como legado numérico e executar foreign_key_check/integrity_check. Validar IDs/FKs, sqlite_sequence, índices, prevenção de ciclos, cascatas, transacções abortadas e reabertura. Testar falha de energia/espaço no desenho de recuperação, sem operar em dados reais.

Cobertura: todos os três modos, legado com alvo 1/unidade «unidades» que continua numérico, initial não zero, alvos ultrapassados, status antigo divergente, timestamps com fuso/fracções, due NULL/civil/ISO, caracteres/valores monetários sem alteração, relações e histórico extensos. Testar repetição de concluir/reabrir, falha intermédia entre estado/evento, etapa eliminada, zero etapas, exportação versionada e impossibilidade de uma app antiga interpretar o esquema novo.

Rollback de código após relaxar o esquema não é automaticamente seguro. Exige ensaio de compatibilidade e plano de recuperação separados. Não eliminar nem reformatar métricas antigas para fazer os novos modos caber. Não preencher acontecimentos antigos por suposição. Nenhum passo desta secção foi executado na 4C.3B.

## Gate de aprovação

É necessário aprovar o modelo de métricas ausentes versus envelope técnico, a migração e compatibilidade, os eventos, operações de conversão/conclusão/reabertura e os testes de recuperação. Até lá: apenas metas numéricas; editor completo e histórico existentes disponíveis; sem criação só com nome, modos novos ou alteração de SQLite v5.
