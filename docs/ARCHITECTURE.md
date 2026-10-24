# Arquitectura — Tudo Aki
Flutter/Dart, Material 3, Riverpod (injecção e invalidação), GoRouter (cinco destinos e módulos auxiliares), Drift/SQLite nativo. Sem backend.

## Responsabilidades
`app/`: tema e navegação. `core/database/`: esquema SQL versionado, repositório e regras transaccionais. `core/notifications/`: adaptação das permissões e agendamento. `features/`: ecrãs, formulários e estados. O repositório devolve registos SQL como mapas; a interface usa snapshots invalidados pelo Riverpod. Entidades de domínio dedicadas podem substituir os mapas à medida que as regras crescerem. Freezed/codegen não são usados nesta fundação. SQL explícito no Drift evita artefactos gerados; consultas parametrizadas.

## Relações
UserPreferences singleton. Goals → GoalMilestones, Tasks, Habits (SET NULL para preservar acções). Subjects → Tasks e StudySessions. CalendarEvents independentes. Habits → HabitCompletions (CASCADE e UNIQUE hábito/data). SavingsGoals → FinancialTransactions (SET NULL). Achievements e ExperienceEvents com chave única de origem para idempotência. PeriodicReviews preserva respostas. Índices em datas e chaves estrangeiras; foreign_keys ON; esquema actual v3, migrações aditivas v1/v2 → v3 e rejeição de versões futuras.

Datas de calendário são locais (AAAA-MM-DD); instantes agendados em ISO 8601 com offset. A fundação usa Africa/Maputo para notificações. Mudanças de fuso e DST fora de Maputo requerem trabalho posterior. Recorrência diária/semanal é calculada por datas civis, sem somar horas UTC.

## Trade-offs
SQLite nativo serve Android e testes Dart; web não está preparada. Dados locais não estão encriptados pela aplicação. XP reconhece uma primeira conclusão, não pune descanso. Resultados das metas são manuais e independentes de tarefas. A exportação usa a folha de partilha do sistema; é o utilizador que escolhe o destino. O esquema inclui entidades futuras sem fingir que têm UI completa.

## Planeamento de metas (v2)
`Goals.parent_id` estabelece uma hierarquia opcional e usa `ON DELETE SET NULL`. Um CHECK impede referências à própria meta e um trigger com CTE recursiva impede ciclos entre antepassados. O selector na interface também exclui a própria meta e os seus descendentes.

`GoalMilestones.due` adiciona um prazo opcional às etapas. Etapas pertencem à meta e são eliminadas em cascata; tarefas e submetas são preservadas quando a meta principal é apagada. As métricas de cada meta são independentes: conclusão de etapas/tarefas e progresso de submetas não são somados arbitrariamente ao resultado da meta principal.

A migração adiciona colunas, índices e um trigger e é executada numa transacção que grava também `PRAGMA user_version`. A exportação JSON usa a versão efectiva do esquema. Os testes abrem um ficheiro v1, migram-no, verificam dados e reabrem-no como v2. Não foram acrescentadas dependências.

## Identidade e compatibilidade (0.2.1)
Nome público e slogan estão em `lib/app/brand.dart`. O pacote Flutter/Dart e o nome Gradle são `tudo_aki`; o namespace e a classe de entrada Android usam `mz.tudoaki.tudo_aki`. O manifesto aponta explicitamente para a nova classe de entrada e usa `@string/app_name` para o launcher.

Um alias de actividade mantém compatibilidade com intents explícitos antigos sem criar um segundo ícone no launcher. São preservados o ID de instalação Android `mz.lifeos.lifeos` e o ficheiro local `lifeos.sqlite`, para que uma actualização mantenha acesso aos dados e à configuração existentes. São detalhes internos de compatibilidade; não representam o nome público nem o nome do pacote Dart. A marca não altera o esquema v2, as regras de negócio, os requisitos ou as metodologias do produto.

## Organização académica e foco (v3)
`features/academics/` separa regras de ocorrências/contagem, operações de estudo, formulários, painel e temporizador. `ClassSchedules` pertence a `Subjects` com CASCADE. `Assessments` e `StudySessions` usam SET NULL para preservar registos ao apagar uma disciplina. Índices suportam datas e relações.

A migração v3 acrescenta título e estado de foco às sessões existentes; sessões antigas incompletas recebem `minutes * 60` segundos e as concluídas mantêm o estado com zero segundos restantes. Migrações v1 → v3 e v2 → v3 são transaccionais, preservando dados e IDs. A exportação inclui as novas tabelas e a versão 3.

Estado do foco: planeado (prazo nulo), em curso (prazo UTC), pausado (prazo nulo e segundos guardados), pronto a confirmar (prazo atingido), concluído (completed/completed_at). Os segundos são calculados por diferença entre instantes e arredondados para cima; não se decrementa um valor apenas com callbacks do Timer. O temporizador actualiza a interface a cada segundo e ao retomar o ciclo de vida. Fechar a página cancela apenas o Timer da interface, mantendo o estado em SQLite.

Um índice parcial único impede duas sessões em curso. Iniciar uma sessão em curso não reinicia o prazo. Uma conclusão antecipada é recusada; uma conclusão repetida é inócua. XP usa a origem única por sessão/dia e limite de três recompensas diárias. Pausas e sessões adicionais não retiram XP. Sessões iniciadas preservam duração/planeamento; a eliminação é explícita.

As ocorrências académicas são modelos de leitura compatíveis com a agenda, sem duplicar linhas em CalendarEvents. Aulas usam dias/horas civis e datas de validade inclusivas; foco usa UTC para duração. A agenda mostra blocos planeados, enquanto `focus_started_at`/`completed_at` guardam instantes reais. Outras limitações de calendário, fusos e ocorrências que atravessam dias continuam documentadas. Não há serviço de alarme de foco em segundo plano.
