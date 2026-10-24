// V1 is intentionally explicit: no generated database sources are required.
const schemaV1 = <String>[
  '''CREATE TABLE UserPreferences (
    id INTEGER PRIMARY KEY CHECK (id = 1), theme TEXT NOT NULL DEFAULT 'system',
    gamification INTEGER NOT NULL DEFAULT 1, onboarded INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'MZN')''',
  'INSERT INTO UserPreferences(id) VALUES(1)',
  '''CREATE TABLE Goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '', category TEXT NOT NULL DEFAULT 'Pessoal',
    horizon TEXT NOT NULL DEFAULT 'Anual', due TEXT,
    initial REAL NOT NULL DEFAULT 0, target REAL NOT NULL CHECK(target > initial),
    current REAL NOT NULL DEFAULT 0, unit TEXT NOT NULL DEFAULT 'unidades',
    status TEXT NOT NULL DEFAULT 'active', created TEXT NOT NULL)''',
  '''CREATE TABLE GoalMilestones (
    id INTEGER PRIMARY KEY AUTOINCREMENT, goal_id INTEGER NOT NULL REFERENCES Goals(id) ON DELETE CASCADE,
    title TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0)''',
  '''CREATE TABLE Subjects (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL UNIQUE)''',
  '''CREATE TABLE Tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, due TEXT,
    priority INTEGER NOT NULL DEFAULT 1 CHECK(priority BETWEEN 0 AND 2),
    important INTEGER NOT NULL DEFAULT 0, reminder INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0,
    completed_at TEXT, goal_id INTEGER REFERENCES Goals(id) ON DELETE SET NULL,
    subject_id INTEGER REFERENCES Subjects(id) ON DELETE SET NULL,
    created TEXT NOT NULL)''',
  'CREATE INDEX task_due ON Tasks(due)',
  'CREATE INDEX task_goal ON Tasks(goal_id)',
  '''CREATE TABLE CalendarEvents (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, start TEXT NOT NULL,
    end TEXT NOT NULL, recurrence TEXT NOT NULL DEFAULT 'none'
    CHECK(recurrence IN ('none','daily','weekly')))''',
  'CREATE INDEX event_start ON CalendarEvents(start)',
  '''CREATE TABLE Habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
    cue TEXT NOT NULL DEFAULT '', category TEXT NOT NULL DEFAULT 'Pessoal',
    weekdays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
    paused INTEGER NOT NULL DEFAULT 0, goal_id INTEGER REFERENCES Goals(id) ON DELETE SET NULL)''',
  '''CREATE TABLE HabitCompletions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, habit_id INTEGER NOT NULL REFERENCES Habits(id) ON DELETE CASCADE,
    day TEXT NOT NULL, UNIQUE(habit_id,day))''',
  '''CREATE TABLE StudySessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, subject_id INTEGER REFERENCES Subjects(id) ON DELETE SET NULL,
    start TEXT NOT NULL, minutes INTEGER NOT NULL CHECK(minutes > 0), completed INTEGER NOT NULL DEFAULT 0)''',
  '''CREATE TABLE SavingsGoals (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
    target_cents INTEGER NOT NULL CHECK(target_cents > 0))''',
  '''CREATE TABLE FinancialTransactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
    amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
    kind TEXT NOT NULL CHECK(kind IN ('income','expense','saving')),
    category TEXT NOT NULL DEFAULT 'Geral', day TEXT NOT NULL,
    savings_id INTEGER REFERENCES SavingsGoals(id) ON DELETE SET NULL)''',
  'CREATE INDEX transaction_day ON FinancialTransactions(day)',
  '''CREATE TABLE Achievements (
    code TEXT PRIMARY KEY, unlocked_at TEXT NOT NULL)''',
  '''CREATE TABLE ExperienceEvents (
    source TEXT PRIMARY KEY, points INTEGER NOT NULL CHECK(points > 0), created TEXT NOT NULL)''',
  '''CREATE TABLE PeriodicReviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT, period TEXT NOT NULL,
    day TEXT NOT NULL, achieved TEXT NOT NULL, pending TEXT NOT NULL,
    obstacles TEXT NOT NULL, next TEXT NOT NULL)''',
  '''CREATE TABLE GoalProgress (
    id INTEGER PRIMARY KEY AUTOINCREMENT, goal_id INTEGER NOT NULL REFERENCES Goals(id) ON DELETE CASCADE,
    value REAL NOT NULL, recorded_at TEXT NOT NULL)''',
];
// Additive upgrade: existing goals, actions, history and IDs are preserved.
const schemaV2 = <String>[
  'ALTER TABLE Goals ADD COLUMN parent_id INTEGER REFERENCES Goals(id) ON DELETE SET NULL CHECK(parent_id IS NULL OR parent_id != id)',
  'ALTER TABLE GoalMilestones ADD COLUMN due TEXT',
  'CREATE INDEX goal_parent ON Goals(parent_id)',
  'CREATE INDEX milestone_goal ON GoalMilestones(goal_id)',
  """CREATE TRIGGER goal_parent_no_cycles BEFORE UPDATE OF parent_id ON Goals
    WHEN NEW.parent_id IS NOT NULL BEGIN
      SELECT RAISE(ABORT, 'Ciclo entre metas') WHERE EXISTS (
        WITH RECURSIVE ancestors(id, parent_id) AS (
          SELECT id, parent_id FROM Goals WHERE id = NEW.parent_id
          UNION
          SELECT g.id, g.parent_id FROM Goals g JOIN ancestors a ON g.id = a.parent_id
        ) SELECT 1 FROM ancestors WHERE id = NEW.id
      );
    END""",
];

// Academic planning and durable focus state; existing records keep their IDs.
const schemaV3 = <String>[
  """CREATE TABLE ClassSchedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subject_id INTEGER NOT NULL REFERENCES Subjects(id) ON DELETE CASCADE,
    weekday INTEGER NOT NULL CHECK(weekday BETWEEN 1 AND 7),
    start_minute INTEGER NOT NULL CHECK(start_minute BETWEEN 0 AND 1439),
    end_minute INTEGER NOT NULL CHECK(end_minute > start_minute AND end_minute <= 1440),
    location TEXT NOT NULL DEFAULT '', active_from TEXT NOT NULL,
    active_until TEXT CHECK(active_until IS NULL OR active_until >= active_from))""",
  """CREATE TABLE Assessments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subject_id INTEGER REFERENCES Subjects(id) ON DELETE SET NULL,
    title TEXT NOT NULL, kind TEXT NOT NULL DEFAULT 'Teste'
      CHECK(kind IN ('Teste','Exame','Apresentação')),
    at TEXT NOT NULL, minutes INTEGER NOT NULL DEFAULT 60 CHECK(minutes > 0),
    completed INTEGER NOT NULL DEFAULT 0 CHECK(completed IN (0,1)))""",
  "ALTER TABLE StudySessions ADD COLUMN title TEXT NOT NULL DEFAULT 'Sessão de estudo'",
  'ALTER TABLE StudySessions ADD COLUMN remaining_seconds INTEGER NOT NULL DEFAULT 0 CHECK(remaining_seconds >= 0)',
  'ALTER TABLE StudySessions ADD COLUMN focus_end TEXT',
  'ALTER TABLE StudySessions ADD COLUMN focus_started_at TEXT',
  'ALTER TABLE StudySessions ADD COLUMN completed_at TEXT',
  'UPDATE StudySessions SET remaining_seconds = CASE WHEN completed = 1 THEN 0 ELSE minutes * 60 END',
  'CREATE UNIQUE INDEX study_one_running ON StudySessions((1)) WHERE focus_end IS NOT NULL AND completed = 0',
  'CREATE INDEX study_subject ON StudySessions(subject_id)',
  'CREATE INDEX study_start ON StudySessions(start)',
  'CREATE INDEX assessment_at ON Assessments(at)',
  'CREATE INDEX class_subject ON ClassSchedules(subject_id)',
];

// Planning never posts money automatically. A ledger preserves explicit postings.
const schemaV4 = <String>[
  """CREATE TABLE Budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    month TEXT NOT NULL CHECK(length(month) = 7 AND substr(month,5,1) = '-' AND CAST(substr(month,6,2) AS INTEGER) BETWEEN 1 AND 12),
    category TEXT NOT NULL CHECK(length(trim(category)) > 0), category_key TEXT NOT NULL,
    limit_cents INTEGER NOT NULL CHECK(limit_cents > 0), UNIQUE(month,category_key))""",
  """CREATE TABLE RecurringTransactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
    amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
    kind TEXT NOT NULL CHECK(kind IN ('income','expense')),
    category TEXT NOT NULL, frequency TEXT NOT NULL CHECK(frequency IN ('weekly','monthly','yearly')),
    start_day TEXT NOT NULL, end_day TEXT CHECK(end_day IS NULL OR end_day >= start_day),
    active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)), revision INTEGER NOT NULL DEFAULT 1)""",
  """CREATE TABLE RecurringOccurrences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_id INTEGER NOT NULL REFERENCES RecurringTransactions(id) ON DELETE CASCADE,
    day TEXT NOT NULL, transaction_id INTEGER REFERENCES FinancialTransactions(id) ON DELETE SET NULL,
    UNIQUE(rule_id,day))""",
  'ALTER TABLE FinancialTransactions ADD COLUMN recurring_id INTEGER REFERENCES RecurringTransactions(id) ON DELETE SET NULL',
  'ALTER TABLE FinancialTransactions ADD COLUMN recurring_day TEXT',
  'CREATE UNIQUE INDEX financial_recurring_day ON FinancialTransactions(recurring_id,recurring_day) WHERE recurring_id IS NOT NULL',
];

const exportTables = [
  'UserPreferences',
  'Goals',
  'GoalMilestones',
  'Subjects',
  'Tasks',
  'CalendarEvents',
  'Habits',
  'HabitCompletions',
  'StudySessions',
  'SavingsGoals',
  'FinancialTransactions',
  'Achievements',
  'ExperienceEvents',
  'PeriodicReviews',
  'GoalProgress',
  'ClassSchedules',
  'Assessments',
  'Budgets',
  'RecurringTransactions',
  'RecurringOccurrences',
];
