"""Supplementary SQL check; does not replace the Dart/Flutter test suite."""
import pathlib
import re
import sqlite3
import tempfile

source = (pathlib.Path(__file__).parents[1] / 'lib/core/database/schema.dart').read_text()
block = source.split('const schemaV1 = <String>[', 1)[1].split('\n];', 1)[0]
statements = [match[0] or match[1] for match in re.findall(r"'''(.*?)'''|'([^'\n]*)'", block, flags=re.S)]
assert len(statements) == 20, f'Unexpected schema statement count: {len(statements)}'
with tempfile.TemporaryDirectory() as directory:
    file = pathlib.Path(directory) / 'lifeos.sqlite'
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
    assert db.execute('PRAGMA foreign_key_check').fetchall() == []
    db.commit()
    db.close()
    db = sqlite3.connect(file)
    assert db.execute('SELECT title FROM Tasks').fetchone() == ('Ler capítulo',)
    assert db.execute('SELECT COUNT(*) FROM HabitCompletions').fetchone() == (1,)
    db.close()
print('SQL OK: schema v1, foreign keys, habit uniqueness, XP uniqueness, integer cents, reopen persistence.')
