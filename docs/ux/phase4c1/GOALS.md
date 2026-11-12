# Metas — nome, tempo e próximo passo

**Substitui a hipótese propositiva de 0–100% da 4B.** Uma meta sem medida numérica não recebe percentagem, barra vazia ou progresso por tempo decorrido. Acompanhamento escolhido pela pessoa, nunca inferido pelo nome, unidade, alvo 1/100, número de tarefas ou frequência de hábitos.

## Criação e descoberta

FAB de Metas conserva abertura directa, já corrigida em 4B. Folha inicial: Nome obrigatório; Prazo opcional em dias; «Criar» principal; «Acompanhamento adicional» discreto e recolhido. Sem escolha adicional, a nova meta é binária («Concluir quando alcançar»). A ajuda visível curta pode dizer «Pode acrescentar etapas ou uma medida depois», sem exigir tutorial. Horizonte/categoria/hierarquia/descrição e campos existentes continuam nas opções completas.

Prazo proposto: inteiro de **1 a 3650 dias**, 1 = amanhã no dia civil local seleccionado no momento da criação; 0, negativo, decimal e entrada não numérica são inválidos. Campo vazio = sem prazo. Mostrar data absoluta antes de Criar, p.ex. criação em 12/11/2026, 30 dias → **12/12/2026**. Calcular por dias de calendário, não N×24h; verificar intervalo 2000–2100 do selector. Ao atravessar a meia-noite com rascunho aberto, manter a data absoluta já apresentada e permitir recalcular explicitamente; nunca trocar o prazo silenciosamente ao enviar. Sem prometer que este fuso/contrato já está implementado.

Opção «Escolher data» serve prazos mais longos ou uma data precisa. Na edição, mostrar o prazo absoluto existente, não reiniciar N dias a partir de hoje. Preservar timestamp/precisão legado sem alterações; «Retirar prazo» é explícito. O prazo da meta é independente do dia de tarefas e não cria lembretes automaticamente.

## Modos e estados

| Modo escolhido | Lista / detalhe | Próximo passo | Conclusão e reabertura |
| --- | --- | --- | --- |
| Binário (novo sem métrica) | «Em curso» ou «Alcançada», ícone de estado e nome; sem fracção ou % | Se há tarefa ligada, oferecer a tarefa pendente existente; caso contrário «Adicionar acção» opcional | «Marcar como alcançada» explícito; depois «Reabrir». Não inventar valores de progresso intermédio |
| Por etapas | «2 de 4 etapas concluídas» e lista de etapas; sem %; se zero, «Ainda sem etapas» | Primeira etapa pendente com ordem estável existente; pessoa pode abrir outra. Não inventar drag/reordenação persistida | Última etapa não conclui a meta automaticamente: oferecer «Todas as etapas concluídas. Marcar meta como alcançada?». Reabrir etapa não apaga reconhecimento nem reabre silenciosamente a meta; informar divergência e oferecer Reabrir meta |
| Numérico | Valor actual/alvo + unidade real; barra opcional com alternativa textual; inicial acessível nas opções | «Registar resultado» com unidade e valor actual; acções ligadas continuam separadas | Preserva updateMetric e estado por alvo; valores finitos, vírgula decimal, progresso relativo a initial. Não reduzir resultado real para caber na barra: visual pode limitar-se a 0–1, valor textual permanece |

Exemplos: «Enviar candidatura» é binária; «Preparar candidatura» tem 3 etapas; «Ler 12 livros» é numérica, 3/12 livros. «2 de 4» mede etapas, não garante metade do esforço. Sem etapas, não exibir 0/0 nem calcular divisão. Se todas forem eliminadas, mostrar estado vazio, não concluir. Tarefas, hábitos e submetas ligadas não aumentam o resultado da meta. Não existe regra nova de XP por concluir uma meta.

No detalhe, uma acção principal depende do modo: Concluir (binário), abrir próxima etapa (etapas), Registar resultado (numérico). Adicionar acção, etapas, editar, criar submeta e histórico mantêm acesso secundário nomeado. «Próximo passo» não cria uma tarefa nem altera datas até confirmação. Metas alcançadas mantêm consulta/edição/reabertura pelo mecanismo apropriado. Eliminar mantém aviso sobre histórico/etapas e preservação das relações conforme o contrato actual.

## Compatibilidade e decisão de dados pendente

O v5 actual **não tem modo**. Goals exige target > initial; status e métricas existem, GoalMilestones é independente. É inseguro decidir que unit=unidades e target=1 significa binário: uma meta antiga pode realmente medir uma unidade.

Recomendação para uma futura fase técnica, sujeita a autorização separada: discriminador nullable **tracking_mode** com valores explicitamente validados (binary/steps/numeric), aditivo, sem remover campos nem alterar tabelas antigas. NULL significa **legado numérico**, nunca «adivinhar tipo». Testar migração aditiva, exportação/restauro e compatibilidade antes de gravar qualquer modo. Este documento não altera schemaVersion nem contém uma migração executável.

Para novas binary/steps, a futura especificação técnica pode manter os campos numéricos obrigatórios como envelope interno 0/1 e unidade de resultado, sem os mostrar como percentagem. Isso não dispensa o discriminador. A operação explícita concluir/reabrir deverá manter status/envelope consistentes e definir se/como regista histórico sem fabricar registos de etapas em GoalProgress. **É um bloqueio técnico para implementação**, não autorização para chamar updateMetric indiscriminadamente ou para ocultar uma métrica antiga. Os wireframes mostram o comportamento de produto, não uma solução de persistência já disponível.

Metas por etapas usam as linhas existentes GoalMilestones; o resumo é derivado e não altera Goals.current ao marcar uma etapa. A confirmação final de meta é operação separada. Novas metas numéricas conservam initial/target/current/unit e GoalProgress. Valores registados são absolutos como no serviço actual, não incrementos ambíguos.

Metas antigas, incluindo as que já têm etapas: por defeito continuam numéricas; etapas mantêm secção auxiliar independente. Preservar ID, created, description, category, horizon, parent_id, due exacto, initial/current/target/unit/status, GoalProgress e todas as relações. Não recalcular histórico, XP ou status ao abrir o novo visual. A alteração de modo não é automática: propor fluxo futuro de pré-visualização/consentimento próprio; até esse contrato ser aprovado, manter mudança de modo bloqueada quando existe histórico ou dados incompatíveis, e editor completo acessível.

## Critérios próprios de revisão

Criar sem medida não pede números; compreender o estado binário sem %. Completar etapas não altera resultado por engano; valores/histórico antigos sobrevivem byte a byte ao abrir/cancelar. Sem data continua válido. Meta com data ISO conserva hora se só se editar nome. Reabertura, fracções, alvo abaixo do inicial, precisão, exclusão de etapas e falha de escrita têm cenários futuros em ACCEPTANCE. Não recomendar implementar os três modos apenas como alterações a forms.dart.
