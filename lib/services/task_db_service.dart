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
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      '''),
    );
  }

  /// Inserts a new task and returns it with the id SQLite assigned.
  Future<LocalTask> insertTask(String title) async {
    final db = await _database;
    final task = LocalTask(title: title, createdAt: DateTime.now());
    final id = await db.insert(table, task.toMap()..remove('id'));
    return LocalTask(id: id, title: task.title, completed: task.completed, createdAt: task.createdAt);
  }

  /// Returns tasks, optionally filtered by completion state (a real SQL
  /// WHERE clause — not an in-memory filter), newest first.
  Future<List<LocalTask>> getTasks({bool? completed}) async {
    final db = await _database;
    final rows = await db.query(
      table,
      where: completed == null ? null : 'completed = ?',
      whereArgs: completed == null ? null : [completed ? 1 : 0],
      orderBy: 'createdAt DESC',
    );
    return rows.map(LocalTask.fromMap).toList();
  }

  Future<void> setCompleted(int id, bool completed) async {
    final db = await _database;
    await db.update(table, {'completed': completed ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTask(int id) async {
    final db = await _database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Quick counts for the "X active" subtitle — also a real SQL query
  /// (COUNT), not List.length in Dart.
  Future<int> countTasks({bool? completed}) async {
    final db = await _database;
    final result = await db.rawQuery(
      completed == null
          ? 'SELECT COUNT(*) as c FROM $table'
          : 'SELECT COUNT(*) as c FROM $table WHERE completed = ?',
      completed == null ? null : [completed ? 1 : 0],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
