import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, AppConstants.databaseName);

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    _database = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invitations (
        id TEXT PRIMARY KEY,
        guest_name TEXT NOT NULL,
        allowed_count INTEGER NOT NULL CHECK(allowed_count > 0),
        token TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL CHECK(status IN ('unused', 'used', 'cancelled')),
        created_at TEXT NOT NULL,
        used_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_invitations_status ON invitations(status)
    ''');

    await db.execute('''
      CREATE TABLE scan_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invitation_id TEXT,
        result TEXT NOT NULL,
        message TEXT NOT NULL,
        scanned_at TEXT NOT NULL,
        FOREIGN KEY(invitation_id) REFERENCES invitations(id)
      )
    ''');
  }
}
