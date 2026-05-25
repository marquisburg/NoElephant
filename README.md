# NoElephant

Embedded relational database (mdb) in Mettle, plus a small CLI demo.

mdb is a file-backed store in one directory: page cache, WAL, heap storage, hash indexes. Windows only for now (Mettle stdlib).

## Requirements

- Windows
- Mettle at `bin\mettle.exe`, stdlib at `bin\stdlib\`

`bin\` is not in git. Install or build Mettle locally, then run `build.bat`.

## Build

```bat
build.bat
```

Output: `build\db_demo.exe`.

## Demo

```bat
build\db_demo.exe path\to\database_dir
```

Creates or opens a directory with `data.db`, `data.wal`, and `data.lock`, then an interactive SQL prompt.

```sql
CREATE TABLE users (id INT64, name TEXT);
INSERT INTO users VALUES (1, 'alice');
SELECT * FROM users;
UPDATE users SET name = 'bob' WHERE id = 1;
DELETE FROM users WHERE id = 1;
```

Empty line quits. First column in `CREATE TABLE` is the primary key.

## Smoke tests

```bat
tests\run_smoke.bat
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\smoke.ps1
```

Builds `db_demo`, runs CRUD on a temp DB, reopens and checks rows. `-SkipBuild` reuses a build; `-KeepTemp` keeps the temp directory.

## Library API

`-I src\mdb`, then `import "db";`:

- `db_open(dir)` open or create
- `db_close(db)` close
- `db_exec(db, sql, len)` run SQL
- `db_checkpoint(db)` flush WAL to main file
- `db_error_str(err)` error text

Types: `INT64`, `TEXT`. SQL: `CREATE TABLE`, `INSERT`, `SELECT` (optional `WHERE`), `UPDATE`, `DELETE`.

## License

MIT. See [LICENSE](LICENSE).
