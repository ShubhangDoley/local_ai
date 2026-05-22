import 'package:local_ai/db/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper getInstance = DbHelper._();

  static final String table_name = 'Local_Ai';
  static final String col_name_text = 'text';
  static final DateTime col_name_datetime = DateTime.now();

  Database? myDB;

  Future<Database?> getDB() async {
    myDB ??= await openDB();
    return myDB!;
  }

  Future<Database?> openDB() async {
  
  }
  
}


