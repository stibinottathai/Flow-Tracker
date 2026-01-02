import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:p_tracker/features/onboarding/data/models/user_settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('p_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE user_settings ( 
  id $idType, 
  lastPeriodDate $textType,
  cycleLength $integerType,
  periodDuration $integerType
  )
''');
  }

  Future<int> create(UserSettingsModel settings) async {
    final db = await instance.database;
    // We only want one row of settings, so we clear the table first or update if exists.
    // For simplicity, let's just delete all and insert.
    await db.delete('user_settings');
    return await db.insert('user_settings', settings.toMap());
  }

  Future<UserSettingsModel?> readSettings() async {
    final db = await instance.database;
    final maps = await db.query('user_settings');

    if (maps.isNotEmpty) {
      return UserSettingsModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
