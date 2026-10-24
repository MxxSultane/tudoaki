# Arquitectura
Flutter/Dart, Material 3, Riverpod (injecção e invalidação), GoRouter (cinco destinos e módulos auxiliares), Drift/SQLite nativo. Sem backend.

## Responsabilidades
`app/`: tema e navegação. `core/database/`: esquema SQL versionado, repositório e regras transaccionais. `core/notifications/`: adaptação das permissões e agendamento. `features/`: ecrãs, formulários e estados. O repositório devolve registos SQL como mapas; a interface usa snapshots invalidados pelo Riverpod. Entidades de domínio dedicadas podem substituir os mapas à medida que as regras crescerem. Freezed/codegen não são usados nesta fundação. SQL explícito no Drift evita artefactos gerados; consultas parametrizadas.

## Relações
UserPreferences singleton. Goals → GoalMilestones, Tasks, Habits (SET NULL para preservar acções). Subjects → Tasks e StudySessions. CalendarEvents independentes. Habits → HabitCompletions (CASCADE e UNIQUE hábito/data). SavingsGoals → FinancialTransactions (SET NULL). Achievements e ExperienceEvents com chave única de origem para idempotência. PeriodicReviews preserva respostas. Índices em datas e chaves estrangeiras; foreign_keys ON; migração inicial v1 e rejeição de versões futuras.

Datas de calendário são locais (AAAA-MM-DD); instantes agendados em ISO 8601 com offset. A fundação usa Africa/Maputo para notificações. Mudanças de fuso e DST fora de Maputo requerem trabalho posterior. Recorrência diária/semanal é calculada por datas civis, sem somar horas UTC.

## Trade-offs
SQLite nativo serve Android e testes Dart; web não está preparada. Dados locais não estão encriptados pela aplicação. XP reconhece uma primeira conclusão, não pune descanso. Resultados das metas são manuais e independentes de tarefas. A exportação usa a folha de partilha do sistema; é o utilizador que escolhe o destino. O esquema inclui entidades futuras sem fingir que têm UI completa.
