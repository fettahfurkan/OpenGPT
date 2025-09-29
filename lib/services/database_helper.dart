import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/system_prompt.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chatgpt5.db');
    return await openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Messages tablosu
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        imagePath TEXT,
        conversationId TEXT NOT NULL DEFAULT 'default'
      )
    ''');

    // Models tablosu
    await db.execute('''
      CREATE TABLE models(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        apiModel TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // API Keys tablosu
    await db.execute('''
      CREATE TABLE api_keys(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyName TEXT NOT NULL,
        keyValue TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Password tablosu
    await db.execute('''
      CREATE TABLE password(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        password TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Conversations tablosu
    await db.execute('''
      CREATE TABLE conversations(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        systemPromptId TEXT,
        messageCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // System prompts tablosu
    await db.execute('''
      CREATE TABLE system_prompts(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 0,
        isSystemPrompt INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Varsayılan modelleri ekle
    await _insertDefaultModels(db);

    // Varsayılan API key'i ekle
    await _insertDefaultApiKey(db);

    // Varsayılan şifreyi ekle
    await _insertDefaultPassword(db);

    // Varsayılan sistem promptunu ekle
    await _insertDefaultSystemPrompt(db);

    // Varsayılan konuşmayı ekle
    await _insertDefaultConversation(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Password tablosu ekle
      await db.execute('''
        CREATE TABLE password(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          password TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      // Varsayılan şifreyi ekle
      await _insertDefaultPassword(db);
    }

    if (oldVersion < 3) {
      // Conversations tablosu ekle
      await db.execute('''
        CREATE TABLE conversations(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          systemPromptId TEXT,
          messageCount INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // System prompts tablosu ekle
      await db.execute('''
        CREATE TABLE system_prompts(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isDefault INTEGER NOT NULL DEFAULT 0,
          isActive INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Varsayılan sistem promptunu ekle
      await _insertDefaultSystemPrompt(db);

      // Varsayılan konuşmayı ekle
      await _insertDefaultConversation(db);
    }

    if (oldVersion < 4) {
      // Eski modelleri temizle ve yeni modelleri ekle
      await db.delete('models');
      await _insertDefaultModels(db);
    }

    if (oldVersion < 5) {
      // Yeni sistem prompt'larını ekle
      final newPrompts = [
        SystemPrompt.yetiskinModTroll(),
        SystemPrompt.doktor(),
        SystemPrompt.avukat(),
        SystemPrompt.erkekSevgili(),
        SystemPrompt.kadinSevgili(),
        SystemPrompt.psikolog(),
        SystemPrompt.kanka(),
        SystemPrompt.camiHocasi(),
        SystemPrompt.falci(),
        SystemPrompt.gericiArkadas(),
        SystemPrompt.destekciArkadas(),
        SystemPrompt.kadinPlus18(),
        SystemPrompt.erkekPlus18(),
        SystemPrompt.cinsellikAsistani(),
      ];

      for (final prompt in newPrompts) {
        await db.insert('system_prompts', prompt.toMap());
      }
    }

    if (oldVersion < 6) {
      // Version 6 için sistem prompt'larını yeniden düzenle
      await db.delete('system_prompts');
      await _insertDefaultSystemPrompt(db);
    }

    if (oldVersion <= 7) {
      // Version 7 için doktor prompt'unu güncelle
      await db.update(
        'system_prompts',
        {
          'content':
              'You are Dr. Ayşe Yılmaz, a board-certified internal medicine specialist with 20 years of experience. From now on, act like a doctor in all conversations. Listen to users\' symptoms, gently explain possible causes, provide healthy living advice, and recommend they see a doctor when necessary. Always include this disclaimer: "This is for general information and role-playing purposes only; please consult a professional for actual medical advice." Be professional, empathetic, and ethical. Explain medical terms in simple terms. Always talk Turkish.',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: ['sp_doktor'],
      );
    }

    if (oldVersion < 5) {
      // Eski versiyonlarda system prompts tablosu yoksa oluştur
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_prompts(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isDefault INTEGER NOT NULL DEFAULT 0,
          isActive INTEGER NOT NULL DEFAULT 0,
          isSystemPrompt INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 9) {
      // Version 9 için isSystemPrompt kolonunu ekle (eğer yoksa)
      try {
        await db.execute(
          'ALTER TABLE system_prompts ADD COLUMN isSystemPrompt INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        // Kolon zaten varsa hata verir, görmezden gel
      }
    }

    if (oldVersion <= 9) {
      // Version 9 için tüm sistem prompt'larını yeniden yükle
      await db.delete('system_prompts');
      await _insertDefaultSystemPrompt(db);
    }

    if (oldVersion < 10) {
      // Version 10 için sistem prompt'larını yeniden yükle
      await db.delete('system_prompts');
      await _insertDefaultSystemPrompt(db);
    }
  }

  Future<void> _insertDefaultModels(Database db) async {
    final defaultModels = [
      {
        'name': 'Sonoma Dusk Alpha',
        'apiModel': 'openrouter/sonoma-dusk-alpha',
        'isActive': 0,
      },
      {
        'name': 'Sonoma Sky Alpha',
        'apiModel': 'openrouter/sonoma-sky-alpha',
        'isActive': 1,
      },
      {
        'name': 'Deepseek Chat V3.1',
        'apiModel': 'deepseek/deepseek-chat-v3.1:free',
        'isActive': 0,
      },
      {
        'name': 'Nemotron Nano 9B',
        'apiModel': 'nvidia/nemotron-nano-9b-v2:free',
        'isActive': 0,
      },
      {
        'name': 'GPT OSS 120B',
        'apiModel': 'openai/gpt-oss-120b:free',
        'isActive': 0,
      },
      {
        'name': 'Dolphin Mistral Venice',
        'apiModel':
            'cognitivecomputations/dolphin-mistral-24b-venice-edition:free',
        'isActive': 0,
      },
      {
        'name': 'Gemini 2.5 Flash Lite',
        'apiModel': 'google/gemini-2.5-flash-lite',
        'isActive': 0,
      },
      {
        'name': 'Gemini 2.0 Flash',
        'apiModel': 'google/gemini-2.0-flash-001',
        'isActive': 0,
      },
      {
        'name': 'Gemini 2.5 Flash',
        'apiModel': 'google/gemini-2.5-flash',
        'isActive': 0,
      },
      {
        'name': 'Anubis 70B',
        'apiModel': 'thedrummer/anubis-70b-v1.1',
        'isActive': 0,
      },
    ];

    for (var model in defaultModels) {
      await db.insert('models', model);
    }
  }

  Future<void> _insertDefaultApiKey(Database db) async {
    await db.insert('api_keys', {
      'keyName': 'Varsayılan',
      'keyValue': '1234',
      'isActive': 1,
    });
  }

  // MESSAGE OPERATIONS
  Future<int> insertMessage(
    ChatMessage message, {
    String conversationId = 'default',
  }) async {
    final db = await database;
    return await db.insert('messages', {
      'content': message.content,
      'isUser': message.isUser ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
      'imagePath': message.imagePath,
      'conversationId': conversationId,
    });
  }

  Future<List<ChatMessage>> getMessages({
    String conversationId = 'default',
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage(
        content: maps[i]['content'],
        isUser: maps[i]['isUser'] == 1,
        timestamp: DateTime.parse(maps[i]['timestamp']),
        imagePath: maps[i]['imagePath'],
      );
    });
  }

  Future<void> clearMessages({String conversationId = 'default'}) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteMessage(int id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // MODEL OPERATIONS
  Future<int> insertModel(String name, String apiModel) async {
    final db = await database;
    return await db.insert('models', {
      'name': name,
      'apiModel': apiModel,
      'isActive': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getModels() async {
    final db = await database;
    return await db.query('models', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getActiveModel() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'models',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> setActiveModel(int modelId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Tüm modelleri pasif yap
      await txn.update('models', {'isActive': 0});
      // Seçilen modeli aktif yap
      await txn.update(
        'models',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [modelId],
      );
    });
  }

  Future<void> deleteModel(int id) async {
    final db = await database;
    await db.delete('models', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateModel(int id, String name, String apiModel) async {
    final db = await database;
    await db.update(
      'models',
      {'name': name, 'apiModel': apiModel},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // API KEY OPERATIONS
  Future<int> insertApiKey(String keyName, String keyValue) async {
    final db = await database;
    return await db.insert('api_keys', {
      'keyName': keyName,
      'keyValue': keyValue,
      'isActive': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getApiKeys() async {
    final db = await database;
    return await db.query('api_keys', orderBy: 'keyName ASC');
  }

  Future<Map<String, dynamic>?> getActiveApiKey() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'api_keys',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> setActiveApiKey(int keyId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Tüm API key'leri pasif yap
      await txn.update('api_keys', {'isActive': 0});
      // Seçilen API key'i aktif yap
      await txn.update(
        'api_keys',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [keyId],
      );
    });
  }

  Future<void> deleteApiKey(int id) async {
    final db = await database;
    await db.delete('api_keys', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateApiKey(int id, String keyName, String keyValue) async {
    final db = await database;
    await db.update(
      'api_keys',
      {'keyName': keyName, 'keyValue': keyValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // PASSWORD OPERATIONS
  Future<void> _insertDefaultPassword(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('password', {
      'password': '12345',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> _insertDefaultSystemPrompt(Database db) async {
    final defaultPrompts = [
      SystemPrompt.defaultPrompt(),
      SystemPrompt.yetiskinModTroll(),
      SystemPrompt.doktor(),
      SystemPrompt.avukat(),
      SystemPrompt.erkekSevgili(),
      SystemPrompt.kadinSevgili(),
      SystemPrompt.psikolog(),
      SystemPrompt.kanka(),
      SystemPrompt.camiHocasi(),
      SystemPrompt.falci(),
      SystemPrompt.gericiArkadas(),
      SystemPrompt.destekciArkadas(),
      SystemPrompt.kadinPlus18(),
      SystemPrompt.erkekPlus18(),
      SystemPrompt.cinsellikAsistani(),
    ];

    for (final prompt in defaultPrompts) {
      await db.insert('system_prompts', prompt.toMap());
    }
  }

  Future<void> _insertDefaultConversation(Database db) async {
    final defaultConversation = Conversation.create(
      title: 'Varsayılan Konuşma',
    );
    await db.insert('conversations', defaultConversation.toMap());
  }

  Future<String?> getPassword() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'password',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['password'] as String;
    }
    return null;
  }

  Future<bool> verifyPassword(String inputPassword) async {
    final storedPassword = await getPassword();
    return storedPassword == inputPassword;
  }

  Future<void> updatePassword(String newPassword) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Mevcut şifreyi güncelle veya yeni şifre ekle
    final existingPassword = await getPassword();
    if (existingPassword != null) {
      await db.update('password', {
        'password': newPassword,
        'updatedAt': now,
      }, where: 'id = (SELECT MAX(id) FROM password)');
    } else {
      await db.insert('password', {
        'password': newPassword,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  // CONVERSATION OPERATIONS
  Future<String> insertConversation(Conversation conversation) async {
    final db = await database;
    await db.insert('conversations', conversation.toMap());
    return conversation.id;
  }

  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Conversation.fromMap(maps[i]);
    });
  }

  Future<Conversation?> getConversation(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Conversation.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateConversation(Conversation conversation) async {
    final db = await database;
    await db.update(
      'conversations',
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Konuşmaya ait mesajları sil
      await txn.delete(
        'messages',
        where: 'conversationId = ?',
        whereArgs: [conversationId],
      );
      // Konuşmayı sil
      await txn.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    });
  }

  Future<void> updateConversationMessageCount(
    String conversationId,
    int messageCount,
  ) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'messageCount': messageCount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // SYSTEM PROMPT OPERATIONS
  Future<String> insertSystemPrompt(SystemPrompt systemPrompt) async {
    final db = await database;
    await db.insert('system_prompts', systemPrompt.toMap());
    return systemPrompt.id;
  }

  Future<List<SystemPrompt>> getSystemPrompts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_prompts',
      orderBy: 'isDefault DESC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return SystemPrompt.fromMap(maps[i]);
    });
  }

  Future<SystemPrompt?> getActiveSystemPrompt() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_prompts',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SystemPrompt.fromMap(maps.first);
    }
    return null;
  }

  Future<SystemPrompt?> getSystemPrompt(String systemPromptId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_prompts',
      where: 'id = ?',
      whereArgs: [systemPromptId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SystemPrompt.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateSystemPrompt(SystemPrompt systemPrompt) async {
    final db = await database;
    await db.update(
      'system_prompts',
      systemPrompt.toMap(),
      where: 'id = ?',
      whereArgs: [systemPrompt.id],
    );
  }

  Future<void> setActiveSystemPrompt(String systemPromptId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Tüm sistem promptlarını pasif yap
      await txn.update('system_prompts', {'isActive': 0});
      // Seçilen sistem promptunu aktif yap
      await txn.update(
        'system_prompts',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [systemPromptId],
      );
    });
  }

  Future<void> deleteSystemPrompt(String systemPromptId) async {
    final db = await database;
    // Varsayılan sistem promptunu silmeye izin verme
    final systemPrompt = await getSystemPrompt(systemPromptId);
    if (systemPrompt != null && !systemPrompt.isDefault) {
      await db.delete(
        'system_prompts',
        where: 'id = ?',
        whereArgs: [systemPromptId],
      );
    }
  }

  // UTILITY OPERATIONS
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'chatgpt5.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
