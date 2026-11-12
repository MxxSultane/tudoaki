# Matriz de compatibilidade e rastreabilidade

Nenhuma linha desta tabela foi implementada nesta fase. «Visual futuro» significa necessidade de autorização e validação, não liberdade para alterar regras.

| Proposta | Fonte actual / dados | Preservar | Impacto / bloqueio | Aceitação futura |
| --- | --- | --- | --- | --- |
| Tokens/glossário partilhado | core/theme/app_theme e today_theme; fontes locais | Preferência claro/escuro/sistema, Inter/Newsreader, recursos Android | Visual futuro por módulo; não mudar o tema global de uma vez | Contraste/foco nos dois temas, 200%, sem regressão Hoje/Planear |
| Hábitos clay | HabitsScreen, Habits/HabitCompletions | Criar hábito em vazio/preenchido 4B, dias, pausa, associação, edição, 5 XP únicos/dia | Só aparência; alvos separados e sem cartões aninhados | Três criações distintas, reabertura SQLite sintética, XP idempotente |
| FAB de Metas | shell /goals, showEditor Meta | Abertura directa 4B, Activas após guardar, outros pontos de criação | Não reintroduzir chooser no FAB; mesmo guard e retorno | Abrir/guardar/cancelar e alternar filtros/rotas |
| GoalSummary por modo | Goals com métricas obrigatórias; GoalProgress | Legado numérico, precisão, histórico, hierarquia, IDs e relações | **Requer discriminador futuro e contrato aditivo**, ausente no v5; nenhum tipo inferido | Migração sintética/round-trip/legado sem reescrita antes de activar modos |
| Meta binária/etapas sem % | GoalMilestones e status, envelope métrico actual | Etapas/tarefas não actualizam métrica automaticamente | Operações explícitas de concluir/reabrir e histórico precisam de especificação técnica | Última etapa não conclui sozinha; exclusão/reabertura não perde histórico |
| Prazo em dias | Goals.due, Editor | NULL sem prazo; ISO legado intacto se não alterado | Novo input, cálculo civil e formato para novos registos por aprovar em fase técnica | Vazio, 1/30/3650, 0/negativo/decimal, meia-noite, fuso, data limite 2100 |
| Formulário tarefa | QuickTaskSheet, TaskOperations, Tasks | 3B/4A/4B integral: rascunho, retorno, dias, lembrete, prioridade, importância, relações, Guardar outra | Apenas polimento futuro; não substituir serviço ou reconstruir para simplificar | Testes existentes intactos + foco/semântica, datas e duplicação |
| Formulário meta | Editor/forms.dart | Completo/editável, categorias, horizonte, alvo/inicial/unidade, submeta | Novo modo e descarte têm bloqueios próprios; não alterar restantes editores | Cancelar sem escrita, erro mantém dados, legado não perde campos |
| Estudos | AcademicsPanel, StudyRepository, AcademicRules, Subjects/Assessments/StudySessions/Tasks | Foco, sessões, aulas, horários, exames, trabalhos, associações e XP | Ordenação/hierarquia de apresentação; sem copiar avaliações/tarefas para Agenda | Editar cada origem; retomar foco; limites/XP e Adicionar trabalho preservados |
| Finanças | FinancePanel/Repository/Rules; tabelas financeiras v5 | Cêntimos, moeda por registo, categorias, mês, poupanças, orçamentos, recorrências/confirmar | Visual futuro; «entrada/saída» não muda os enums ou cálculos | Totais iguais por moeda e período; nunca conversão/soma transversal |
| Actividade e mapa conceptual | activityWeek, Tasks/HabitCompletions/StudySessions, Goals/GoalProgress, ExperienceEvents/Achievements | Fontes distintas, gamificação opcional, histórico limitado, regras XP | Mapa completo excluído; camada de leitura futura não pode fabricar eventos/títulos | Lista equivalente, sem duplicações ou novos XP; zero é ausência de registo |
| Agenda/Tarefas/navegação | AppRoutes/GoRouter/Cubits existentes | Hoje/Planear/Metas/Mais, Mais→Tarefas, editores/rotas antigas | Sem redesenho implícito; só correcção de acessibilidade comprovada, em fase própria | Estado/retorno/guard, eventos, datas e identidade dos IDs |
| Dados/distribuição | SQLite v5, lifeos.sqlite, mz.lifeos.lifeos | Caminhos, assinatura, dependências, dados reais, exportação | Nenhuma migração/build/release nova nesta fase | Diff documental; actualização nativa exige ensaio próprio antes de distribuir |

## Política do legado

Nenhuma abertura/reorganização escreve dados. Nenhuma migração inferida por cor, título ou unit. Nunca reinterpretar o prazo antigo como contagem iniciada hoje. Não recalcular current/status/XP por mudar tema. Uma edição modifica só campos confirmados, no mesmo ID, conservando valores ocultos. Modo de meta antigo permanece numérico mesmo com etapas até escolha explícita e contrato de conversão aprovado.

Uma futura extensão não destrutiva de esquema deve preservar compatibilidade de exportação/restauro, chaves estrangeiras, índices, triggers e transacções. O plano de restauro existente continua proposta, não garantia disponível; Git não protege os dados do telefone. Esta fase não resolve temporalidade/concorrência/backup apontados em 3F.

## Riscos e resposta de design

Recolher funções pode prejudicar descoberta: cada expansão tem nome, contagem e acesso textual; testar encontrar funções antigas sem ajuda. Clay excessivo reduz densidade: reservar para destaques e nunca aplicar a movimentos. Glass depende do fundo: conjunto fechado de composições e fallback sólido. Os modos de meta são o maior risco técnico: não implementar até aprovar um discriminador e operações próprias, sem conversão silenciosa.
