abstract class DatabaseTables {
  static const String novels = 'novels';
  static const String plugins = 'plugins';
  static const String localEpubs = 'local_epubs';
  static const String savedChapters = 'saved_chapters';
  static const String settings = 'settings';
  static const String chapterReads = 'chapter_reads';
  static const String localDocuments = 'local_documents';
  static const String readingProgress = 'reading_progress';
  static const String annotations = 'annotations';
  static const String readingStats = 'reading_stats';

  static const String createNovelTable = '''
    CREATE TABLE IF NOT EXISTS novels (
      id TEXT PRIMARY KEY,
      pluginId TEXT,
      title TEXT,
      coverImageUrl TEXT,
      author TEXT,
      description TEXT,
      genres TEXT,
      status INTEGER,
      shouldShowNumberOfChapters INTEGER,
      chapters TEXT,
      isFavorite INTEGER DEFAULT 0,
      lastChecked TEXT,
      lastReadAt TEXT,
      lastKnownChapterCount INTEGER DEFAULT 0,
      lastReadChapterId TEXT
    )
  ''';

  static const String createPluginsTable = '''
    CREATE TABLE IF NOT EXISTS plugins (
      id TEXT PRIMARY KEY,
      enabled INTEGER DEFAULT 1,
      prefs TEXT
    )
  ''';

  static const String createLocalEpubsTable = '''
    CREATE TABLE IF NOT EXISTS local_epubs (
      id TEXT PRIMARY KEY,
      filePath TEXT,
      title TEXT,
      author TEXT,
      description TEXT,
      coverPath TEXT,
      format TEXT DEFAULT 'epub',
      chapters TEXT,
      importedAt TEXT
    )
  ''';

  static const String createSavedChaptersTable = '''
    CREATE TABLE IF NOT EXISTS saved_chapters (
      novelId TEXT,
      chapterId TEXT,
      title TEXT,
      content TEXT,
      savedAt TEXT,
      PRIMARY KEY (novelId, chapterId)
    )
  ''';

  static const String createSettingsTable = '''
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''';

  static const String createChapterReadsTable = '''
    CREATE TABLE IF NOT EXISTS chapter_reads (
      novelId TEXT,
      chapterId TEXT,
      read INTEGER,
      PRIMARY KEY (novelId, chapterId)
    )
  ''';

  static const String createLocalDocumentsTable = '''
    CREATE TABLE IF NOT EXISTS local_documents (
      id TEXT PRIMARY KEY,
      filePath TEXT,
      title TEXT,
      author TEXT,
      description TEXT,
      coverPath TEXT,
      format TEXT DEFAULT 'epub',
      fileSize INTEGER DEFAULT 0,
      chapters TEXT,
      importedAt TEXT
    )
  ''';

  static const String createReadingProgressTable = '''
    CREATE TABLE IF NOT EXISTS reading_progress (
      documentId TEXT PRIMARY KEY,
      chapterId TEXT,
      pageIndex INTEGER DEFAULT 0,
      scrollOffset REAL DEFAULT 0.0,
      progressPercent REAL DEFAULT 0.0,
      estimatedTimeLeftSeconds INTEGER DEFAULT 0,
      lastReadAt TEXT
    )
  ''';

  static const String createAnnotationsTable = '''
    CREATE TABLE IF NOT EXISTS annotations (
      id TEXT PRIMARY KEY,
      novelId TEXT,
      chapterId TEXT,
      selectedText TEXT,
      note TEXT,
      colorHex TEXT,
      createdAt TEXT
    )
  ''';

  static const String createReadingStatsTable = '''
    CREATE TABLE IF NOT EXISTS reading_stats (
      date TEXT PRIMARY KEY,
      secondsRead INTEGER DEFAULT 0,
      wordsRead INTEGER DEFAULT 0,
      chaptersCompleted INTEGER DEFAULT 0
    )
  ''';
}
