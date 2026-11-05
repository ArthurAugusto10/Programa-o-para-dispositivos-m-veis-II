import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:coletor_localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:coletor_localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:coletor_localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';

// Banco de dados exclusivo para os testes.
class BancoLocalizacoesTeste extends BancoLocalizacoes {
  final Database bancoTeste;

  BancoLocalizacoesTeste(this.bancoTeste);

  @override
  Future<Database> get database async => bancoTeste;
}

void main() {
  // Inicializa o SQLite para o ambiente de testes.
  sqfliteFfiInit();

  late Database bancoTeste;
  late RepositorioLocalizacoes repositorio;

  setUp(() async {
    bancoTeste = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE localizacoes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              precisao REAL NOT NULL,
              instante TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    repositorio = RepositorioLocalizacoes(
      banco: BancoLocalizacoesTeste(bancoTeste),
    );
  });

  tearDown(() async {
    await bancoTeste.close();
  });

  test('Deve salvar, consultar e limpar localizações', () async {
    final localizacao = Localizacao(
      latitude: -23.1791,
      longitude: -45.8872,
      precisao: 5.5,
      instante: DateTime.utc(2026, 11, 3, 12, 0),
    );

    // 1. Salvar
    final id = await repositorio.salvar(localizacao);

    expect(id, greaterThan(0));

    // 2. Consultar
    final localizacoes = await repositorio.buscarUltimas();

    expect(localizacoes.length, 1);
    expect(localizacoes.first.latitude, -23.1791);
    expect(localizacoes.first.longitude, -45.8872);
    expect(localizacoes.first.precisao, 5.5);
    expect(localizacoes.first.id, id);

    // 3. Limpar
    final quantidadeExcluida = await repositorio.limpar();

    expect(quantidadeExcluida, 1);

    final resultadoFinal = await repositorio.buscarUltimas();

    expect(resultadoFinal, isEmpty);
  });
}