# Fase 2C — preparação da navegação

## Origem e isolamento
Base: branch refactor/fase-2b-tarefas, commit 038c4619a70aeaea74d6ebaf42367c70dbcd115e, árvore limpa. HEAD remoto conferido igual. CI verde da base confirmado pelo utilizador; não reconsultado por API. Branch novo refactor/fase-2c-navegacao. Lidos AGENTS.md, V2_CONTRACTS.md, ARCHITECTURE.md, DESIGN_SYSTEM.md e relatórios anteriores. O pedido explícito autoriza apenas preparação da navegação, não activação visual.

## Mapa anterior, apresentado antes de modificar código
| Caminho | Destino actual | Comportamento |
| --- | --- | --- |
| / | Agenda/Hoje existente | Shell, separador 0 |
| /goals | Metas | Shell, separador 1 |
| /tasks | Tarefas | Shell, separador 2 |
| /goal/:id | Detalhe da meta | Fora do shell; ID inválido produz meta inexistente |
| /areas | Mais | Directório empilhado, sem barra inferior |
| /weekly-planner | Planear semana | Página existente, sem nova rota de planeamento |
| /progress | Progresso | Página existente |
| /habits | Hábitos | HabitsScreen |
| /academics | Estudos | TudoAkiScreen embedded |
| /finance | Finanças | TudoAkiScreen embedded |
| /reviews | Revisões | ReviewsScreen |
| /profile | Definições | SettingsScreen |

Um único GoRouter em TudoAkiApp e um ShellRoute. Sem redirect, initialLocation explícito ou StatefulShellRoute. O valor inicial implícito / permanece. Cubits mantêm selecções no shell conforme o comportamento anterior; não se acrescentou restauro ao sair/recriar o shell.

Barra usa go; Mais e suas áreas usam push. Voltar usa pop se há histórico; caso contrário go('/'). A criação abre a folha de tipos, depois showEditor; o ID guardado repõe filtro/dia e destino conforme o tipo. Edição fecha a folha mantendo a página. Esses passos não mudaram.

O Hoje legado contém um chamador /agenda que não é rota registada. Foi mantido como AppRoutes.legacyAgenda, sem criar alias ou corrigir o defeito nesta fase. O manifesto Android não declara App Links/URL schemes de entrada; a compatibilidade verificada nos testes é a dos caminhos GoRouter, não uma certificação de deep links externos no Android.

## Contratos introduzidos
AppRoutes contém todos os caminhos existentes e goalDetail(id). Os consumidores activos e legados passam a usar esses valores sem mudar os métodos go/push/pop. Nenhum novo caminho público foi registado.

AppDestination enum fornece id (nome estável do enum), path, title e icon. Renomear IDs constitui mudança do contrato. AppNavigation.currentDestinations é a única lista usada pelo shell: Agenda/Metas/Tarefas, na mesma ordem, com os mesmos ícones. TudoAkiShell.paths continua disponível como lista imutável derivada dessa ordem, agora static final em vez de const; não foram encontrados consumidores const externos no repositório.

AppNavigation.futureDestinations é apenas metadados, sem controlador, router, páginas ou flag de activação:

| Identidade | Caminho pretendido | Título / ícone | Responsabilidade futura |
| --- | --- | --- | --- |
| today | / | Hoje / today_outlined | Tarefas e compromissos do dia |
| plan | /plan, ainda não registado | Planear / calendar_month_outlined | Dia, amanhã, semana e tarefas sem data, manuais/opcionais |
| goals | /goals | Metas / flag_outlined | Metas e progresso medido |
| more | /areas | Mais / more_horiz | Hábitos, estudos, finanças, revisões, definições, progresso e outras áreas |

Hoje e Mais reutilizam caminhos existentes como intenção de compatibilidade. O nome plan e /plan são contrato preparatório; só devem ser activados com página funcional e política de compatibilidade aprovadas. Metas reutiliza o mesmo objecto de metadados nos dois contratos. Tarefas continua no separador actual; a sua localização futura em Planear/Mais deve ser especificada antes de activar a barra nova. Percurso não é criado nem imposto como destino principal.

## Ficheiros
Novos: lib/app/navigation/app_routes.dart; lib/app/navigation/app_destinations.dart; test/navigation_contract_test.dart; docs/PHASE2C_REPORT.md.
Modificados: lib/app/app.dart; lib/core/widgets/workspace_page.dart; lib/features/areas/presentation/areas_screen.dart; lib/features/agenda/presentation/daily_summary.dart; lib/features/agenda/presentation/today_screen.dart; lib/features/goals/presentation/goals_screen.dart; lib/features/weekly_planner/presentation/weekly_planner_screen.dart; lib/features/settings/presentation/settings_screen.dart; lib/features/progress/progress_screen.dart; lib/features/screens.dart; docs/ARCHITECTURE.md; .github/workflows/flutter-validation.yml.

As alterações nos componentes secundários são apenas imports e substituição de caminhos por expressões equivalentes; não modificam a sua estrutura visual. O workflow só inclui o branch novo em push; critérios, comandos e versões mantidos.

## Testes acrescentados
Seis testes de widgets com SQLite em memória e o GoRouter real:
1. Caminhos, rótulos, ícones e índices dos três separadores; selecção da agenda preservada ao alternar destinos.
2. Mais → sete áreas existentes → Voltar; recuperação do separador Tarefas de origem.
3. Entrada directa nos caminhos secundários e detalhes, fallback Voltar para /, parâmetro inválido e query string de Tarefas.
4. Regresso pelo RouterDelegate usado no back do sistema, respeitando a pilha de áreas.
5. Contrato dos quatro destinos futuros, navegação nos três destinos já implementados com dados reais e confirmação de que /plan não tem correspondência no router.
6. Fluxo existente + → Tarefa → Guardar → editar, mantendo ID, dados opcionais e destino, sem XP.

Não são apenas testes de constantes: abrem páginas e formulários, lêem dados persistidos e exercitam go/push/back no router. Nenhum teste antigo foi alterado.

## Resultados desta fase
- Dart SDK oficial 3.9.2: formatação aplicada e verificação read-only lib/test aprovada, 71 ficheiros, 0 alterações na segunda passagem. Aviso de flutter_lints não resolvido por falta de dependências locais; não equivale a análise estática.
- flutter analyze --no-pub e flutter test --no-pub tentados: ambos falharam no bootstrap com código 1, HTTP 403 de storage.googleapis.com. Zero testes Flutter executados localmente nesta fase; seis novos ainda sem execução confirmada.
- YAML e scripts shell do workflow verificados; git diff --check aprovado.
- Comparação lexical contra a base, descontando formatação/vírgulas finais e repondo os mesmos literais: componentes secundários equivalentes; em app.dart só caminhos e a construção da mesma barra a partir dos metadados foram alterados. Um GoRouter e um ShellRoute mantidos.
- Diff vazio nas operações de tarefas 2B, forms.dart, providers.dart, SQLite, Android, dependências, finanças, tema, notificações e implementação académica. Testes antigos intactos.
- Assinatura de RouteConfiguration.findMatch(Uri) conferida na fonte pública oficial go_router-v16.3.0 para o teste de /plan. Isto não substitui a execução da suite.

## Riscos e revisão
Aguardar CI deste branch antes de integrar; verde da base não valida esta entrega. A API GitHub estava indisponível por autenticação nas fases anteriores; tentar criar PR, sem merge automático. Não se declara suporte novo a App Links nem restauro de estado entre processos. Alterar futuramente os IDs ou caminhos requer rever compatibilidade, navegação directa, queries, voltar e acesso a Tarefas. O defeito legado /agenda permanece deliberadamente sem correcção.

## Recomendação para a primeira implementação visual
Primeiro aprovar o desenho e a localização de Tarefas, a política de compatibilidade dos caminhos e o destino funcional Planear. Validar protótipos com utilizadores novos e contraste/tema escuro antes de aplicar a paleta. Uma fase visual pequena poderá activar os quatro destinos com funcionalidades reais, conservando os caminhos antigos necessários e a mesma fonte de dados; não ligar /plan a uma página vazia. Nenhuma dessas alterações foi iniciada nesta fase. Aguardar aprovação explícita.
