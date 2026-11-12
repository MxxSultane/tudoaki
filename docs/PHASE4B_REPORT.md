# Fase 4B — funcionalidade e simplificação

## Referência e âmbito

HEAD inicial confirmado: `f3ff7a96647ce0d1d76c7f71d70627c7f88e6a10`; branch `fix/fase-4b-funcional-simplificacao`; árvore limpa. Não havia alterações do utilizador para conciliar. Lidos AGENTS.md, V2_CONTRACTS.md, DESIGN_SYSTEM.md e relatórios 3B–4A. A autorização explícita 4B prevalece sobre as restrições históricas a fases futuras. Sem merge ou implementação da Fase 4C.

## Causa comprovada: criação de hábitos

A rota `/habits` abre AreaScaffold sem FAB, com HabitsScreen embebido. O único acesso a showEditor('Hábito') era legacyEmpty, condicionado a `Habits.isEmpty`. Depois da primeira gravação, a invalidação de dataProvider actualizava correctamente a lista e retirava precisamente esse acesso. O editor, o INSERT sem ID, o provider e a navegação não impõem um limite de um hábito. A investigação não encontrou motivo para mudar persistência, esquema ou atribuição de XP.

O teste de regressão corrigido percorre Mais → Hábitos, cria três títulos distintos, edita o primeiro sem trocar ID, conclui/reabre/conclui, sai e volta à área. Na base anterior, falha por ausência de «Criar hábito» depois da primeira gravação nos quatro casos claro/escuro × 100/200%. Uma versão inicial do teste procurava TextButton por tipo exacto, incompatível com TextButton.icon; corrigiu-se o finder para o texto antes de repetir a reprodução contra o código original. Não se usou essa falha inicial como prova do defeito.

Correcção limitada: apresentar «Criar hábito» também quando há registos, reutilizando showEditor. A criação vazia existente fica intacta. Gravar e editar continuam a usar o repositório e a invalidação existentes; conclusão continua por toggleHabit. Teste adicional fecha realmente uma base SQLite temporária sintética, abre uma nova ligação e compara hábitos, conclusões e eventos de XP. Três IDs distintos; criar/editar não atribui XP; concluir repetidamente preserva os 5 XP únicos por hábito/dia.

## FAB de Metas

O FAB do shell em `/goals` abre directamente o editor Meta compacto existente. Depois de guardar selecciona Activas através de GoalsCubit, para mostrar a meta criada mesmo se antes se consultavam Alcançadas. Não empilha outra rota. Cancelar não grava nem muda o filtro. O selector global Evento/Tarefa/Meta, as entradas de detalhe e os restantes pontos de criação não foram substituídos. Teste abre o FAB, verifica Editor.kind == Meta e grava pela persistência real.

## Apresentação inicial da criação rápida

Mantém QuickTaskSheet e o rodapé responsivo 4A. Sem título, a folha apresenta cabeçalho/Cancelar, Título, dia opcional, associações herdadas quando existirem, Mais opções e Guardar. A acção secundária «Guardar e adicionar outra» surge assim que há um título não vazio ou quando se abrem as opções. Continua disponível antes da primeira gravação válida; depois de guardar outra, volta a surgir ao escrever o título seguinte. Não se acrescentou um passo para quem cria em sequência.

Este é um ajuste de visibilidade, sem reconstruir formulário nem alterar _save, validação, TaskOperations, lembretes, datas, prioridade, importância, associações, descarte ou contexto herdado. Abrir Mais opções sem título também permite descobrir a acção secundária desactivada. Os testes antigos da Fase 3B e a matriz 4A permanecem intactos.

## Auditoria e proposta para metas — sem implementação

Hoje, o editor compacto exige título, horizonte, unidade e alvo; o prazo está nas opções. O modelo já guarda title, due, initial, target, current, unit, status, created, description, category e parent_id. GoalProgress regista os avanços; etapas e tarefas associadas são independentes da métrica.

Proposta 4C para **novas metas**: nome obrigatório; prazo opcional expresso como número inteiro de dias; opções progressivas para a métrica e restantes campos. Ao guardar, converter os dias numa data civil explícita calculada a partir do dia local de criação, mostrando previamente a data resultante. Sem prazo grava NULL. Não usar «dias restantes» como valor persistido, pois mudaria ao reabrir. Definir antes da implementação se 1 dia significa amanhã, limites permitidos, tratamento de zero e fuso; recomendação: inteiro positivo, 1 = amanhã, intervalo validado contra o selector de datas existente.

Para uma meta sem métrica escolhida, propor 0–100, unidade %, e actualização manual explícita pelo mecanismo de progresso existente. Não inferir avanço pelo tempo decorrido nem por tarefas/hábitos. Preservar o editor de métricas e etapas para quem precisa de livros, valores ou outras unidades. Validar arredondamento, retrocesso, conclusão/reabertura e idempotência antes de aprovar esta opção.

**Metas antigas:** não converter métricas nem reescrever due. Mostrar os valores existentes e permitir editar só campos escolhidos, preservando ID, created, horizonte, categoria, descrição, hierarquia, histórico, initial/current/target/unit/status e relações. Uma data ISO antiga conserva a sua precisão se não for alterada; não converter uma data histórica para uma nova contagem de dias. Manter acesso ao editor completo. O esquema v5 já suporta a proposta básica; qualquer necessidade adicional exigiria contrato e migração aditiva separados. Não tocar em SavingsGoals/finanças nem unificar os dois tipos de meta.

## Auditoria visual dos ecrãs reais — propostas para 4C

Capturas do renderer Flutter, com fixtures sintéticas constantes, em `docs/ux/previews/phase4b/before/`. Observação directa das imagens, complementada pela leitura dos componentes activos:

| Área | Observação no ecrã real | Proposta sem perder funções |
| --- | --- | --- |
| Estudos | Introdução, duas acções e texto de XP ocupam o topo; o cartão de sessão divide largura entre texto e três ícones; disciplinas surgem abaixo de várias secções. | Priorizar sessão em curso/próximo estudo e uma acção Planear estudo. Tornar XP uma informação discreta; recolher avaliações, trabalhos e disciplinas em secções expansíveis com contagem e acesso explícito às acções actuais. Preservar foco/retoma, avaliações, disciplinas e Adicionar trabalho com associação. |
| Finanças | Selector de moeda, explicação longa, mês, resumo com cinco linhas e duas acções antecedem orçamentos e recorrências; títulos/acções disputam largura. | Resumo compacto de saldo/receitas/despesas com mês e moeda sempre visíveis; Registar movimento principal; detalhes, poupanças, orçamentos e recorrências progressivos. Manter aviso de ausência de conversão cambial, precisão em cêntimos, confirmação das recorrências e acesso a todas as moedas/histórico. |
| Progresso | AppBar e conteúdo repetem Progresso; contagens/XP precedem sete linhas diárias mesmo vazias; conquistas ficam no fim. | Um cabeçalho, síntese curta e actividade semanal com alternativa textual; detalhes diários e conquistas expansíveis. Respeitar gamificação desligada, descanso e distinção entre actividade actual e reconhecimento histórico. Não fabricar uma linha temporal a partir de XP. |
| Metas | Já há hierarquia simples: título, Activas/Alcançadas e cartões com título, horizonte/área e progresso. O formulário requer conceitos de métrica cedo. | Conservar a lista; reduzir metadados secundários no primeiro nível e destacar próximo passo/prazo quando existente. Nome/dias opcionais no novo formulário conforme proposta acima; opções mantêm horizonte, métricas e hierarquia. O único ajuste implementado aqui é o FAB directo. |

Estes módulos não foram redesenhados. Antes de 4C: validar propostas com pessoas novas; protótipos claro/escuro, 320/360 px, texto 200%, leitura de ecrã, teclado e alvos 48 dp. Não há aprovação implícita para iniciar essa fase.

## Ficheiros

- `lib/features/habits/presentation/habits_screen.dart`: acesso de criação na lista preenchida.
- `lib/app/app.dart`: FAB contextual de Metas, editor existente e filtro após guardar.
- `lib/features/tasks/presentation/quick_task_sheet.dart`: visibilidade progressiva da acção secundária.
- `test/phase4b_test.dart`: sete novos casos, com SQLite real sintético.
- `tool/capture_quality.dart`: cenários de folha inicialmente vazia e criação de meta; modo explícito de captura do selector anterior.
- `.github/workflows/{flutter-validation,android-debug-validation}.yml`: só acrescentar este branch aos disparos push.
- `docs/ux/previews/phase4b/` e este relatório: evidência/entrega.

## Capturas reais antes/depois

Não são maquetas nem imagens geradas. Flutter test + RepaintBoundary, ícones/fontes reais, dimensões lógicas 390×844; teclado/200% em 360×800. Imagens a pixelRatio 2. As capturas de auditoria e da folha preenchida usam os mesmos dados/relógio anteriores. A folha vazia anterior foi renderizada com o ficheiro original da base; a captura do selector anterior usa a função global existente, equivalente ao callback anterior do FAB. O depois usa o FAB real.

| Caso | Antes | Depois |
| --- | --- | --- |
| Hábitos preenchidos claro | [Antes](ux/previews/phase4b/before/habits-light.png) | [Depois](ux/previews/phase4b/after/habits-light.png) |
| Hábitos preenchidos escuro | [Antes](ux/previews/phase4b/before/habits-dark.png) | [Depois](ux/previews/phase4b/after/habits-dark.png) |
| Folha inicial clara | [Antes](ux/previews/phase4b/before/quick-empty-light.png) | [Depois](ux/previews/phase4b/after/quick-empty-light.png) |
| Folha inicial escura | [Antes](ux/previews/phase4b/before/quick-empty-dark.png) | [Depois](ux/previews/phase4b/after/quick-empty-dark.png) |
| FAB Metas claro | [Antes](ux/previews/phase4b/before/goals-create-light.png) | [Depois](ux/previews/phase4b/after/goals-create-light.png) |
| FAB Metas escuro | [Antes](ux/previews/phase4b/before/goals-create-dark.png) | [Depois](ux/previews/phase4b/after/goals-create-dark.png) |
| Folha preenchida, teclado/200% | [Antes](ux/previews/phase4b/before/quick-keyboard-200-light.png) | [Depois](ux/previews/phase4b/after/quick-keyboard-200-light.png) |

Também incluídos quick-light/dark e quick-keyboard-200-dark para comparação de preservação. Capturas de Estudos, Finanças, Progresso e Metas são auditoria; o depois mantém os mesmos módulos.

## Validação

Flutter 3.35.7 / Dart 3.9.2 / Java 21, ferramentas preparadas preservadas. Formatação: 97 ficheiros, zero alterações pendentes. Análise final: sem problemas, código 0. Nove testes do processador Python aprovados; YAML, bash e git diff --check aprovados. Comparação directa com a base nas áreas protegidas sem diferenças.

A primeira execução Flutter precisou de XDG_CONFIG_HOME num directório gravável do workspace. A primeira análise incluiu cópias temporárias Dart usadas para renderizar a base e um aviso de chavetas no utilitário; retiraram-se as cópias da árvore analisada e corrigiram-se as chavetas. O primeiro comando unittest Python usou um caminho de importação inadequado; a execução directa do script passou. Estas falhas de preparação não foram contadas como validações aprovadas.

Suite completa: **254 executados, 254 aprovados, 0 falhados, 0 ignorados e 0 erros de execução**, runner código 0 e processador código 0; 247 anteriores intactos + sete novos. Duração observada: 339 segundos, com compilação Android concorrente. Os 28 PNG antes/depois foram produzidos por execuções de captura aprovadas, fora da contagem da suite.

Comandos: `source tool/env.sh`; `export XDG_CONFIG_HOME=/workspace/.tools/config`; `dart format --output=none --set-exit-if-changed lib test tool/capture_quality.dart`; `flutter analyze --no-pub`; `flutter test --no-pub --machine`; `python3 tool/summarize_flutter_tests.py <jsonl> <summary>`; `python3 tool/test_summarize_flutter_tests.py`; `flutter build apk --debug --no-pub`.

Capturas: `flutter test --no-pub tool/capture_quality.dart --dart-define=QUALITY_OUTPUT=docs/ux/previews/phase4b/after --name 'quick-empty|quick-light|quick-dark|quick-keyboard-200|habits-light|habits-dark|goals-light|academics-light|finance-light|progress-light|goals-create'`. O selector anterior usa `--dart-define=QUALITY_GOAL_SELECTOR=true --name goals-create` e saída before; as restantes imagens before foram geradas com a base original correspondente. Não sobrescrever capturas históricas.

O primeiro build local falhou após 381,8 s: «Gradle build daemon disappeared unexpectedly». O cgroup de 8 GiB registou oom=1/oom_kill=1 e o daemon usava o limite -Xmx8G do projecto. Repetição com limite de 3 GiB/1 GiB de metaspace, dois workers e compilador Kotlin no processo, apenas no GRADLE_USER_HOME local; android/gradle.properties preservado. Repetição local **aprovada**, código 0, 103,3 s; APK não vazio em build/app/outputs/flutter-apk/app-debug.apk. Não houve novo oom_kill. Sem distribuição do APK. O manifesto do APK foi inspeccionado com aapt: `mz.lifeos.lifeos`, versão 0.9.2+12, preservados. APK SHA-256 local: `605ffe49236436aea350bb2381acb31fb0ea6acd1de187649f4a1d7bb3258439`.

### GitHub Actions

Implementação publicada no commit `038c0ce285c94e59dfa7178e88671d4507c1b54f`, no branch autorizado, sem merge. `gh auth status` falhou neste ambiente; o push Git funcionou e a API foi consultada pelo conector GitHub, com os resultados observados directamente. Não foi preciso alterar credenciais nem workflows para contornar falhas.

| Workflow | Execução | Resultado |
| --- | --- | --- |
| Flutter validation | [43290473342](https://github.com/MxxSultane/tudoaki/actions/runs/43290473342) | COMPLETED / SUCCESS |
| Android debug validation | [43290473515](https://github.com/MxxSultane/tudoaki/actions/runs/43290473515) | COMPLETED / SUCCESS; compilação e preservação aprovadas |

A contagem 254 é local, obtida do JSON machine e do processador, não inferida da CI. O commit documental de entrega apenas consolida estes resultados, preservando o código, testes, capturas e workflows validados. Não se pediu disponibilização de APK nem se alterou o critério de upload anterior.

## Preservação, riscos e limitações

Sem alterações em Agenda/Tarefas, esquema SQLite v5, lifeos.sqlite, Android/applicationId, dependências/lockfile, TaskOperations, regras XP/conquistas, finanças, serviços ou navegação principal. Nenhuma operação sobre dados reais. Os testes de reabertura usam exclusivamente ficheiro temporário sintético.

A apresentação da acção secundária muda quando o título passa de vazio a preenchido; verificar essa descoberta com utilizadores e teclado real. Não existe limite de hábitos introduzido nesta entrega; listas extensas continuam deslocáveis. Não há nova validação de títulos duplicados, porque a aplicação permite títulos iguais e o pedido exige vários hábitos distintos, não uma nova regra de unicidade.

Capturas/testes de widget não certificam IME nativo, TalkBack, notificações reais, ciclo de vida Android, assinatura ou actualização de instalação existente. Não foi testado em telefone físico. Recomenda-se validar estes pontos num perfil de testes separado e rever a proposta de metas antes de autorizar 4C. Não desinstalar uma aplicação com dados para contornar incompatibilidade de assinatura debug.
