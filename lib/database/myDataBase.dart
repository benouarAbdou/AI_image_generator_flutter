import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDb {
  static Database? _db;

  Future<Database?> get db async {
    if (_db == null) {
      _db = await _initialDb();
      return _db;
    } else {
      return _db;
    }
  }

  Future<Database> _initialDb() async {
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, 'recipes.db');
    Database myDb = await openDatabase(
      path,
      onCreate: _onCreate,
      version: 2,
      onOpen: _onOpen,
    );
    return myDb;
  }

  Future<void> _onOpen(Database db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute("PRAGMA foreign_keys = ON");

    await db.execute(
        '''
CREATE TABLE "messages" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "text" TEXT NOT NULL,
  "isUser" INTEGER NOT NULL,
  "imageData" BLOB,
  "prompt" TEXT
)''');
  }

  Future<List<Map<String, dynamic>>> readData(String sql) async {
    Database? myDb = await db;
    List<Map<String, dynamic>> response = await myDb!.rawQuery(sql);
    return response;
  }

  Future<int> insertData(String sql) async {
    Database? myDb = await db;
    int response = await myDb!.rawInsert(sql);
    return response;
  }

  Future<int> updateData(String sql) async {
    Database? myDb = await db;
    int response = await myDb!.rawUpdate(sql);
    return response;
  }

  Future<int> deleteData(String sql) async {
    Database? myDb = await db;
    int response = await myDb!.rawDelete(sql);
    return response;
  }

  Future<int> insertMessage(Message message) async {
    Database? myDb = await db;
    return await myDb!.insert('messages', message.toMap());
  }

  Future<List<Message>> getMessages() async {
    Database? myDb = await db;
    final List<Map<String, dynamic>> maps = await myDb!.query('messages');
    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  Future<void> clearMessages() async {
    Database? myDb = await db;
    await myDb!.delete('messages');
  }
}

class Message {
  final int? id;
  final String text;
  final bool isUser;
  final Uint8List? imageData;
  final String? prompt;

  Message({
    this.id,
    required this.text,
    required this.isUser,
    this.imageData,
    this.prompt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser ? 1 : 0,
      'imageData': imageData,
      'prompt': prompt,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      text: map['text'],
      isUser: map['isUser'] == 1,
      imageData: map['imageData'],
      prompt: map['prompt'],
    );
  }
}
