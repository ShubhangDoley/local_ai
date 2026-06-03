import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper getInstance = DbHelper._();

  static const String tableName = 'Local_Ai';
  static const String colNameText = 'text';
  static const String colNameRole = 'role';
  static const String colNameTime = 'timestamp';

  Database? _myDB;

  Future<Database> getDB() async {
    _myDB ??= await openDB();
    return _myDB!;
  }

  Future<Database> openDB() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = join(dir.path, 'chat_history.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $colNameText TEXT,
            $colNameRole TEXT,
            $colNameTime TEXT
          )
        ''');
      },
    );
  }
}
