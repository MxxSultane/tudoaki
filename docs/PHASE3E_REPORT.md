# Fase 3E — navegação

Base: 7dcf3d2cb63cad7a652916d22de4ee7d7071f9c2, árvore limpa, Fase 3D validada (176 testes, CI 42797643915). Branch feat/fase-3e-navegacao-2.

## Mapa e decisão antes de implementar
Consumidores inspeccionados: app.dart, AppRoutes/AppDestination, WorkspacePage, TodayScreen, AreasScreen, PlanningScreen, forms e testes de navegação/aplicação/planeamento. Contratos V2, Design System e relatório 3D consultados.

| Antes | Depois |
| --- | --- |
| / — Agenda/TodayScreen | / — Hoje, primeiro ramo |
| /goals — Metas | Mesmo caminho/ecrã, terceiro ramo |
| /tasks — separador Tarefas | Mesmo caminho/lista, página do ramo Mais; acesso por Mais e Planear |
| /areas — área empilhada | Mais, quarto ramo principal |
| /plan — não registada | Segundo ramo, PlanningScreen existente; primeira visita Hoje |
| /weekly-planner | Mantida fora da barra; Semana por defeito e extra legado preservado |
| /goal/:id, /habits, /academics, /finance, /reviews, /profile, /progress | Mantidas como páginas secundárias, Voltar pela pilha/fallback / |
| Agenda completa dentro de Hoje | Preservada; Mais acrescenta /calendar reutilizando AgendaBrowser |
| /agenda não registada | Continua não registada; não corrigir defeito legado |

StatefulShellRoute.indexedStack mantém quatro navigators e os widgets activos entre separadores. A escolha justifica-se pelo estado real de Planear; um ShellRoute simples recriava páginas. Não há outro router nem store de tarefas. Cubits existentes ficam acima do router, preservando selecções também nas páginas compatíveis. Pedidos contextuais tipados são efémeros e não criam query parameters públicos. As folhas existentes podem abrir nos navigators dos ramos. ModalNavigationGuard observa PopupRoute e bloqueia a barra/oculta o FAB até fechar a folha; não foi necessário alterar forms.dart. Pop de páginas/formulários tem prioridade sobre regressar ao Hoje.

## Resultados
Flutter 3.35.7 / Dart 3.9.2, ferramentas preservadas. Resultados locais observados após a última correcção:
- flutter analyze --no-pub: código 0, sem problemas.
- flutter test --no-pub --reporter expanded: código 0, **180 aprovados, 0 falhados**, 80 segundos (176 anteriores ajustados ao contrato + quatro casos novos).
- dart format --output=none --set-exit-if-changed lib test tool/capture_navigation.dart: código 0, 93 ficheiros, zero alterações.
- flutter test --no-pub tool/capture_navigation.dart: código 0, duas renderizações reais, fora da contagem da suite normal.
- git diff --check e comparação das áreas protegidas: aprovados.

Os testes detectaram e protegeram dois casos de integração: barra/FAB disponíveis durante folhas de ramo e prioridade de Voltar sobre páginas empilhadas. Ambos corrigidos na camada de navegação, sem mudar regras de negócio. CI pendente de resultado observado. Sem merge ou Fase 3F.

## Implementação e compatibilidade
A barra segue Sage/Graphite com os quatro ícones/rótulos sempre visíveis. StatefulShellRoute conserva os estados vivos; repetir um separador não repõe Planear. Mais em /tasks regressa ao directório, sem empilhar cópias. /tasks pertence ao navigator de Mais, mantendo filtros e formulário completo. Mais também oferece Agenda completa em /calendar, reutilizando AgendaBrowser e a criação existente. Nenhum builder foi criado para /agenda.

PlanningRequest dá identidade a cada pedido explícito de Amanhã/Semana; PlanningScreen usa didUpdateWidget para aplicar só um pedido novo, sem perder a vista ao alternar separadores. /plan abre Hoje na primeira visita; /weekly-planner mantém Semana e o extra PlanningView legado. Não há query parameters novos nem segundo planeador. Todas as tarefas continuam a referir os mesmos IDs SQLite.

Voltar: páginas secundárias e rotas modais são retiradas primeiro; num destino principal sem pilha regressa ao Hoje. Entradas directas secundárias usam o fallback / existente. Formulários abertos bloqueiam navegação para preservar rascunhos. A selecção é mantida enquanto o shell existe; não se promete restauro após encerrar o processo.

## Ficheiros alterados
- app/app.dart: único router, quatro ramos, Cubits partilhados e integração visual/barra/Voltar.
- app/navigation/app_routes.dart e app_destinations.dart: /plan, /calendar e destinos activos; enum legada preservada.
- app/navigation/modal_navigation_guard.dart: observação de folhas sem mudar formulários.
- core/widgets/workspace_page.dart e features/agenda/presentation/today_screen.dart: retirar ligações Mais redundantes e encaminhar pedidos contextuais ao destino principal.
- features/areas/presentation/areas_screen.dart: Tarefas/Agenda completa e FAB opcional na área de calendário.
- features/planning/domain/planning_view.dart e presentation/planning_screen.dart: pedido efémero e acesso Todas as tarefas.
- test/navigation_v2_test.dart e support/navigation_access.dart: cobertura nova e acesso de teste pelo menu real.
- tool/capture_navigation.dart e docs/ux/previews/phase3e: duas capturas reais com a barra.
- workflow Flutter validation: apenas acrescentar este branch ao trigger push.
- este relatório, ARCHITECTURE.md e DESIGN_SYSTEM.md: contratos e resultados.

## Cada teste anterior ajustado
| Ficheiro | Alteração justificada pelo contrato aprovado |
| --- | --- |
| app_test.dart | Quatro destinos; Hoje substitui Agenda; Tarefas pelo menu real; regresso de Mais pela barra. Persistência, reabertura nativa, métricas e XP conservados. |
| navigation_contract_test.dart | Novos índices/ícones/rotas, Mais principal sem toolbar Voltar, /plan agora registada e /tasks seleccionado em Mais. Cobertura das áreas, IDs, edição e Cubit conservada. |
| phase1_task_flows_test.dart | Contagem da barra e entrada de Tarefas substituídas. Todos os critérios de gravação/cancelamento/conclusão permanecem. |
| planning_screen_test.dart | Só o primeiro percurso de Hoje passa a /plan e regressa pela barra; /plan deixa de ser proibida. Casos do planeador legado e persistência intactos. |
| today_screen_test.dart | Separadores/entrada das tarefas e regresso do novo Planear pela barra; distinguir cabeçalho Hoje do rótulo Hoje. Contagem de hábitos permanece três. |
| weekly_planner_widget_test.dart | Segundo Voltar do directório antigo substituído pelo separador Hoje; formulário semanal, identidade, precisão e navegação da semana conservados. |

Nenhum teste de esquema, finanças, XP, TaskOperations ou notificações foi enfraquecido ou eliminado.

## Novos testes e capturas
Quatro casos novos verificam: os quatro destinos e mesma instância de Planear após alternância; primeira entrada Hoje/última vista; pedidos Amanhã/Semana repetidos; protecção do rascunho e gravação única; retorno Android ao Hoje e prioridade do pop de Hábitos/Tarefas; Agenda completa; /tasks e /agenda; claro/escuro, 360 px, texto 200% e área segura. A suite anterior continua a cobrir metas/detalhes, associações, criação/edição, XP, lembretes e dados.

Capturas reais Flutter/RepaintBoundary com SQLite sintético, 390 × 844, PNG 2×; sem imagens conceptuais ou certificação física. Reproduzir: source tool/env.sh; flutter test --no-pub tool/capture_navigation.dart.
- [Claro](ux/previews/phase3e/navigation-today-light.png)
- [Escuro](ux/previews/phase3e/navigation-today-dark.png)

## Limites
SQLite v5, lifeos.sqlite, Android ID, dependências/lockfile, TaskOperations, XP, notificações, finanças e forms.dart mantidos. Sem migração, restauro, Percurso, IA ou novas funções de metas. Dados de teste apenas sintéticos. /agenda continua defeito legado; limites de calendário/concorrência registados em 3D não foram corrigidos.

Teclado físico, TalkBack/VoiceOver, comportamento específico dos fabricantes Android, entrega de lembretes e desempenho físico continuam não verificados. Testes de handlePopRoute e área segura são simulações Flutter. Não foi produzido APK: Android SDK não preparado. Sem merge; 3F exige revisão/aprovação.
