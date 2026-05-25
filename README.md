# NoElephant

An embedded relational database (**mdb**) written in Mettle, with a small interactive demo.

mdb is a single-directory, file-backed store with page caching, a write-ahead log, heap storage, and hash indexes. It targets Windows today via the Mettle standard library.

## Requirements

- Windows
- Mettle compiler at `bin\mettle.exe` with stdlib at `bin\stdlib\`

The `bin\` directory is not committed to git. Copy or build Mettle locally before running `build.bat`.

## Build

From the repository root:

```bat
build.bat
```

This produces `build\db_demo.exe`.

## Run the demo

```bat
build\db_demo.exe path\to\database_dir
```

The demo opens (or creates) a database directory containing `data.db`, `data.wal`, and `data.lock`, then starts an interactive SQL prompt.

Example session:

```sql
CREATE TABLE users (id INT64 PRIMARY KEY, name TEXT);
INSERT INTO users VALUES (1, 'alice');
SELECT * FROM users;
UPDATE users SET name = 'bob' WHERE id = 1;
DELETE FROM users WHERE id = 1;
```

Press Enter on an empty line to quit.

## Project layout

```
NoElephant/
├── build.bat              # build script
├── src/
│   └── mdb/               # embedded database library
├── examples/
│   └── db_demo/           # interactive CLI demo source
├── build/                 # build output (gitignored)
└── bin/                   # Mettle toolchain (gitignored, local only)
```

## Library API

Import the public module with `-I src\mdb` and `import "db";`:

| Function | Description |
|----------|-------------|
| `db_open(dir)` | Open or create a database in `dir` |
| `db_close(db)` | Close and release resources |
| `db_exec(db, sql, len)` | Execute a SQL statement |
| `db_checkpoint(db)` | Flush WAL into the main database file |
| `db_error_str(err)` | Human-readable error string |

Column types: `INT64`, `TEXT`. Supported SQL: `CREATE TABLE`, `INSERT`, `SELECT` (optional `WHERE`), `UPDATE`, `DELETE`.

## License

MIT — see [LICENSE](LICENSE).
