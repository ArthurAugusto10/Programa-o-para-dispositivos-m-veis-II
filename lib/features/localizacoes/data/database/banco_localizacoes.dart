import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  static const String _nomeBanco = 'localizacoes.db';
  static const int _versaoBanco = 1;

  static const String tabela = 'localizacoes';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _inicializarBanco();
    return _database!;
  }

  Future<Database> _inicializarBanco() async {
    final caminho = join(
      await getDatabasesPath(),
      _nomeBanco,
    );

    return await openDatabase(
      caminho,
      version: _versaoBanco,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tabela (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}