# Fase 2A — extracção segura

## Base e isolamento
Branch inicial prep/tudo-aki-2-fase-1, commit 6d8f2916f541f50b78b082bd7af366dd2a842d58, árvore limpa. HEAD remoto conferido igual ao local. CI verde desta base informado pelo utilizador; não foi reconsultado por API. Branch novo: refactor/fase-2a-modulos-antigos. Lidos AGENTS.md e V2_CONTRACTS.md; o pedido explícito desta fase autoriza a extracção estrutural e substitui a limitação anterior da Fase 1.

## Antes e depois
Antes: screens.dart reunia habits/habitCards, reviews e profile, além de Hoje/Agenda/Metas/Progresso, tarefas e integração académica/financeira. app.dart encaminhava as áreas para TudoAkiScreen.

Depois, por ordem de extracção:
1. features/habits/presentation/habits_screen.dart: HabitsScreen e buildHabitCards.
2. features/reviews/presentation/reviews_screen.dart: ReviewsScreen.
3. features/settings/presentation/settings_screen.dart: SettingsScreen, mantendo o título legado Perfil quando não embedded.
4. core/widgets/legacy_section_page.dart: LegacySectionPage, LegacyAction, LegacySectionBuilder, legacyHeading e legacyEmpty, reproduzindo composição/lista, carregamento/erro, cabeçalho opcional, estilos e acções anteriores.

Não havia classes independentes das três áreas; foram extraídos métodos/conteúdo para widgets próprios. Os helpers heading/empty antigos continuam em screens.dart para evitar alterações às outras áreas. A sua reprodução no suporte das áreas extraídas mantém dependências unidireccionais: os módulos novos não importam screens.dart.

## Referências
- app.dart importa os três widgets e usa-os em /habits, /reviews e /profile. Rotas, títulos, AreaScaffold, Voltar e barra principal inalterados.
- TudoAkiScreen delega Hábitos/Revisões/Perfil para os widgets novos, preservando embedded e os consumidores antigos.
- Hoje antigo chama buildHabitCards com o mesmo repositório e act, incluindo o filtro todayOnly. A lógica diária tem uma só implementação.
- Os imports existentes de screens.dart em academics_widget_test, finance_widget_test, currency_widget_test e goal_planning_widget_test continuam válidos. Não foram removidos métodos de Agenda/Metas/Progresso ou MetricDialog. showQuickCreate e dateLabel mantidos.
- forms.dart, operações SQLite, partilha JSON, cancelAll antes de erase, regras monetárias e de XP não mudaram.
- Workflow inclui o branch novo nos disparos push, mantendo os mesmos comandos/versões e sem deploy.

## Cobertura
Antes: app_test verifica abertura das seis áreas por Mais e regresso à barra; currency_widget_test verifica a preferência de moeda através da entrada antiga Perfil; repository_test/progress_test verificam persistência, hábitos/XP/conquistas. Faltavam percursos completos por Mais de registo de hábitos e criação/consulta de revisões.

Acrescentados três casos em legacy_modules_test.dart:
- Mais → Hábitos: visualizar activos/pausados, marcar/desmarcar/remarcar, uma conclusão diária e uma atribuição de 5 XP, mesmas linhas de hábitos ao reabrir.
- Mais → Revisões: preencher quatro respostas, guardar, sair/voltar e consultar as respostas, mesmo registo, sem XP.
- Mais → Definições: tema, moeda e gamificação, sair/voltar, manter preferências e histórico de XP/tarefas.

Testes antigos e respectivos critérios não foram alterados. O defeito conhecido de criar segundo hábito permanece: não foi introduzida uma nova entrada nem tornado requisito desejado.

## Verificação nesta fase
- Dart SDK oficial 3.9.2 disponível: formatação dos sete ficheiros Dart criados/modificados e verificação read-only de lib/test aprovadas (65 ficheiros, 0 alterações na segunda passagem). Aviso de flutter_lints não resolvido por falta de dependências; não equivale a análise Flutter.
- flutter analyze --no-pub e flutter test --no-pub tentados: ambos código 1, bootstrap bloqueado por HTTP 403 do proxy no download do SDK em storage.googleapis.com. Não chegaram a analisar nem carregar testes. Zero testes Flutter executados localmente nesta fase; os três novos não têm aprovação local.
- Comparação lexical com 6d8f291, ignorando formatação/vírgulas finais: corpos extraídos de hábitos/revisões/definições preservados após substituição de nomes de helpers e passagem de contexto/repositório. Métodos de Agenda, Metas, Progresso, taskCard, métricas e helpers antigos preservados.
- Diff vazio em base/esquema SQLite, android/, dependências, forms.dart, finanças, progresso, tema e notificações. git diff --check aprovado. Nenhuma base de dispositivo aberta ou migração executada.
- Sintaxe YAML e scripts shell do workflow verificados localmente. Análise/testes desta extracção precisam de CI; o sucesso anterior não valida estas alterações.

## Ficheiros
Modificados: lib/features/screens.dart, lib/app/app.dart, .github/workflows/flutter-validation.yml e docs/ARCHITECTURE.md.
Criados: lib/features/habits/presentation/habits_screen.dart, lib/features/reviews/presentation/reviews_screen.dart, lib/features/settings/presentation/settings_screen.dart, lib/core/widgets/legacy_section_page.dart, test/legacy_modules_test.dart e docs/PHASE2A_REPORT.md.

## Riscos e revisão
Ausência de validação Flutter local; aguardar análise e suite na CI antes de integrar. O wrapper de compatibilidade mantém chamadas antigas; a extracção adiciona uma camada de composição sem intenção de alterar layout ou fluxo. Confirmar também estados preenchidos/erro e teclado num dispositivo. Limitações conhecidas e defeitos auditados permanecem deliberadamente intactos. Não se assume equivalência visual apenas por comparar tokens.

Sem alterações funcionais intencionais. Esquema v5, mz.lifeos.lifeos, lifeos.sqlite, dados, XP, conquistas e design preservados. Fase 2B/3 não iniciadas; aguardar revisão e aprovação, sem merge automático.
