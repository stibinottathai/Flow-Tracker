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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
CREATE TABLE user_settings ( 
  id $idType, 
  lastPeriodDate $textType,
  cycleLength $integerType,
  periodDuration $integerType,
  reminderEnabled $boolType,
  reminderDaysBefore $integerType DEFAULT 1,
  reminderTime $textType DEFAULT "09:00"
  )
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN reminderEnabled INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN reminderDaysBefore INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE user_settings ADD COLUMN reminderTime TEXT NOT NULL DEFAULT "09:00"',
      );
    }
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
