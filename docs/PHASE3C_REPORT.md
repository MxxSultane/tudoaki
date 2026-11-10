# Fase 3C — novo Hoje

## Origem e inventário antes da implementação
Branch feat/fase-3c-novo-hoje, a partir de 5df87f463cdaebb3150bbe73368c3fb79d145a7b. Árvore inicialmente limpa; esta base da Fase 3B foi validada localmente (122 testes) e pela execução Actions 42783336902. Contratos lidos: AGENTS.md, V2_CONTRACTS.md, DESIGN_SYSTEM.md e ambos os documentos HOJE_PLANEAR da Fase 3A. Os ajustes aprovados D1–D8 prevalecem sobre propostas anteriores: sem Desfazer novo nem alteração de XP, uma data, guardar explícito e navegação actual.

O Hoje activo encontra-se em lib/features/agenda/presentation/today_screen.dart, na rota /. Não é o ramo Hoje antigo de screens.dart. Antes desta implementação, contém:

| Conteúdo ou acção actual | Preservação prevista |
| --- | --- |
| Cabeçalho Hoje/Agenda, data e Mais | Cabeçalho Hoje/data/Mais no resumo; Agenda/data no calendário completo. |
| Selector de data, anterior/seguinte, Dia/Semana/Mês e faixa semanal | Modos mantidos no resumo; consulta completa mantida em AgendaBrowser, com retorno a Hoje e sem nova rota. |
| Agenda pessoal/académica, conflitos, tarefas e editores | Calendário completo preservado. Resumo usa as mesmas ocorrências e editores por origem; nunca cria cópias académicas. |
| Expansão O meu dia: próximo compromisso e três prioridades | Substituída por compromissos e listas explícitas, sem repetir tarefas no mesmo resumo. |
| Hábitos do dia e Definir uma rotina | Até três hábitos, mesma operação toggleHabit; acesso Ver hábitos, incluindo vazio. |
| Até duas metas activas no resumo | Consulta e criação mantidas no separador Metas, sempre visível; não duplicar resumos de metas em Hoje. |
| Retomar estudo em curso | Ligação condicional mantida em Hoje para a área Estudos existente. |
| Sem data e Voltar a hoje | Sem data continua no calendário e em Tarefas; resumo dá acesso a Tarefas. Retorno ao resumo explícito. |
| + global → Evento/Tarefa/Meta | Preservado, incluindo formulários e resultados. Acesso directo Adicionar tarefa usa showQuickTaskSheet com o dia civil de hoje. |

Não existe encaminhamento contextual de amanhã aprovado/implementado. Nesta fase mostrar apenas Planear semana funcional, sem /plan, parâmetro de navegação inventado ou página temporária.

## Nova estrutura e comportamento
1. Hoje, data civil por extenso e contagem de tarefas concluídas nessa data. Sem XP, percentagens ou indicadores fictícios no cabeçalho.
2. Modos Dia/Semana/Mês conservados como acesso directo à consulta antiga. Ver dia completo abre AgendaBrowser no mesmo /; Voltar a Hoje repõe o resumo do dia actual.
3. Compromissos: até dois em curso ou futuros, ordenados pelo modelo da agenda; eventos já terminados no mesmo dia continuam no calendário completo. Cada origem académica é projectada uma vez; não há inserts em CalendarEvents.
4. Tarefas do dia: pendentes por importância/prioridade, hora explícita e ID estável; todas alcançáveis, sem limite de três. TaskRow existente conclui/reabre via TaskOperations e abre o editor completo. Só se mostra hora quando existe, sem repetir Sem hora nas flexíveis.
5. De dias anteriores: recolhido por defeito, com data original, conclusão e editor existentes. Nenhum reagendamento ou penalização automática. Uma hora passada hoje continua em Tarefas de hoje.
6. Até três hábitos activos previstos para o dia, com registo diário original, bloqueio durante escrita e acesso a todos em Ver hábitos. Sem rotina, estado neutro e ligação funcional.
7. Concluídas hoje: recolhido, baseado em completed_at local, independentemente de due. Cada ID aparece numa única lista do resumo. Reabrir conserva as regras idempotentes de XP existentes.
8. Planear semana, lista global Tarefas/Sem data e Retomar estudo condicional. Metas permanecem no separador próprio, em vez de duplicar dois cartões no resumo.

Adicionar tarefa abre directamente showQuickTaskSheet da Fase 3B, com dia civil de hoje, foco/teclado e data removível. Guarda por TaskOperations e actualiza o snapshot. Confirmação inline acessível junto de Adicionar tarefa, antes da lista (também visível com 50 tarefas); sem data/outro dia tem acesso a Ver tarefas, sem redireccionamento automático. Só ao tocar Ver tarefas/Sem data se selecciona Pendentes na lista existente, para não esconder o registo num filtro Concluídas conservado de uma visita anterior. A área de origem é conservada. Guardar e adicionar outra mantém o comportamento 3B. O + global e o selector Evento/Tarefa/Meta permanecem, para conservar a criação existente e uma única acção principal. Não foi criado outro formulário.

Relógio: utiliza workspaceClockProvider, temporizador até ao próximo minuto (incluindo a meia-noite civil) e actualização ao retomar a aplicação. O temporizador é cancelado em pausa/ocultação; os próximos compromissos avançam também enquanto Hoje permanece aberto. Ao consultar explicitamente outro dia/modo, essa selecção é conservada; actualizar o relógio não reagenda tarefas nem escreve dados.

Visual: tema semântico Sage/Graphite limitado ao shell da Agenda/Hoje e às suas folhas; restantes áreas conservam o tema anterior. Inter/Newsreader locais, listas abertas, margens 20, ritmo 8, alvos 48, sem gradientes ou sombras. Pares de texto/controlos testados nos dois temas; Mineral fica reservado a detalhe/separação. Texto a 200% usa quebras e deslocação, sem alturas fixas nas listas.

## Ficheiros criados e modificados
| Ficheiro | Alteração |
| --- | --- |
| lib/features/agenda/presentation/today_screen.dart | Novo resumo, criação rápida, calendário, relógio/lifecycle e hábitos compactos. |
| lib/features/agenda/presentation/agenda_browser.dart | Extracção da consulta antiga, sem duplicar o DailySummary no calendário. |
| lib/features/agenda/domain/today_content.dart | Selectores só de leitura para o resumo, sem nova persistência. |
| lib/core/theme/today_theme.dart | Tokens e tema 2.0 limitado à área, incluindo contraste e estados dos controlos. |
| lib/app/app.dart | Aplica apenas esse tema ao shell quando o caminho é /; rotas, barra, índices e callbacks mantidos. |
| lib/features/tasks/presentation/task_row.dart | Opção visual showSubtitle, true por defeito; apenas Hoje oculta legendas redundantes. Operações inalteradas. |
| test/today_content_test.dart | Seis testes de projecções, ordenação, datas, ocorrências, hábitos e contraste. |
| test/today_screen_test.dart | Dezassete testes de comportamento real e adaptação de layout. |
| test/support/today_fixture.dart | SQLite sintético, lembretes simulados e relógio determinístico dos testes. |
| tool/capture_today.dart | Utilitário reproduzível de capturas reais do Flutter, fora da suite normal. |
| docs/ux/previews/phase3c/*.png | Quatro capturas: vazio/preenchido em claro/escuro. |
| .github/workflows/flutter-validation.yml | Só acrescenta o branch ao disparo push, sem alterar comandos ou critérios. |
| docs/ARCHITECTURE.md, docs/DESIGN_SYSTEM.md e este relatório | Arquitectura, âmbito visual e resultados. |

O ramo Hoje antigo de screens.dart e DailySummary permanecem no repositório; não se eliminou código legado alheio. Nenhum teste anterior foi modificado.

## Testes e resultados locais observados
Ferramentas: Flutter 3.35.7, revisão adc901062556672b4138e18a4dc62a4be8f4b3c2, Dart 3.9.2, com a preparação local concluída na Fase 3B. Comandos após source tool/env.sh:

| Comando | Resultado |
| --- | --- |
| flutter --version | Versões acima confirmadas. |
| dart format --output=none --set-exit-if-changed lib test tool/capture_today.dart | Código 0: 81 ficheiros, zero alterações. |
| flutter analyze --no-pub | Código 0: sem problemas. |
| flutter test --no-pub --reporter expanded | Código 0: **145 aprovados, 0 falhados**, duração observada 74 segundos. Inclui os 122 anteriores e 23 novos. |
| flutter test --no-pub tool/capture_today.dart --reporter expanded | Código 0: quatro renderizações/capturas, separadas da contagem de 145 testes da suite. |
| git diff --check; YAML e bash -n dos passos | Aprovados. |
| Diff das áreas protegidas e dos testes anteriores | Sem alterações. pubspec.yaml/pubspec.lock e dependências preservados. |

Cobertura nova: vazio; tarefas/compromissos; ordem cronológica e importância; UTC para dia local; hora passada hoje; pendentes anteriores; concluídas por completed_at; título/foco/data contextual/sem data; continuação e ausência de duplicação; concluir/reabrir/editar com ID, associações e XP preservados; hábitos/XP; planeador e estudo; erro de leitura/repetição e erro de conclusão; passagem de hora sem sair, meia-noite aberta e retoma; editores académicos por origem; 50 tarefas; 360 px, 200% de texto, teclado simulado e ambos os temas. Os testes usam apenas SQLite em memória.

As primeiras execuções dos novos testes revelaram a falta de inicialização do binding para fontes e pressupostos de visibilidade em listas progressivas; os helpers foram corrigidos para percorrer realmente a lista e inicializar o Flutter. Não se enfraqueceram critérios nem se alteraram testes antigos. Os 14 testes anteriores de aplicação/navegação/planeamento passaram também na verificação inicial.

## Capturas reais
Geradas por Flutter/RepaintBoundary a 390 × 844, PNG a 2×, fontes locais e MaterialIcons carregados, com dados sintéticos e relógio fixo em 10/11/2026. Revistas visualmente após os últimos ajustes. Não são imagens conceptuais nem capturas de um dispositivo Android.

| Estado | Claro | Escuro |
| --- | --- | --- |
| Vazio | [Captura](ux/previews/phase3c/today-empty-light.png) | [Captura](ux/previews/phase3c/today-empty-dark.png) |
| Preenchido | [Captura](ux/previews/phase3c/today-filled-light.png) | [Captura](ux/previews/phase3c/today-filled-dark.png) |

Reproduzir: source tool/env.sh; flutter test --no-pub tool/capture_today.dart. Os hábitos/concluídas e ligações mais abaixo continuam acessíveis por deslocação; a captura preenchida mostra o primeiro enquadramento.

## GitHub Actions
As execuções 42787974438 (primeira implementação, commit 74cefe9) e 42789027697 (relógio ao minuto, commit 84b8ef0) ficaram verdes; os passos públicos de formatação/análise/testes e preservação do lockfile foram observados com sucesso. Após a última execução foi reposicionada a confirmação junto da criação e reforçado o teste com 50 tarefas. Esse estado passou novamente em 145 testes locais; foi ainda verificado o acesso a tarefas pendentes após conservar o filtro Concluídas de uma visita anterior. Os dois casos de contexto passam e a suite final tem 145 aprovações. A CI da implementação completa ainda aguarda resultado observado.

## Limitações e preservação
- Planear amanhã específico continua adiado: só Planear semana existente é anunciado. /plan não está registada; não há quatro separadores, Planear 2.0, Percurso ou restauro.
- Rotas secundárias, botões de voltar, formulários antigos, esquema SQLite v5, dados/IDs, identificador Android, dependências/lockfile, TaskOperations, XP/conquistas, notificações e finanças não foram alterados. Não se acedeu a dados reais nem se executaram migrações.
- O modelo existente de agenda só cobre o dia inicial de eventos que atravessam meia-noite. Essa correcção não relacionada continua fora do âmbito; não se promete cobertura de continuação.
- O relógio local do dispositivo é a referência de Hoje. O serviço de notificações mantém a política Maputo existente; fusos globais/DST e entrega real de lembretes não foram certificados nesta fase.
- Teclado nativo, TalkBack/VoiceOver, desempenho físico e compreensão por novos utilizadores precisam de avaliação num dispositivo. Layout/contraste automatizados e capturas reais de widget não substituem essa avaliação. Não foi gerado APK: o Android SDK não está preparado neste ambiente e o pedido de validação desta fase é análise/testes.
- Sem merge automático e sem iniciar a fase seguinte; revisão/aprovação do responsável do produto permanece necessária.
- A tentativa de abrir PR em rascunho pela API GitHub recebeu Forbidden. O branch remoto e a comparação permanecem disponíveis para revisão; não houve merge.
