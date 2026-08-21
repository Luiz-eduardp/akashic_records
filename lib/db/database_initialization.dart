import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_tables.dart';

class DatabaseInitialization {
  static const int currentVersion = 7;

  static Future<Database> initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'akashic_records.db');

    try {
      return await _openDatabase(path);
    } catch (_) {
      await _deleteAndRecreate(path);
      try {
        return await _openDatabase(path);
      } catch (_) {
        return await _openInMemoryDatabase();
      }
    }
  }

  static Future<Database> _openDatabase(String path) async {
    final db = await openDatabase(
      path,
      version: currentVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
    try {
      await db.execute("UPDATE ${DatabaseTables.novels} SET chapters = '[]' WHERE LENGTH(chapters) > 20000;");
      await db.execute("UPDATE ${DatabaseTables.novels} SET description = SUBSTR(description, 1, 2000) WHERE LENGTH(description) > 20000;");
    } catch (_) {}
    return db;
  }

  static Future<Database> _openInMemoryDatabase() {
    return openDatabase(
      inMemoryDatabasePath,
      version: currentVersion,
      onCreate: _createTables,
    );
  }

  static Future<void> _deleteAndRecreate(String path) async {
    try {
      await deleteDatabase(path);
    } catch (_) {}
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute(DatabaseTables.createNovelTable);
    await db.execute(DatabaseTables.createPluginsTable);
    await db.execute(DatabaseTables.createLocalEpubsTable);
    await db.execute(DatabaseTables.createSavedChaptersTable);
    await db.execute(DatabaseTables.createSettingsTable);
    await db.execute(DatabaseTables.createChapterReadsTable);
    await db.execute(DatabaseTables.createLocalDocumentsTable);
    await db.execute(DatabaseTables.createReadingProgressTable);
    await db.execute(DatabaseTables.createAnnotationsTable);
    await db.execute(DatabaseTables.createReadingStatsTable);
  }

  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _migrateToV2(db);
    if (oldVersion < 3) await _migrateToV3(db);
    if (oldVersion < 4) await _migrateToV4(db);
    if (oldVersion < 5) await _migrateToV5(db);
    if (oldVersion < 6) await _migrateToV6(db);
    if (oldVersion < 7) await _migrateToV7(db);
  }

  static Future<void> _migrateToV7(Database db) async {
    try {
      await db.execute(DatabaseTables.createAnnotationsTable);
      await db.execute(DatabaseTables.createReadingStatsTable);
    } catch (_) {}
  }

  static Future<void> _migrateToV2(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE novels ADD COLUMN isFavorite INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE novels ADD COLUMN lastChecked TEXT');
      await db.execute(
        'ALTER TABLE novels ADD COLUMN lastKnownChapterCount INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE novels ADD COLUMN lastReadAt TEXT');
      await db.execute('ALTER TABLE novels ADD COLUMN lastReadChapterId TEXT');
    } catch (_) {}
  }

  static Future<void> _migrateToV3(Database db) async {
    try {
      await db.execute(DatabaseTables.createSettingsTable);
    } catch (_) {}
  }

  static Future<void> _migrateToV4(Database db) async {
    try {
      await db.execute(DatabaseTables.createLocalEpubsTable);
      await db.execute(DatabaseTables.createSavedChaptersTable);
      await db.execute(DatabaseTables.createChapterReadsTable);
    } catch (_) {}
  }

  static Future<void> _migrateToV5(Database db) async {
    try {
      await db.execute('ALTER TABLE novels ADD COLUMN lastReadAt TEXT');
    } catch (_) {}
  }

  static Future<void> _migrateToV6(Database db) async {
    try {
      await db.execute('ALTER TABLE local_epubs ADD COLUMN format TEXT DEFAULT \'epub\'');
    } catch (_) {}
    try {
      await db.execute(DatabaseTables.createLocalDocumentsTable);
      await db.execute(DatabaseTables.createReadingProgressTable);

      await db.execute('''
        INSERT OR IGNORE INTO local_documents (id, filePath, title, author, description, coverPath, format, chapters, importedAt)
        SELECT id, filePath, title, author, description, coverPath, COALESCE(format, 'epub'), chapters, importedAt FROM local_epubs
      ''');
    } catch (_) {}
  }
}
