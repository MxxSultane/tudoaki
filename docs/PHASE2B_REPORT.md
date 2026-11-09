# Fase 2B — operações de tarefas

## Origem
Branch de origem refactor/fase-2a-modulos-antigos, commit 62ab816e0011675a7bb45b3e9386792c4bedf01e, árvore limpa; HEAD remoto igual ao local. Base efectivamente validada segundo confirmação explícita do utilizador de CI verde. Novo branch refactor/fase-2b-tarefas. Lidos AGENTS.md, V2_CONTRACTS.md, ARCHITECTURE.md e relatórios anteriores. O pedido desta fase autoriza a refactorização de operações, sem autorizar a Fase 2C.

## Mapa anterior, apresentado antes das alterações
| Operação | Caminho anterior | Dependências |
| --- | --- | --- |
| Criar/editar | + ou Metas/Estudos → showEditor → Editor.save → repo.save(Tasks) | Validação/serialização no formulário, SQLite, Reminders, dataProvider |
| Reagendar | Planeador → nova tarefa/Escolher pendente/editar TaskRow → mesmo Editor.save | Mesmo ID, data YYYY-MM-DD ou ISO, associações e lembretes |
| Concluir/reabrir | TaskRow em Agenda/Tarefas/Metas/planeador; taskCard antigo em Estudos/legado | repo.taskDone, XP transaccional, cancel/schedule duplicados, wrappers de invalidação |
| Eliminar | Editor.remove com confirmação → cancelar lembrete → repo.delete | Cancelamento pode impedir a eliminação; invalidação depois da remoção |
| Ler | dataProvider → snapshot de Tasks | Filtros/ordenação locais em cada ecrã; agendaItemsForDay como modelo de leitura |

Goals/GoalPlan ligam tarefas por goal_id; AcademicsPanel por subject_id e taskBuilder. Eventos e avaliações não escrevem em Tasks. Escolher pendente conserva o ID, não copia linhas. A eliminação de metas/disciplinas altera relações por FK e a eliminação total das Definições cancela todos os alarmes antes de repo.erase; não são operações individuais de tarefas a substituir nesta fase.

## Arquitectura implementada
Uma classe TaskOperations utiliza a mesma instância TudoAkiRepository e Reminders, com callback de actualização fornecido por Riverpod. Sem tabela, cache, repositório de persistência ou sistema de estado paralelo. TaskWriteResult devolve ID e eventual TaskReminderFailure (unavailable/failed), mantendo as mensagens na interface.

Operações:
- create: fornece created se o chamador não o definir, mantém campos opcionais/defaults SQLite; grava via save.
- edit: UPDATE pelo ID; campos não enviados, incluindo associações, ficam intactos. Aceita snapshot anterior para preservar o contrato do editor. Sem snapshot consulta os dados existentes pelo repositório.
- reschedule: passa a data literal a edit; NULL e YYYY-MM-DD desactivam lembrete como no editor. Não normaliza ISO/UTC, não cria outra linha. O planeador continua a passar pelo editor/edit; não foi forçado a usar uma nova API de formulário.
- setCompleted: delega integralmente em repository.taskDone, depois coordena cancelamento/reagendamento. Callback onPersisted mantém a ordem do feedback táctil do TaskRow. Nenhum cálculo de XP/conquista movido.
- delete: cancela primeiro se reminder=1; se o cancelamento lançar erro, não elimina, tal como antes. Depois usa repository.delete.

Erros de lembrete em criação/edição/conclusão não desfazem a gravação já concluída: são devolvidos ao chamador como antes. Erros SQLite propagam-se e não são tratados como lembretes. A flag reconcileReminders preserva a intenção original do editor, incluindo cancelamento quando a data/hora é removida. A opção refreshConsumers=false fica limitada aos dois componentes antigos com wrappers que já invalidam dados; evita duplo refresh e mantém a ordem aviso → invalidação. Chamadas novas ao serviço actualizam dataProvider por defeito.

## Integrações e compatibilidade
Editor.save/remove, TaskRow e taskCard antigo passaram a usar taskOperationsProvider. Validação, campos, serialização, textos, snackbars, confirmação, Navigator e layouts não mudaram. A criação/reagendamento do planeador, metas e trabalhos académicos herdam a centralização por reutilizarem o mesmo editor.

Mantidas as APIs públicas repository.save/delete/taskDone: são a camada de persistência existente e continuam usadas por fixtures, testes e consumidores antigos. Não foram removidas nem reescritas. dataProvider, filtros, Cubits, modelos de leitura e ordenações permanecem iguais. Hábitos e eliminação global das Definições ficam intactos. Não há nova distinção física entre data planeada e prazo, nem novas regras para registos inexistentes ou validação de título fora do formulário.

## Testes acrescentados
Dez casos em task_operations_test.dart: criação com título/opcionais e relações, edição por ID, reagendamento sem duplicação/precisão de datas, XP/conquista idempotentes e métrica de meta, gamificação desligada, reagendamento de lembretes, falhas de plataforma sem perder gravação, ordem do callback/conclusão, cancelamento antes da eliminação, falha SQLite sem efeitos laterais e actualização de consumidores via ProviderContainer. Alguns casos reúnem mais de uma verificação; são dez testes, não uma contagem por assertion.

Um caso de integração em task_delete_flow_test.dart usa o editor existente: cancelar a confirmação não elimina, confirmar cancela o lembrete e remove a tarefa da lista, mantendo XP. Reutiliza helpers públicos de phase1_task_flows_test.dart, sem alterar testes anteriores. Os testes existentes de app/planeador/metas/estudos e lembretes continuam a exercitar os mesmos consumidores.

## Validação
- Dart SDK oficial 3.9.2: formatação aplicada aos sete ficheiros Dart criados/modificados; verificação read-only de lib/test com 68 ficheiros, zero alterações, código 0. Aviso de flutter_lints não resolvido por falta de dependências locais, sem falha do formatador.
- flutter analyze --no-pub e flutter test --no-pub tentados, ambos código 1 antes da execução: bootstrap bloqueado por HTTP 403 de storage.googleapis.com. Zero testes Flutter executados localmente; os onze novos não são declarados aprovados.
- git diff --check e sintaxe YAML/shell verificados. Diff vazio em lib/core/database, android/, pubspec.yaml, pubspec.lock, finanças, progresso, tema e notificações. Testes antigos inalterados. Estruturas de apresentação e campos do formulário comparados com a base.
- Workflow existente preserva comandos, versões, critérios e códigos de falha. Única alteração: acrescentar o novo branch ao disparo push para executar a validação real; não contorna falhas de código. CI desta entrega ainda precisa de resultado observado.

## Ficheiros
Novos: lib/features/tasks/domain/task_operations.dart; test/task_operations_test.dart; test/task_delete_flow_test.dart; docs/PHASE2B_REPORT.md.
Modificados: lib/app/providers.dart; lib/features/forms.dart; lib/features/tasks/presentation/task_row.dart; lib/features/screens.dart; docs/ARCHITECTURE.md; .github/workflows/flutter-validation.yml.

## Riscos e limites
A coordenação SQLite/Android não é uma transacção distribuída; mantém os pontos de falha anteriores e distingue o resultado guardado da notificação. Snapshot passado por um editor pode ficar desactualizado se houver operações concorrentes, comportamento anterior preservado. As APIs de baixo nível continuam disponíveis por compatibilidade e não fazem reconciliação automática de alarmes. Validação física e equivalência de todos os estados da interface continuam pendentes; comparação de fonte e formatação não substituem análise/testes. Nenhuma operação sobre dados reais.

Esquema v5, lifeos.sqlite, mz.lifeos.lifeos, dependências, finanças, XP/conquistas, navegação, design e funcionalidades preservados. Não há mudanças funcionais intencionais.

## Recomendação para 2C
Primeiro rever o serviço e obter CI verde desta entrega, incluindo os testes antigos. Só com nova aprovação definir o âmbito da 2C, por exemplo reduzir a dependência do editor genérico em passos pequenos, reutilizando o serviço e mantendo contratos. Não antecipar interface, novas datas de prazo/planeamento, Percurso ou restauro. Fase 2C não iniciada; sem merge automático.
