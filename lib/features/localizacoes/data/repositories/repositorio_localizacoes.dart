import 'package:sqflite/sqflite.dart';

import '../database/banco_localizacoes.dart';
import '../../models/localizacao.dart';

class RepositorioLocalizacoes {
  final BancoLocalizacoes _banco;

  RepositorioLocalizacoes({
    BancoLocalizacoes? banco,
  }) : _banco = banco ?? BancoLocalizacoes();

  // Salva uma localização no banco.
  Future<int> salvar(Localizacao localizacao) async {
    final db = await _banco.database;

    final dados = localizacao.toMap();

    // O SQLite gera o ID automaticamente.
    dados.remove('id');

    return await db.insert(
      BancoLocalizacoes.tabela,
      dados,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Consulta as últimas 100 localizações.
  Future<List<Localizacao>> buscarUltimas() async {
    final db = await _banco.database;

    final resultado = await db.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: 100,
    );

    return resultado
        .map((registro) => Localizacao.fromMap(registro))
        .toList();
  }

  // Exclui todos os registros da tabela.
  Future<int> limpar() async {
    final db = await _banco.database;

    return await db.delete(
      BancoLocalizacoes.tabela,
    );
  }
}