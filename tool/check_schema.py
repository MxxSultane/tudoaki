"""Supplementary SQL check; does not replace the Dart/Flutter test suite."""
import pathlib
import re
import sqlite3
import tempfile

source = (pathlib.Path(__file__).parents[1] / 'lib/core/database/schema.dart').read_text()
def statements_for(version):
    block = source.split(f'const schemaV{version} = <String>[', 1)[1].split('\n];', 1)[0]
    matches = re.findall(r"'''(.*?)'''|\"\"\"(.*?)\"\"\"|'([^'\n]*)'|\"([^\"\n]*)\"", block, flags=re.S)
    return [next(part for part in match if part) for match in matches]

statements = statements_for(1)
upgrade = statements_for(2)
academic_upgrade = statements_for(3)
finance_upgrade = statements_for(4)
assert len(statements) == 20 and len(upgrade) == 5 and len(academic_upgrade) == 13 and len(finance_upgrade) == 6, 'Incomplete schema parsing'
with tempfile.TemporaryDirectory() as directory:
    file = pathlib.Path(directory) / 'tudo_aki.sqlite'
    db = sqlite3.connect(file)
    db.execute('PRAGMA foreign_keys=ON')
    for sql in statements:
        db.execute(sql)
    db.execute("INSERT INTO Goals(title,target,created) VALUES('Ler',12,'2026-10-24')")
    db.execute("INSERT INTO Tasks(title,goal_id,created) VALUES('Ler capítulo',1,'2026-10-24')")
    db.execute('DELETE FROM Goals WHERE id=1')
    assert db.execute('SELECT goal_id FROM Tasks').fetchone() == (None,)
    db.execute("INSERT INTO Habits(title) VALUES('Caminhar')")
    db.execute("INSERT INTO HabitCompletions(habit_id,day) VALUES(1,'2026-10-24')")
    try:
        db.execute("INSERT INTO HabitCompletions(habit_id,day) VALUES(1,'2026-10-24')")
    except sqlite3.IntegrityError:
        pass
    else:
        raise AssertionError('Duplicate habit day accepted')
    for _ in range(3):
        db.execute("INSERT OR IGNORE INTO ExperienceEvents VALUES('task:1',10,'2026-10-24')")
    assert db.execute('SELECT SUM(points) FROM ExperienceEvents').fetchone() == (10,)
    db.execute("INSERT INTO FinancialTransactions(title,amount_cents,kind,day) VALUES('Poupança',1200010,'saving','2026-10-24')")
    assert db.execute('SELECT amount_cents,typeof(amount_cents) FROM FinancialTransactions').fetchone() == (1200010, 'integer')
    db.execute("INSERT INTO StudySessions(start,minutes) VALUES('2026-10-24T10:00:00',25)")
    db.execute("INSERT INTO StudySessions(start,minutes,completed) VALUES('2026-10-23T10:00:00',10,1)")
    db.commit()
    with db:
        for sql in upgrade:
            db.execute(sql)
        db.execute('PRAGMA user_version=2')
    with db:
        for sql in academic_upgrade:
            db.execute(sql)
        db.execute('PRAGMA user_version=3')
    assert db.execute('SELECT remaining_seconds FROM StudySessions ORDER BY id').fetchall() == [(1500,), (0,)]
    with db:
        for sql in finance_upgrade:
            db.execute(sql)
        db.execute('PRAGMA user_version=4')
    db.execute("INSERT INTO Budgets(month,category,category_key,limit_cents) VALUES('2026-10','Casa','casa',50000)")
    try:
        db.execute("INSERT INTO Budgets(month,category,category_key,limit_cents) VALUES('2026-10','CASA','casa',10000)")
    except sqlite3.IntegrityError:
        pass
    else:
        raise AssertionError('Duplicate category budget accepted')
    rule = db.execute("INSERT INTO RecurringTransactions(title,amount_cents,kind,category,frequency,start_day) VALUES('Renda',10000,'expense','Casa','monthly','2026-10-01')").lastrowid
    movement = db.execute("INSERT INTO FinancialTransactions(title,amount_cents,kind,category,day,recurring_id,recurring_day) VALUES('Renda',10000,'expense','Casa','2026-10-01',?,'2026-10-01')", (rule,)).lastrowid
    db.execute("INSERT INTO RecurringOccurrences(rule_id,day,transaction_id) VALUES(?,'2026-10-01',?)", (rule,movement))
    db.execute('DELETE FROM FinancialTransactions WHERE id=?', (movement,))
    assert db.execute('SELECT transaction_id FROM RecurringOccurrences').fetchone() == (None,)
    db.execute("UPDATE StudySessions SET focus_end='2026-10-24T10:25:00Z' WHERE id=1")
    try:
        db.execute("INSERT INTO StudySessions(start,minutes,remaining_seconds,focus_end) VALUES('2026-10-24T10:00:00',25,1500,'2026-10-24T10:25:00Z')")
    except sqlite3.IntegrityError:
        pass
    else:
        raise AssertionError('Concurrent focus sessions accepted')
    year = db.execute("INSERT INTO Goals(title,target,created) VALUES('Ano',12,'2026-10-24')").lastrowid
    month = db.execute("INSERT INTO Goals(title,target,created,parent_id) VALUES('Mês',1,'2026-10-24',?)", (year,)).lastrowid
    try:
        db.execute('UPDATE Goals SET parent_id=? WHERE id=?', (month,year))
    except sqlite3.IntegrityError:
        pass
    else:
        raise AssertionError('Goal cycle accepted')
    db.execute('DELETE FROM Goals WHERE id=?', (year,))
    assert db.execute('SELECT parent_id FROM Goals WHERE id=?', (month,)).fetchone() == (None,)
    assert db.execute('PRAGMA foreign_key_check').fetchall() == []
    db.commit()
    db.close()
    db = sqlite3.connect(file)
    assert db.execute('SELECT title FROM Tasks').fetchone() == ('Ler capítulo',)
    assert db.execute('SELECT COUNT(*) FROM HabitCompletions').fetchone() == (1,)
    db.close()
print('SQL OK: v1 → v4 migration, financial ledger/budgets, durable focus, acyclic goals, foreign keys, integer cents, reopen persistence.')
