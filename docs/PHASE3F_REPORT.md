# Fase 3F — integração, regressão e qualidade

## 1. Referência inicial

Branch de origem: `feat/fase-3e-navegacao-2`. HEAD inicial: **efd8ad7757aa8a5d9db3a6cd32d4c83ac5ee0373**, árvore limpa. O commit de implementação 3E **f9d2e09243f5780ea77494164bc2e2c05807abcd** tem [CI 42971075627 aprovada](https://github.com/MxxSultane/tudoaki/actions/runs/42971075627); o HEAD documental tem [CI 42971662816 aprovada](https://github.com/MxxSultane/tudoaki/actions/runs/42971662816). Ambos os resultados foram observados, sem inferir contagens dos logs remotos.

Branch de trabalho: **qa/fase-3f-integracao**. A matriz inicial foi registada antes de correcções. Foram consultados AGENTS.md, V2_CONTRACTS.md, DESIGN_SYSTEM.md, relatórios 3B–3E e os contratos HOJE_PLANEAR_SPEC/IMPLEMENTATION. A autorização desta fase é QA e correcção de defeitos de integração demonstrados; não substitui a aprovação necessária para fases futuras.

A suite dos ficheiros de teste presentes no HEAD inicial foi executada isoladamente: **180 aprovados, 0 falhados**, código 0, cerca de 84 segundos. Os testes novos não estavam incluídos nessa execução.

## 2. Matriz de funcionalidades e navegação

Existe um único GoRouter em `lib/app/app.dart`, com `StatefulShellRoute.indexedStack`: Hoje `/`, Planear `/plan`, Metas `/goals`, Mais `/areas` e `/tasks` no quarto ramo. Rotas secundárias usam o navigator root. A selecção efémera permanece nos Cubits e os dados no provider partilhado. Não foi introduzido outro sistema de navegação.

As referências abaixo são testes de comportamento executados na suite inicial, complementados pelos novos casos 3F. «Directa» significa `router.go` em teste Flutter; não certifica Android App Links/intents.

| Fluxo / função | Rotas / componentes | Evidência de verificação | Limite |
| --- | --- | --- | --- |
| Arranque, Hoje vazio/preenchido, compromissos, tarefas e hábitos | `/`, TodayScreen | `today_screen_test.dart`, `today_content_test.dart`; capturas reais | Sem relógio/dispositivo Android real |
| Hoje → Planear, amanhã e semana | `/plan`, PlanningRequest | `navigation_v2_test.dart`, `planning_screen_test.dart`: entradas contextuais e mesma instância | Pedido interno, sem nova URL pública |
| Planear → Hoje/Metas e alternância repetida | Quatro ramos do shell | `navigation_v2_test.dart`: conserva instância e modo Sem data; repetição de selecção | Não é teste prolongado de memória/centenas de ciclos |
| Dia, amanhã, semana, sem data | PlanningScreen/WeeklyPlannerScreen | `planning_screen_test.dart`, `weekly_planner_widget_test.dart`, capturas dos quatro modos | Sem nova lógica de planeamento |
| Metas → detalhe → regressar | `/goals`, `/goal/:id` | `app_test.dart`: criação real de meta/tarefa ligada/progresso; `navigation_contract_test.dart` | Metas não foi redesenhado |
| Mais → Tarefas → regressar | `/areas` → `/tasks` | `navigation_v2_test.dart`: Voltar Android simulado e regresso; testes 3F do mesmo ID | Reseleccionar Mais volta ao directório, por contrato existente |
| Mais → Hábitos/Estudos/Finanças/Progresso/Revisões/Definições | `/habits`, `/academics`, `/finance`, `/progress`, `/reviews`, `/profile` | `navigation_contract_test.dart`: abre cada área e toolbar Voltar; `app_test.dart`, `legacy_modules_test.dart` e suites funcionais | Não houve gesto físico em cada área |
| Mais → Agenda completa | `/calendar`, AgendaBrowser | `navigation_v2_test.dart`: abre períodos/FAB e volta ao directório | Fallback de entrada directa em `/calendar` não ensaiado isoladamente |
| Mais → Planear semana legado | `/weekly-planner` | `navigation_contract_test.dart`, `weekly_planner_widget_test.dart` | Mantém entrada secundária funcional |
| Entradas directas antigas | `/tasks?source=legacy`, `/areas`, `/weekly-planner`, áreas secundárias e `/goal/:id` | `navigation_contract_test.dart`: conteúdo, parâmetro inválido e fallback para Hoje; `/tasks` selecciona Mais | `/agenda` continua não registada; ver riscos |
| Voltar de destino principal e de área empilhada | BackButtonListener/GoRouter | `navigation_v2_test.dart`, `navigation_contract_test.dart`: handlePopRoute/RouterDelegate | Gesto do SO/predictive back não executado |
| Retorno de criação/edição completa | Editor, resultado legado para Tarefas | `navigation_contract_test.dart`, `app_test.dart`, novos testes 3F | Mantém o destino e os campos existentes |
| Retorno de criação rápida e folhas aninhadas | QuickTaskSheet/ModalNavigationGuard | `today_screen_test.dart`, `planning_screen_test.dart`, `phase3f_modal_test.dart` | Lembretes nativos são simulados |
| Identidade e dados entre os três ecrãs | TaskOperations/SQLite em memória/dataProvider | `phase3f_task_journey_test.dart`: três percursos completos | Sem dados reais nem migrações |

Os testes cobrem reutilização de instâncias, push/pop e ciclos de abertura/fecho sem bloqueio residual. Não provam a ausência de todas as fugas de memória ou todas as combinações possíveis de pilhas.

## 3. Defeitos reproduzidos e correcções

Não foi confirmado um novo defeito funcional atribuível à integração 3E que justifique alterar produção. A análise estática e os testes não substituem validação em dispositivo.

A primeira execução dos sete testes novos teve **6 aprovados e 1 falhado**. O caso sujo simulava Voltar imediatamente após `enterText`, antes de o frame reconstruir `PopScope.canPop`. Foi acrescentado `pumpAndSettle` no novo teste, após a escrita. O cenário passou com o frame actualizado; não se alteraram PopScope, ModalNavigationGuard ou regras de descarte. A repetição dirigida dos quatro casos modais passou: **4/4**.

A revisão visual reproduziu pendências anteriores à 3E: sobreposição pontual do FAB com «Ver hábitos» no primeiro viewport de Hoje preenchido e corte do rótulo secundário «Guardar e adicionar outra» com texto a 200%. Estão documentadas abaixo, sem redesenho ou correcção automática de comportamentos anteriores.

## 4. Alterações efectuadas

| Ficheiro | Finalidade |
| --- | --- |
| `test/phase3f_task_journey_test.dart` | Três percursos transversais reais da mesma tarefa |
| `test/phase3f_modal_test.dart` | Quatro casos de guard, diálogos aninhados, falha/repetição e regresso |
| `tool/capture_quality.dart` | Utilitário reprodutível para renderizar e inspeccionar ecrãs com fixtures sintéticas |
| `docs/ux/previews/phase3f/*.png` | Capturas produzidas pelo Flutter, sem mockups nem imagens geradas |
| `.github/workflows/flutter-validation.yml` | Apenas inclusão do novo branch nos disparos; verificações e critérios de falha intactos |
| `.github/workflows/android-debug-validation.yml` | Build debug num runner isolado, versões documentadas; guarda apenas logs |
| `docs/PHASE3F_REPORT.md` | Matriz inicial, evidências, limitações e entrega |

**Nenhuma alteração em `lib/`, `android/`, `pubspec.yaml`, `pubspec.lock`, esquema SQLite v5, identificador, assinatura, regras financeiras, XP ou notificações.** Não foram acrescentadas dependências. Não houve merge, distribuição, redesign geral ou início de outra fase.

## 5. Testes acrescentados e preservados

`phase3f_task_journey_test.dart` contém três casos: só meta, só disciplina e ambas. Usam os controlos reais: criar em Hoje → consultar Planear → reagendar → abrir Tarefas via Mais → editar → concluir → reabrir → concluir novamente → consultar Planear. Em cada etapa verificam:

- uma única linha e o mesmo ID/created, título e estado persistidos;
- dia e hora preservados no reagendamento, goal_id/subject_id e restantes propriedades;
- dataProvider actualizado, sem cópias por ecrã;
- uma única origem `task:<id>` de 10 XP mesmo após reabertura e nova conclusão;
- ausência de alteração automática da métrica da meta;
- cancelamento/agendamento sempre com o mesmo ID e a data esperada.

Os três casos passaram na primeira execução dirigida. SQLite é real em memória; somente o serviço de plataforma de lembretes é simulado. Não é validação da entrega de notificações.

`phase3f_modal_test.dart` contém quatro casos: dois ciclos de folha limpa/Voltar sem escrita; folha suja com confirmação root, continuar e descartar; DatePicker sobre folha, falha SQLite e repetição explícita; chooser/Editor completo root com picker, falha e recuperação. Tentam mudar de separador pelo callback real com modais abertos e verificam o ramo, o rascunho, o FAB e a libertação posterior. Só a confirmação explícita descarta o rascunho da folha rápida. Nenhum guard foi desactivado.

Todos os testes anteriores estão preservados byte a byte em relação a efd8ad7. A cobertura nova é complementar; não se alteraram expectativas antigas para aceitar regressões. Os casos de renderização são diagnósticos separados, não engrossam a contagem da suite em `test/`.

## 6. Ferramentas e validação local

Flutter **3.35.7**, revisão **adc901062556672b4138e18a4dc62a4be8f4b3c2**; Dart **3.9.2**, DevTools 2.48.0. O SDK/cache já preparado apresenta canal/origem local desconhecidos, mas a revisão foi verificada. `tool/env.sh` selecciona JDK Temurin **21.0.13+9**, cache de pacotes e SQLite nativo. O Java do sistema é 21.0.12.1.

| Comando / verificação | Resultado observado |
| --- | --- |
| `flutter --version` | Código 0, versões acima |
| Suite original dos ficheiros do HEAD inicial | Código 0; 180 aprovados, 0 falhados |
| Sete testes novos, primeira tentativa | Código 1; 6 aprovados, 1 falhado por sincronização do teste; causa e correcção registadas |
| Quatro casos modais, repetição após correcção | Código 0; 4 aprovados, 0 falhados |
| `dart format` nos ficheiros novos | Formatação aplicada; sem alteração em testes anteriores |
| `flutter pub get --enforce-lockfile` | Código 0; dependências e lockfile preservados |
| `dart format --output=none --set-exit-if-changed lib test tool/capture_quality.dart` | Código 0; 95 ficheiros, 0 alterações na verificação final |
| `flutter analyze --no-pub` | Primeira execução código 1: duas infos de chaves em if no novo utilitário; corrigidas sem alteração lógica. Repetição final código 0: **No issues found** |
| `flutter test --no-pub --machine` + processador | Código 0 em ambos; **187 executados, 187 aprovados, 0 falhados, 0 ignorados, 0 erros de execução**, cerca de 105 segundos; 180 anteriores + 7 novos |
| `python3 -B -m unittest discover -s tool -p 'test_summarize_flutter_tests.py' -v` | 9 aprovados, 0 falhados; processador existente preservado |
| YAML dos dois workflows, scripts `bash -n`, Python `ast.parse` | Aprovados; sem mascarar códigos de saída |
| `git diff --check` e comparação das áreas protegidas | Aprovados na preparação; repetir antes do commit |
| `flutter doctor -v` | Código 0, mas diagnóstico Android toolchain falhou por SDK ausente; não equivale a ambiente saudável |
| `flutter devices` | Código 0; apenas Linux desktop, nenhum Android |
| `flutter build apk --debug --no-pub` local | **Código 1**: `[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.` |
| Mesmo build no runner GitHub Actions | **Aprovado**, execução 42982260786; APK debug existente e não vazio, sem publicação |

Logs locais completos encontram-se em `/workspace/3f-*.log`, fora do código de produção. Para reproduzir num ambiente preparado:

```bash
source tool/env.sh
flutter --version
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test tool/capture_quality.dart
flutter analyze --no-pub
flutter test --no-pub --machine > /tmp/tudoaki-3f-tests.jsonl
python3 tool/summarize_flutter_tests.py /tmp/tudoaki-3f-tests.jsonl /tmp/tudoaki-3f-summary.json
flutter test --no-pub tool/capture_quality.dart --reporter expanded
git diff --exit-code -- lib android pubspec.yaml pubspec.lock
```

Os caminhos absolutos de `tool/env.sh` destinam-se ao ambiente cloud documentado. Noutro computador, preparar as mesmas versões conforme README/tool e executar os comandos Flutter sem esse ficheiro.

## 7. GitHub Actions

O workflow **Flutter validation** foi mantido; só se acrescentou `qa/fase-3f-integracao` ao push. Permanecem lockfile obrigatório, nove testes do processador, formatação, análise, testes Flutter e agregação dos códigos reais. Não existe `continue-on-error` para tornar falhas verdes.

O novo **Android debug validation** usa Ubuntu 24.04, Java 21, Flutter 3.35.7/revisão exacta e Dart 3.9.2. Prepara os componentes do projecto: CLI 19.0/checksum existente, APIs 34/35/36, Build Tools 35.0.0, NDK 27.0.12077973 e CMake 3.22.1. Reutiliza Gradle 8.12, AGP 8.9.1 e Kotlin 2.1.0 sem actualizar o projecto. Limites de memória/workers ficam num GRADLE_USER_HOME temporário. Compila com `flutter build apk --debug --no-pub`, verifica o APK não vazio e confere a ausência de alterações em Android e dependências. O `pipefail` preserva falhas do build. **Só logs são carregados como artefacto; não se publica APK nem se altera distribuição.**

Resultado remoto observado no commit de código **62ebb523089b6993f26d3e917714e8319b308d79**: **Flutter validation aprovado**, execução [42982260573](https://github.com/MxxSultane/tudoaki/actions/runs/42982260573), estado COMPLETED/conclusão SUCCESS. A contagem 187 acima vem da execução local, não foi inferida dos logs remotos. **Android debug validation aprovado**, execução [42982260786](https://github.com/MxxSultane/tudoaki/actions/runs/42982260786), estado COMPLETED/conclusão SUCCESS observado em 11/11/2026. A preparação Android e resolução/preservação terminaram com sucesso; o passo de compilação executou o build debug e a verificação do APK não vazio. Não foram consultados logs privados nem inferidas contagens remotas. O commit documental de entrega conserva integralmente código, testes, workflows e capturas deste SHA; as execuções do HEAD são consultáveis em [Actions do branch](https://github.com/MxxSultane/tudoaki/actions?query=branch%3Aqa%2Ffase-3f-integracao).

## 8. Revisão visual executada

O utilitário usa a aplicação real, fontes locais, SQLite em memória, relógios injectados e dados sintéticos. A renderização Flutter é exportada a 2× para PNG. Não são goldens de aceitação nem capturas de um Android físico.

Capturas em [`ux/previews/phase3f/`](ux/previews/phase3f/): Hoje vazio/preenchido; Planear dia/amanhã/semana/sem data; Metas; Mais; Tarefas; folha rápida; Editor completo; Hábitos; Estudos; Finanças; Revisões; Definições; Progresso; Agenda completa; loading e erro de leitura. Cada estado tem versão `-light.png` e `-dark.png`.

Foram executados cenários 360×800, escala 200%, para Mais, folha rápida com inset de teclado de 280 px, Hoje preenchido, Planear semana e Editor completo. Nos restantes estados a dimensão é 390×844, escala 100%. O teclado é espaço/inset simulado; não há IME Android desenhado. O título extenso na folha rápida mantém-se num campo horizontal rolável. Não foi ensaiada exaustivamente cada página a todas as escalas.

Exemplos: [Hoje preenchido](ux/previews/phase3f/hoje-filled-light.png), [Planear semana escuro](ux/previews/phase3f/plan-week-dark.png), [folha rápida/200%/teclado](ux/previews/phase3f/quick-keyboard-200-dark.png), [Mais/200%](ux/previews/phase3f/more-200-light.png), [Finanças escuro](ux/previews/phase3f/finance-dark.png), [erro de leitura](ux/previews/phase3f/read-error-light.png).

A hierarquia de Hoje/Planear separa compromissos com hora e tarefas flexíveis; o seleccionado da barra distingue-se por cor e rótulo. Os tokens semânticos novos usam floresta/grafite no claro e Sage sobre grafite no escuro. Não se certifica contraste de toda a aplicação só por captura: os testes de tema/contraste existentes são complementares. Alvos da identidade 2.0 têm mínimos de 48 px; o tema legado usa 44 px em vários botões. TalkBack, ordem de foco nativa, brilho real e conforto de leitura não foram verificados em telefone.

### Pendências visuais verificadas

| Problema | Componente / evidência | Impacto e recomendação | Risco / prioridade |
| --- | --- | --- | --- |
| FAB cobre parte de «Ver hábitos» no primeiro viewport de Hoje preenchido | `app.dart` FAB global, `today_screen.dart` cabeçalho; `hoje-filled-{light,dark}.png` | O alvo pode ficar parcialmente encoberto; scroll reposiciona-o. O comportamento já existe antes da 3E (base 3D), sem atribuição a esta integração. Rever posicionamento numa fase aprovada | Sem perda persistida; P2 |
| «Guardar e adicionar outra» fica cortado com texto 200%/teclado | QuickTaskSheet, `quick-keyboard-200-{light,dark}.png` | Texto secundário comprido e área reduzida; validar acesso por scroll e altura do botão em revisão de acessibilidade. Componente anterior, não redesenhado aqui | Sem alteração de dados; P2 |
| Datas ISO nas Revisões e plurais/títulos repetidos em Progresso/Agenda | `reviews_screen.dart:30`, `progress_screen.dart`, `progress_panel.dart`, `agenda_browser.dart`; capturas das áreas | «Semanal · 2026-11-11», «1 tarefas concluídas», «1 metas activas» e cabeçalhos duplicados. Polimento futuro só de apresentação, preservando os valores gravados | Baixo risco para texto; P3 |
| Identidade diferente ao entrar em módulos antigos | `TudoAkiShell` aplica `buildTodayTheme` aos destinos principais; áreas secundárias usam o tema base `buildTheme`; capturas de Planear/Metas/Mais versus Finanças/Progresso | Cor de acção, densidade, cartões e cabeçalhos mudam entre áreas. Harmonizar por módulo numa fase visual própria, preservando funções | Mudança de tema exige regressão local; P2 |

As **50 imagens** foram abertas e inspeccionadas: 40 capturas a 390×844/100% e 10 a 360×800/200%, nos dois temas. Execuções: 44/44 renderizações iniciais, 6/6 adicionais, códigos 0. Uma repetição dirigida de scroll passou 6/6: «Ver hábitos», «Guardar» no Editor e «Guardar e adicionar outra» ficaram hit-testable. Esta última legenda continua cortada horizontalmente; o scroll não corrige a largura. Durante a preparação do diagnóstico de scroll, 2 casos falharam porque o helper procurava um item ainda não construído pela ListView lazy; substituiu-se apenas o helper por scrollUntilVisible. A repetição passou. Não é um defeito da aplicação nem foi somado aos 187 testes funcionais.

## 9. Problemas conhecidos, sem correcção automática

P1 = resolver/validar antes de distribuição ou de alterações que dependam do contrato afectado; P2 = melhoria planeada; P3 = compatibilidade de baixo alcance. «Confirmado por código» descreve implementação verificável; não atribui reprodução em dispositivo.

| Problema / gravidade | Ficheiro responsável | Impacto / possibilidade de perda | Reprodução e estado | Recomendação / risco da alteração / prioridade |
| --- | --- | --- | --- | --- |
| `/agenda` sem rota registada — baixa | `app_routes.dart:22`, `screens.dart:245`, `app.dart` | Deep link histórico dá erro; sem escrita/perda | Teste existente confirma match com erro. O chamador encontrado é Hoje antigo inactivo, não TodayScreen | Aprovar alias/redireccionamento; risco baixo, P3 |
| Evento que atravessa meia-noite — média/alta | `database.dart:234`, `agenda_items.dart:24` | Continuação pode faltar no dia seguinte e nos conflitos; linha guardada não desaparece | Confirmado por selecção do dia inicial em occurrenceOn; não novo ensaio nativo nesta fase | Testar intersecção de intervalos/recorrência antes de corrigir; risco médio, P1 |
| Edição/reagendamento após eliminação concorrente — alta | `task_operations.dart:20,40,47`, `database.dart:141` | UPDATE sem linhas pode devolver sucesso. Intenção de edição pode perder-se, eventual alarme órfão; não reinsere/duplica a linha | Confirmado por código; concorrência real não reproduzida agora. Requer eliminação entre leitura e escrita | Guarda transaccional/erro explícito e testes de corrida; risco médio, P1 |
| Dias UTC divergentes entre consumidores — média/alta | `agenda_items.dart:32`, `today_content.dart:63`, `planning_items.dart:13` | Agenda antiga agrupa parse cru, Hoje/Planear usam toLocal; perto da meia-noite o dia pode diferir. Sem reescrita física | Confirmado por código; dependente de offset/dados. Não certificado em vários fusos nesta fase | Aprovar política temporal e matriz TZ antes de unificar; risco alto se reinterpretar histórico, P1 |
| Lembretes/fuso Maputo/agendamento aproximado — média/alta | `reminders.dart:34,45,71,88` | Aviso pode atrasar/faltar; tarefa persiste. Fuso fixo pode não corresponder a viagem | Código confirmado; entrega, permissões, Doze e reinício não verificados em Android | Guião físico e política explícita de fuso; risco médio, P1 de validação |
| Eliminar depende de cancelar notificação — média | `task_operations.dart:119` | Se cancelar lançar erro, DELETE não ocorre; registo fica preservado | Ordem confirmada no código, sem nova falha nativa reproduzida | Decidir política após ensaio nativo; risco médio, P2 |
| Exportação sem importação/restauro — alta | `settings_screen.dart:98`, `database.dart:214`, Manifest `allowBackup=false` | Desinstalação/limpeza/perda do telefone podem perder a base. JSON não garante recuperação; leitura sequencial não é snapshot transaccional | Ausência confirmada no código/docs; não se apagaram dados para ensaiar | Protocolo de restauro/round-trip/rollback em fase autorizada; risco alto, P1 antes de migrações/distribuição |
| Editor completo sem confirmação de rascunho — média | `features/forms.dart`, em contraste com QuickTaskSheet | Back/barreira/arrasto podem perder texto ainda não guardado; não apagam registo persistido | Ausência de PopScope confirmada no código; anterior à integração. Percepção em telefone não verificada | Rever contrato dos formulários completos, sem desactivar guard; risco médio, P2 |
| Consistência visual dos módulos antigos — média | Temas e componentes legados | Mudança de identidade/densidade, sem perda de dados | Capturas reais nos dois temas | Harmonização incremental separada, sem eliminar funções; risco médio, P2 |
| Actualização/assinatura existente — alta de validação | `android/app/build.gradle.kts`, V2_CONTRACTS | Debug verde não prova instalação por cima ou continuidade de assinatura. Desinstalar como contorno pode apagar dados | Identificador preservado; actualização com APK/keystore anterior não executada | Testar actualização compatível numa cópia de teste antes de distribuir; risco alto, P1 |
| README histórico — baixa | `README.md` | Ainda descreve três separadores/80 testes/limitação antiga; pode confundir ao executar main | Confirmado por leitura; relatório actual é a referência 3F | Actualizar documentação de lançamento quando aprovado, P3 |

Os nomes abreviados da tabela apontam para `lib/core/database/`, `lib/features/agenda/domain/`, `lib/features/planning/domain/`, `lib/features/tasks/domain/`, `lib/core/notifications/` e `lib/features/settings/presentation/`, conforme indicado na matriz. Não foram criados testes que obriguem a conservar os defeitos conhecidos.

## 10. Android, dados e limites de certificação

Não existem SDK/adb/emulador nos caminhos preparados, `/dev/kvm` ou dispositivo USB/Android acessível. A tentativa de build local falhou concretamente por SDK ausente. O ficheiro CLI oficial respondeu HTTP 200 a HEAD; contudo doctor identificou HTTP 403 do proxy para storage.googleapis.com/maven.google.com. Não se confunde acesso a um download com ambiente Android operacional. Optou-se pelo runner preparado, sem instalar vários GB localmente nem alterar o projecto.

**Não executado:** instalação Android, testes físicos/emulador, gestos do SO, TalkBack, IME real, permissões/entrega de lembretes, reinício, suspensão, actualização sobre assinatura anterior, dados de um telefone, release/iOS/web e ensaio prolongado de desempenho. Uma compilação debug aprovada, se observada na CI, comprova apenas compilação.

Todos os dados usados são sintéticos, em SQLite em memória; não se abriu a base local de um utilizador. Não houve migração, restauro ou reinterpretação de datas. O risco adicional desta entrega para dados persistidos é baixo por não modificar produção. Os riscos anteriores de concorrência/temporalidade/ausência de restauro permanecem; Git e screenshots não são backup da base do telefone.

## 11. Recomendação

**A regressão automatizada está aprovada no commit de código indicado:** 187/187 testes, análise e formatação aprovadas, ambas as CIs verdes e compilação Android debug concluída. Não foi encontrada regressão funcional nova que exija corrigir produção. Recomenda-se entregar a Fase 3F para revisão humana e decisão de produto; uma fase seguinte pode ser autorizada mantendo explícitas as pendências P1 de dados e de validação nativa.

Não se recomenda declarar pronta para distribuição: ainda faltam instalação/actualização compatível, notificações, teclado/gestos e acessibilidade em Android real ou emulador. As duas pendências visuais P2 e o contrato de descarte do Editor completo devem ter uma correcção de acessibilidade aprovada; os riscos temporais/concorrência/restauro exigem fases próprias e testes antes de alterar regras. Não houve merge nem início da etapa seguinte.
