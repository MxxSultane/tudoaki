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
];
