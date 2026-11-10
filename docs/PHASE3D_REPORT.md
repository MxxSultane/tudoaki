# Fase 3D — novo Planear

## Origem e mapa anterior — registados antes de alterar implementação
Branch feat/fase-3d-novo-planear, derivado de 91bbe38e5c7e53eeb6026c966598900ce0e053c8. Árvore limpa; última base da Fase 3C validada com 145 testes locais e Actions 42791051823 verde. Foram lidos AGENTS.md, V2_CONTRACTS.md, DESIGN_SYSTEM.md e as duas especificações HOJE_PLANEAR da Fase 3A. O pedido 3D autoriza esta evolução, prevalecendo sobre indicações históricas de Fase 1/implementação futura.

Fluxo actual: Hoje → Planear semana, ou Mais → Planear semana → /weekly-planner → AreaScaffold + WeeklyPlannerCubit + WeeklyPlannerScreen. O botão Voltar usa a pilha actual ou / como fallback. Não existe /plan registada.

| Comportamento anterior | Integração prevista |
| --- | --- |
| Domingo abre segunda seguinte; outros dias abrem semana actual | WeeklyPlannerCubit original mantido; entrada normal continua em Semana. |
| Sete cartões verticais, um expandido, tipo Tarefa/Evento no topo | Vista Semana reutiliza WeeklyPlannerScreen, sem outra tabela ou cópias de tarefas. |
| Semana anterior/seguinte, selector de qualquer data, limites 2000–2100 | Conservados com as chaves, selecção de dia e regresso dos editores. |
| Criar tarefa por formulário antigo com dia obrigatório e hora opcional | Preservado na Semana para compatibilidade; criação das novas vistas Hoje/Amanhã/Sem data usa showQuickTaskSheet. Não substituir nem modificar forms.dart. |
| Escolher pendente sem data → editor contextual → Guardar no mesmo ID | Conservado na Semana; novas vistas diárias usam escolha + confirmação de dia por TaskOperations.reschedule. |
| Eventos pessoais/académicos, conflitos, editores por origem | Preservados; dia usa o mesmo modelo agendaItemsForDay, sem gravar ocorrências académicas em CalendarEvents. |
| TaskRow conclui/reabre e abre editor completo | Reutilizado; menu contextual adicional permite mudar dia/retirar data. XP continua no repositório. |
| Rodapé com dia seleccionado e única acção principal | Preservado em Semana; equivalente contextual nas novas vistas e confirmação visível junto da acção. |

## Proposta de integração
PlanningScreen recebe Hoje/Amanhã/Semana/Sem data como selecção efémera; começa em Semana para manter as entradas Planear semana e a regra de domingo. Reutiliza o Cubit semanal já existente, sem modificar o seu contrato. Hoje ganhará um encaminhamento explícito Planear amanhã para a mesma rota através de contexto interno tipado, sem novo caminho público. Nenhuma barra principal nova.

Dia: tarefas pendentes e concluídas separadas, compromissos e acesso a eventos, criação rápida contextual removível e escolha de pendente existente. Sem data: tarefas sem dia, criação sem data, associação explícita a um dia e editor antigo para editar/eliminar. Menu de tarefa usa uma folha apenas de reagendamento, com dia/hora explícitos, preservação da precisão quando não alterada e aviso de desligar lembrete ao retirar hora/data. Só Guardar/confirmar escreve por TaskOperations; nenhuma regra de persistência duplicada.

Tema: reutilizar buildTodayTheme da Fase 3C no planeamento. Relógio: fonte workspaceClockProvider, actualização ao minuto/retoma; Hoje/Amanhã relativos acompanham a mudança civil, data escolhida e semana consultada permanecem explícitas. Consulta e mudança de vista não escrevem.

## Implementação e validação
O ecrã é PlanningScreen na rota /weekly-planner, com quatro modos internos. A entrada normal mantém Semana por compatibilidade; Hoje → Planear amanhã abre directamente Amanhã. Mais → Planear semana e Hoje → Planear semana continuam funcionais. Voltar conserva a pilha e o contexto de origem; /plan não foi registada.

Hoje/Amanhã permitem escolher outra data explicitamente, consultar pendentes/concluídas e compromissos separados, criar com showQuickTaskSheet e escolher pendentes existentes (sem data ou de outros dias). O selector mostra a data de origem; a folha apresenta o destino e só Guardar grava. A tarefa conserva ID, created, relações, prioridade/importância e restantes campos. Alterar a vista ou consultar outra semana não escreve.

Sem data apresenta pendentes e concluídas com due NULL, cria sem dia e permite escolher dia pelo menu. Tocar no título abre Editor, incluindo a eliminação original. Nenhuma tarefa é copiada. A confirmação de criação está no rodapé visível mesmo com 50 tarefas; uma gravação fora da vista oferece Ver tarefa, sem redireccionar automaticamente.

Semana reutiliza a composição, Cubit, tipo Tarefa/Evento, selecção/limites e editores anteriores. Mantém a criação pelo formulário antigo com dia contextual obrigatório e hora opcional; a criação rápida está nas vistas novas. O menu de cada tarefa acrescenta Escolher dia/Retirar data. Não se eliminou nem se substituiu globalmente qualquer formulário. Concluídas continuam visíveis na semana com a caixa e o traço existentes; nas vistas diárias/Sem data ficam numa expansão própria.

TaskScheduleSheet serve apenas para reagendar: dia obrigatório para essa operação, hora opcional e lembrete nunca ligado automaticamente. Mantém a hora e precisão existentes por defeito; Retirar hora e Retirar data desligam o lembrete por TaskOperations. Retirar data exige confirmação, sem eliminar a tarefa. Erro SQLite mantém o rascunho/estado e permite repetição; falha de lembrete é apresentada separadamente da gravação, sem repetir create.

scheduledTaskDue preserva a string original quando dia/hora não mudam; ao mudar o dia preserva hora local, segundos e subsegundos, e mantém UTC quando aplicável. Uma alteração explícita de hora passa a ter a precisão seleccionada no controlo. planningItemsForDay reutiliza as ocorrências existentes e agrupa Tasks pelo dia local, tal como o novo Hoje. Isto afecta apenas a projecção de Planear; valores due não são reescritos durante a consulta. Os modelos académicos não são inseridos como eventos pessoais.

O relógio utiliza workspaceClockProvider e actualiza ao minuto/retoma. Hoje/Amanhã relativos acompanham a meia-noite; data escolhida e selecção semanal ficam fixas. A data contextual fica explícita na folha aberta, mesmo se o relógio avançar durante a edição. Nenhum reagendamento automático, penalização ou XP de planeamento.

## Ficheiros criados e modificados
| Ficheiro | Responsabilidade |
| --- | --- |
| lib/features/planning/domain/planning_view.dart | Contexto interno tipado, sem nova rota pública. |
| lib/features/planning/domain/planning_dates.dart | Serialização da mudança explícita de dia/hora, preservando precisão. |
| lib/features/planning/domain/planning_items.dart | Projecção civil local de tarefas e ocorrências partilhadas. |
| lib/features/planning/presentation/planning_screen.dart | Integração dos quatro modos, criação e escolha contextual, relógio e confirmações. |
| lib/features/planning/presentation/task_schedule_sheet.dart | Reagendamento por TaskOperations, bloqueio de duplo envio e tratamento de erro. |
| lib/features/planning/presentation/planner_task_tile.dart | Reutiliza TaskRow e acrescenta menu de dia/retirada, com confirmação. |
| lib/features/weekly_planner/presentation/weekly_planner_screen.dart | Projecção partilhada, menu e confirmação; restantes fluxos conservados. |
| lib/app/app.dart | Usa PlanningScreen no mesmo route e aplica o tema existente da Fase 3C. |
| lib/features/agenda/presentation/today_screen.dart | Só importação e ligação contextual Planear amanhã. |
| lib/core/theme/today_theme.dart | Reutilização em Planear, incluindo AppBar e superfícies de cartões. |
| test/planning_dates_test.dart | Quatro testes de precisão/projecção, SQLite em memória. |
| test/planning_screen_test.dart | Vinte e sete casos widget/integração, incluindo dois temas e texto ampliado. |
| test/support/planning_fixture.dart | Repositório sintético/relógio, falhas simuladas e lembretes falsos. |
| tool/capture_planning.dart | Renderização reproduzível de seis capturas Flutter. |
| docs/ux/previews/phase3d/*.png | Dia, Semana e Sem data em claro/escuro. |
| .github/workflows/flutter-validation.yml | Só acrescenta o branch ao disparo push. |
| docs/ARCHITECTURE.md, docs/DESIGN_SYSTEM.md e este relatório | Arquitectura, âmbito visual, mapa anterior e resultados. |

Operações reutilizadas: TaskOperations.create/reschedule/setCompleted/edit/delete; TaskRow; showQuickTaskSheet; showEditor/Editor; showAcademicEditor; agendaItemsForDay/agendaConflict; WeeklyPlannerCubit/WeeklyPlannerScreen; WorkspaceData/applyWorkspace; buildTodayTheme. Sem persistência paralela ou cálculo próprio de XP.

## Testes e resultados locais observados
Ferramentas do projecto: Flutter 3.35.7, revisão adc901062556672b4138e18a4dc62a4be8f4b3c2, Dart 3.9.2. Ambiente preparado na Fase 3B; sem dependências novas nem actualizações. Comandos após source tool/env.sh:

| Comando | Resultado |
| --- | --- |
| dart format --output=none --set-exit-if-changed lib test tool/capture_today.dart tool/capture_planning.dart | Código 0: 91 ficheiros, zero alterações. |
| flutter analyze --no-pub | Código 0: sem problemas. |
| flutter test --no-pub --reporter expanded | Código 0: **176 aprovados, 0 falhados**, duração observada 86 segundos. Inclui 145 anteriores e 31 novos. |
| flutter test --no-pub tool/capture_planning.dart --reporter expanded | Código 0: seis renderizações, separadas da contagem da suite normal. |
| Compatibilidade inicial: weekly_planner_widget_test + navigation_contract_test + today_screen_test | 27 aprovados sem alterar os testes antigos. |

Cobertura nova: todos os modos; entrada real de Hoje e Voltar; criação contextual, sem data e continuação; escolha de pendente datada/sem data; preservação de ID/associações/campos; mudança e retirada de data; hora preservada/alterada/retirada; precisão UTC/offset/subsegundos; conclusão/reabertura e XP idempotente; lembretes indisponíveis/erro; escrita falhada e repetição sem falsa confirmação; retirada falhada sem cancelar alarme; erro de leitura e repetição; edição/eliminação pelo Editor; origem académica e regresso ao dia; compatibilidade semanal; 50 tarefas; meia-noite/retoma, data explícita e semana conservadas; claro/escuro, 360 px, texto 200% e teclado simulado.

As primeiras execuções dos novos testes revelaram pressupostos incorrectos de localização (abreviatura de mês), construção progressiva da lista, controlos do selector e formato horário de entrada. Foram corrigidos os localizadores e a interacção dos testes, mantendo os resultados de aceitação. Nenhum teste antigo foi modificado para aceitar regressões.

## Capturas reais
Flutter/RepaintBoundary, 390 × 844, PNG a 2×, fontes e MaterialIcons locais, relógio fixo e SQLite em memória. Capturas revistas nos dois temas; sem imagens conceptuais ou edição gráfica. Reproduzir: source tool/env.sh; flutter test --no-pub tool/capture_planning.dart.

| Vista | Claro | Escuro |
| --- | --- | --- |
| Dia | [Captura](ux/previews/phase3d/planning-today-light.png) | [Captura](ux/previews/phase3d/planning-today-dark.png) |
| Semana | [Captura](ux/previews/phase3d/planning-week-light.png) | [Captura](ux/previews/phase3d/planning-week-dark.png) |
| Sem data | [Captura](ux/previews/phase3d/planning-undated-light.png) | [Captura](ux/previews/phase3d/planning-undated-dark.png) |

## GitHub Actions
**Verde, observado** no commit de implementação 1add6071c675257e9b21d232985a84b4b6b2b444: execução [42796970887](https://github.com/MxxSultane/tudoaki/actions/runs/42796970887), estado COMPLETED e conclusão SUCCESS. O workflow mantém Flutter 3.35.7/Dart 3.9.2, resolução com --enforce-lockfile, formatação, análise, testes e verificação do lockfile; não há publicação/deploy.

A contagem de 176 testes e os 86 segundos acima são resultados locais executados, não uma contagem remota inferida. Os logs da execução exigem login; a observação foi feita na página pública do GitHub Actions. O commit que regista este resultado só altera este relatório, mantendo o mesmo código validado.

A tentativa de abrir PR em rascunho pela API GraphQL recebeu Forbidden. As alterações estão no branch remoto feat/fase-3d-novo-planear; [comparar com a base da Fase 3C](https://github.com/MxxSultane/tudoaki/compare/feat/fase-3c-novo-hoje...feat/fase-3d-novo-planear). Não houve merge.

## Compatibilidade, limitações e riscos
- Esquema SQLite v5/lifeos.sqlite, Android ID, dependências/lockfile, TaskOperations, notificações, XP/conquistas, finanças, forms.dart e contratos AppRoutes/AppDestination inalterados. Os três separadores principais e todas as áreas secundárias continuam. Não houve migrações nem acesso a dados reais.
- A entrada normal continua em Semana e o seu formulário antigo mantém o contrato anterior. A escolha semanal antiga continua limitada a pendentes sem data; nas vistas diárias o selector permite também tarefas de outros dias. Editar e reagendar por menu continuam disponíveis na semana.
- O estado das vistas é efémero na sessão. A intenção Amanhã passa por extra interno, não por um novo deep link; não se promete restauro dessa vista após terminar o processo. Tarefas guardadas continuam em SQLite.
- AgendaBrowser e os outros consumidores antigos não foram refactorizados: a política de datas UTC desses consumidores e a continuação de compromissos entre dias permanecem limitações conhecidas. O novo Planear usa agrupamento local coerente com Hoje sem alterar os registos.
- A guarda para uma tarefa eliminada concorrentemente antes de TaskOperations.edit/reschedule gravar continua fora do âmbito, como já documentado na Fase 3A. Não foi ocultada com um novo registo nem corrigida globalmente nesta fase.
- Notificações aproximadas e política Maputo permanecem. Teclado nativo, TalkBack/VoiceOver, entrega real de lembretes, compreensão por utilizadores novos e desempenho físico precisam de validação em dispositivo. Capturas e testes de widgets não certificam isso. O Android SDK continua não preparado; não foi gerado APK nesta fase.
- Não existe /plan, barra principal de quatro separadores, Percurso, IA, prazo/dia fisicamente separados, importação ou restauro. Sem merge automático; Fase 3E apenas após aprovação.
