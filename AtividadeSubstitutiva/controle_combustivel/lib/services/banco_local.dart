import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocal {
  BancoLocal._();

  static final BancoLocal instancia = BancoLocal._();

  Future<Database>? _abertura;

  Future<Database> get banco async {
    final abertura = _abertura ??= _abrirBanco();

    try {
      return await abertura;
    } catch (_) {
      // Permite tentar novamente se a abertura falhar.
      if (identical(_abertura, abertura)) {
        _abertura = null;
      }
      rethrow;
    }
  }

  Future<Database> _abrirBanco() async {
    final pasta = await getDatabasesPath();
    final caminho = p.join(pasta, 'controle_combustivel.db');

    return openDatabase(
      caminho,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE veiculos (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            marca TEXT NOT NULL,
            modelo TEXT NOT NULL,
            ano INTEGER NOT NULL CHECK (ano > 0),
            cilindrada REAL NOT NULL CHECK (cilindrada > 0)
          )
        ''');

        await db.execute('''
          CREATE TABLE abastecimentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veiculo_id INTEGER NOT NULL,
            combustivel TEXT NOT NULL
              CHECK (combustivel IN ('etanol', 'gasolina', 'diesel')),
            preco_litro REAL NOT NULL CHECK (preco_litro > 0),
            quilometragem REAL NOT NULL CHECK (quilometragem >= 0),
            litros REAL NOT NULL CHECK (litros > 0),
            data_hora TEXT NOT NULL,
            FOREIGN KEY (veiculo_id)
              REFERENCES veiculos (id)
              ON DELETE CASCADE,
            UNIQUE (veiculo_id, data_hora)
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_abastecimentos_veiculo_data
          ON abastecimentos (veiculo_id, data_hora, id)
        ''');
      },
    );
  }
}