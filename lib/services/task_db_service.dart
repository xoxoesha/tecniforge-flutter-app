import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

// ---------------------------------------------------------------------------
// TASK DATABASE SERVICE — local, on-device SQLite storage for the Task List
// screen (via the `sqflite` package).
//
// This is different from Business Notes (SharedPreferences, a simple
// key-value store) and from Clients/Team Tasks (a REST API, live over the
// network). SQLite gives us:
//   - A real relational table on disk, so data survives app restarts —
//     the same as SharedPreferences, but...
//   - ...the ability to QUERY it with SQL (e.g. "give me only the completed
//     tasks", "give me only the active ones") instead of loading everything
//     into memory and filtering in Dart.
//
// There is exactly one database connection for the whole app (a singleton),
// opened lazily the first time it's needed and reused after that.
//
// Robustness notes:
//   - Every method wraps its DB call in try/catch and rethrows a clear,
//     app-level Exception, so callers (the UI) never see a raw sqflite
//     crash — they get a message they can display.
//   - update/delete check how many rows were actually affected. If a
//     caller passes an id that no longer exists, that's now a real error
//     instead of a silent no-op.
//   - Indexes on `completed` and `createdAt` speed up the filtered
//     queries and the ORDER BY as the table grows.
// ---------------------------------------------------------------------------

class TaskDbService {
  TaskDbService._();
  static final TaskDbService instance = TaskDbService._();

  static const _dbName = 'tecniforge_tasks.db';
  static const _dbVersion = 1;
  static const table = 'tasks';

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath(); // e.g. /data/user/0/<package>/databases
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        // Indexes speed up the filtered queries (WHERE completed = ?) and
        // the ORDER BY createdAt used in getTasks() — matters once the
        // table has more than a handful of rows.
        await db.execute('CREATE INDEX idx_tasks_completed ON $table (completed)');
        await db.execute('CREATE INDEX idx_tasks_createdAt ON $table (createdAt)');
      },
      // Placeholder for future schema changes. When _dbVersion is bumped,
      // migration steps go here so existing users' data is preserved
      // instead of the table being wiped and recreated.
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  /// Inserts a new task and returns it with the id SQLite assigned.
  Future<LocalTask> insertTask(String title) async {
    try {
      final db = await _database;
      final task = LocalTask(title: title, createdAt: DateTime.now());
      final id = await db.insert(table, task.toMap()..remove('id'));
      return LocalTask(id: id, title: task.title, completed: task.completed, createdAt: task.createdAt);
    } catch (e) {
      throw Exception('Could not save task: $e');
    }
  }

  /// Returns tasks, optionally filtered by completion state (a real SQL
  /// WHERE clause — not an in-memory filter), newest first.
  Future<List<LocalTask>> getTasks({bool? completed}) async {
    try {
      final db = await _database;
      final rows = await db.query(
        table,
        where: completed == null ? null : 'completed = ?',
        whereArgs: completed == null ? null : [completed ? 1 : 0],
        orderBy: 'createdAt DESC',
      );
      return rows.map(LocalTask.fromMap).toList();
    } catch (e) {
      throw Exception('Could not load tasks: $e');
    }
  }

  Future<void> setCompleted(int id, bool completed) async {
    try {
      final db = await _database;
      final rowsAffected = await db.update(
        table,
        {'completed': completed ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw Exception('Task not found (id: $id)');
      }
    } catch (e) {
      throw Exception('Could not update task: $e');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final db = await _database;
      final rowsAffected = await db.delete(table, where: 'id = ?', whereArgs: [id]);
      if (rowsAffected == 0) {
        throw Exception('Task not found (id: $id)');
      }
    } catch (e) {
      throw Exception('Could not delete task: $e');
    }
  }

  /// Quick counts for the "X active" subtitle — also a real SQL query
  /// (COUNT), not List.length in Dart.
  Future<int> countTasks({bool? completed}) async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        completed == null
            ? 'SELECT COUNT(*) as c FROM $table'
            : 'SELECT COUNT(*) as c FROM $table WHERE completed = ?',
        completed == null ? null : [completed ? 1 : 0],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Could not count tasks: $e');
    }
  }

  /// Closes the database connection. Not required for normal app use
  /// (the singleton lives for the app's lifetime), but good practice to
  /// have available — e.g. for tests, or a future "reset data" feature.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}