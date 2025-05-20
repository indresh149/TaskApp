import 'package:notesapp/data/models/task_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:developer' as developer;

const String _dbName = 'tasks_database.db';
const String _taskTable = 'tasks';

class TaskLocalDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_taskTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        createdDate TEXT NOT NULL,
        dueDate TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        tags TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_task_status ON $_taskTable (status)');
    await db
        .execute('CREATE INDEX idx_task_priority ON $_taskTable (priority)');
    await db.execute(
        'CREATE INDEX idx_task_created_date ON $_taskTable (createdDate)');
    developer.log('Database created with version $version',
        name: 'TaskLocalDataSource');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion',
        name: 'TaskLocalDataSource');
    if (oldVersion < 2) {}
  }

  Future<void> addTask(TaskModel task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        _taskTable,
        task.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    developer.log('Task added: ${task.id}', name: 'TaskLocalDataSource');
  }

  Future<TaskModel?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _taskTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TaskModel.fromDbMap(maps.first);
    }
    return null;
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(_taskTable, orderBy: 'createdDate DESC');
    return List.generate(maps.length, (i) {
      return TaskModel.fromDbMap(maps[i]);
    });
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _taskTable,
        task.toDbMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    });
    developer.log('Task updated: ${task.id}', name: 'TaskLocalDataSource');
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        _taskTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    developer.log('Task deleted: $id', name: 'TaskLocalDataSource');
  }

  Future<void> clearAllTasks() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_taskTable);
    });
    developer.log('All tasks cleared from local DB',
        name: 'TaskLocalDataSource');
  }

  Future<List<TaskModel>> getUnsyncedTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _taskTable,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => TaskModel.fromDbMap(maps[i]));
  }

  Future<void> updateTasks(List<TaskModel> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      Batch batch = txn.batch();
      for (var task in tasks) {
        batch.update(
          _taskTable,
          task.toDbMap(),
          where: 'id = ?',
          whereArgs: [task.id],
        );
      }
      await batch.commit(noResult: true);
    });
    developer.log('${tasks.length} tasks updated in batch',
        name: 'TaskLocalDataSource');
  }

  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_taskTable);
      Batch batch = txn.batch();
      for (var task in tasks) {
        batch.insert(_taskTable, task.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    developer.log('${tasks.length} tasks cached into local DB.',
        name: 'TaskLocalDataSource');
  }
}
