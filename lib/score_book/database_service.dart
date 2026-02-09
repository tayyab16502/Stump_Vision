import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'cricket_scores.db');
    return await openDatabase(
      path,
      version: 7, // Bumped version for TEXT ID migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ID is now TEXT PRIMARY KEY
    await db.execute('''
      CREATE TABLE matches(
        id TEXT PRIMARY KEY, 
        matchDetails TEXT,
        innings1Data TEXT,
        innings2Data TEXT,
        currentInnings INTEGER DEFAULT 1,
        targetToChase INTEGER DEFAULT 0,
        firstInningScore INTEGER DEFAULT 0,
        firstInningOuts INTEGER DEFAULT 0,
        isComplete INTEGER,
        lastUpdated INTEGER,
        notes TEXT DEFAULT NULL
      )
    ''');
    print('Database created with version $version');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    if (oldVersion < newVersion) {
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        switch (version) {
          case 5:
            try {
              await db.execute('ALTER TABLE matches ADD COLUMN notes TEXT DEFAULT NULL');
            } catch (e) {
              print('Column notes exists/error: $e');
            }
            break;
          case 6:
            try {
              await db.execute('ALTER TABLE matches ADD COLUMN currentInnings INTEGER DEFAULT 1');
            } catch (e) {}
            try {
              await db.execute('ALTER TABLE matches ADD COLUMN targetToChase INTEGER DEFAULT 0');
            } catch (e) {}
            try {
              await db.execute('ALTER TABLE matches ADD COLUMN firstInningScore INTEGER DEFAULT 0');
            } catch (e) {}
            try {
              await db.execute('ALTER TABLE matches ADD COLUMN firstInningOuts INTEGER DEFAULT 0');
            } catch (e) {}
            break;
          case 7:
          // Migration to convert INTEGER ID to TEXT ID
            await _migrateIdToText(db);
            break;
        }
      }
    }
  }

  // Helper to migrate Int ID to Text ID
  Future<void> _migrateIdToText(Database db) async {
    print('Starting migration of ID column to TEXT...');
    try {
      // 1. Read existing data
      final List<Map<String, dynamic>> oldMatches = await db.query('matches');

      // 2. Rename old table
      await db.execute('ALTER TABLE matches RENAME TO matches_old');

      // 3. Create new table with TEXT ID
      await db.execute('''
        CREATE TABLE matches(
          id TEXT PRIMARY KEY,
          matchDetails TEXT,
          innings1Data TEXT,
          innings2Data TEXT,
          currentInnings INTEGER DEFAULT 1,
          targetToChase INTEGER DEFAULT 0,
          firstInningScore INTEGER DEFAULT 0,
          firstInningOuts INTEGER DEFAULT 0,
          isComplete INTEGER,
          lastUpdated INTEGER,
          notes TEXT DEFAULT NULL
        )
      ''');

      // 4. Insert old data into new table, converting ID to String
      for (var match in oldMatches) {
        final oldId = match['id'];
        String newId = oldId.toString(); // Convert int ID to string

        Map<String, dynamic> newMatch = Map.from(match);
        newMatch['id'] = newId;

        await db.insert('matches', newMatch);
      }

      // 5. Drop old table
      await db.execute('DROP TABLE matches_old');
      print('Migration to TEXT ID complete.');

    } catch (e) {
      print('Error during ID migration: $e');
      // If something failed, try to restore old table or leave as is for manual fix
    }
  }

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'cricket_scores.db');
    await deleteDatabase(path);
    _database = null;
  }

  // Changed return type to Future<String> because ID is string
  Future<String> insertOrUpdateMatch(Map<String, dynamic> matchData) async {
    Database db = await database;
    // ID handled as String
    final String? matchId = matchData['id'] as String?;

    int isCompleteValue = (matchData['isComplete'] is bool) ? (matchData['isComplete'] ? 1 : 0) : 0;

    Map<String, dynamic> dataToSave = {
      'matchDetails': matchData['matchDetails'],
      'innings1Data': matchData['innings1Data'],
      'innings2Data': matchData['innings2Data'],
      'currentInnings': matchData['currentInnings'] ?? 1,
      'targetToChase': matchData['targetToChase'] ?? 0,
      'firstInningScore': matchData['firstInningScore'] ?? 0,
      'firstInningOuts': matchData['firstInningOuts'] ?? 0,
      'isComplete': isCompleteValue,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      if (matchId != null) {
        // Update existing using String ID
        // Use ConflictAlgorithm.replace might overwrite ID if not careful, but here we update by ID
        int count = await db.update('matches', dataToSave, where: 'id = ?', whereArgs: [matchId]);
        if (count > 0) {
          return matchId;
        } else {
          // Fallback if ID provided but not found (shouldn't happen normally)
          dataToSave['id'] = matchId;
          await db.insert('matches', dataToSave);
          return matchId;
        }
      } else {
        // Generate new UUID if not present (though Logic should provide it)
        String newId = const Uuid().v4();
        dataToSave['id'] = newId;
        await db.insert('matches', dataToSave);
        return newId;
      }
    } catch (e) {
      print('Error saving match: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMatches() async {
    Database db = await database;
    return await db.query('matches', orderBy: 'lastUpdated DESC');
  }

  Future<void> deleteMatch(String id) async { // ID is String
    Database db = await database;
    await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getMatchState(String id) async { // ID is String
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query('matches', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> exportMatchToJson(String matchId) async { // ID is String
    try {
      final matchData = await getMatchState(matchId);
      if (matchData == null) return null;

      return {
        'exportVersion': '1.0',
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
        'matchId': matchData['id'],
        'matchDetails': matchData['matchDetails'],
        'innings1Data': matchData['innings1Data'],
        'innings2Data': matchData['innings2Data'],
        'isComplete': matchData['isComplete'],
        'lastUpdated': matchData['lastUpdated'],
        'notes': matchData['notes'],
        'currentInnings': matchData['currentInnings'],
        'targetToChase': matchData['targetToChase'],
        'firstInningScore': matchData['firstInningScore'],
        'firstInningOuts': matchData['firstInningOuts'],
      };
    } catch (e) {
      print('Error exporting: $e');
      return null;
    }
  }

  Future<String?> importMatchFromJson(Map<String, dynamic> jsonData) async { // Returns String ID
    try {
      String matchDetailsJson = jsonData['matchDetails'] is String ? jsonData['matchDetails'] : jsonEncode(jsonData['matchDetails']);
      String innings1DataJson = jsonData['innings1Data'] is String ? jsonData['innings1Data'] : jsonEncode(jsonData['innings1Data']);
      String innings2DataJson = jsonData['innings2Data'] is String ? jsonData['innings2Data'] : jsonEncode(jsonData['innings2Data']);

      // Use ID from JSON if available, else generate
      String importId = jsonData['matchId']?.toString() ?? const Uuid().v4();

      Map<String, dynamic> matchData = {
        'id': importId,
        'matchDetails': matchDetailsJson,
        'innings1Data': innings1DataJson,
        'innings2Data': innings2DataJson,
        'isComplete': jsonData['isComplete'],
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'notes': jsonData['notes'],
        'currentInnings': jsonData['currentInnings'] ?? 1,
        'targetToChase': jsonData['targetToChase'] ?? 0,
        'firstInningScore': jsonData['firstInningScore'] ?? 0,
        'firstInningOuts': jsonData['firstInningOuts'] ?? 0,
      };

      return await insertOrUpdateMatch(matchData);
    } catch (e) {
      print('Error importing: $e');
      return null;
    }
  }

  bool _validateJsonStructure(Map<String, dynamic> jsonData) {
    return jsonData.containsKey('matchDetails') && jsonData.containsKey('innings1Data') && jsonData.containsKey('innings2Data');
  }

  Future<String?> getMatchAsJsonString(String matchId) async {
    final jsonData = await exportMatchToJson(matchId);
    return jsonData != null ? jsonEncode(jsonData) : null;
  }

  Future<String?> importMatchFromJsonString(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return await importMatchFromJson(jsonData);
    } catch (e) {
      return null;
    }
  }
}