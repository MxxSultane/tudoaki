# Progresso — fontes e limites antes da 4C.3E

Base ffc9b0b48da024c566c3ee2b5d47a636495bc840; árvore inicialmente limpa; baseline 318/318. Revisão complementar às auditorias 4C.1/4C.2 e relatórios 4C.3A–D.

| Fonte real | O que comprova | O que não comprova |
| --- | --- | --- |
| Tasks completed/completed_at | Conclusão actualmente activa com instante guardado | Conclusão antiga de tarefa reaberta/eliminada; due/created não são conclusão |
| HabitCompletions habit_id/day | Registo daquele hábito no dia civil | Hora, nome histórico original, rotina eliminada em cascata |
| StudySessions completed/completed_at | Sessão actualmente concluída com instante | start é planeamento; não pode substituir completed_at ausente |
| GoalProgress goal_id/value/recorded_at | Valor numérico registado nessa data | Unidade/título históricos, data exacta de alcançar a meta, novo modo binário/etapas |
| Goals current/initial/target/unit/status | Estado e valores actuais da meta numérica | Evento datado de conclusão; created/due não são data de alcançar |
| ExperienceEvents source/points/created | Reconhecimento de XP persistido | Histórico integral: gamificação pode estar desligada, limite de estudo pode ser atingido; não contém título histórico |
| Achievements code/unlocked_at | Reconhecimento persistido das quatro conquistas | Actividade adicional ou XP extra; não é um catálogo novo de recompensas |
| activityWeek | Contagens existentes de tarefas/hábitos/estudos por dia em Maputo, últimos sete dias | Índice de produtividade, percentagem de sucesso, evolução inteira de vida |

Produção: /progress → AreaScaffold → ProgressScreen → WorkspaceData/dataProvider → ProgressPanel. O ecrã activo tinha título repetido (barra + WorkspacePage), cartão de contagens/XP, sete barras relativas ao máximo da semana e conquistas. Fazer uma revisão mantinha o acesso real a /reviews. screens.dart contém ainda uma implementação legada mais extensa, não usada por esta rota; não é removida nem apresentada como funcionalidade activa.

**Efeito de leitura existente:** dataProvider chama syncAchievements antes das consultas. Não se altera esse carregador global nem as regras/repositórios, pois servem os outros módulos. O novo leitor local de Progresso deve consultar só as nove tabelas necessárias, sem sincronizar/gravar. A inicialização global da aplicação continua a ter a sincronização anterior; a garantia de ausência de escrita é testada no leitor/ecrã de Progresso e, na navegação real, a partir da aplicação já carregada. Não se disfarça essa diferença como alteração das regras de XP.

Decisão: projecção de leitura de quatro fontes, uma entrada por tabela/ID, sem XP duplicado como actividade; datas ausentes/inválidas separadas, sem fallback de planeamento/criação. Nomes/associações são os actuais, não um arquivo imutável. Metas alcançadas são estado actual sem evento datado inventado. Percurso opcional será uma linha do tempo estática agrupada por dia, com a mesma lista e ordem, ligações apenas dentro do mesmo dia; nenhuma constelação aleatória ou relação causal fabricada.

Preservar todas as contagens existentes, activityWeek, quatro conquistas, nível/XP e acesso às revisões. Histórico e indicadores ficam secundários; ausência de actividade não gera julgamento. Sem esquema, dependências, operações ou entidades persistidas novas.
