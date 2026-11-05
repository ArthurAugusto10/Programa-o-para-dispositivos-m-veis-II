
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/banco_localizacoes.dart';
import '../../models/localizacao.dart';

class RepositorioLocalizacoes {
  final BancoLocalizacoes _banco;

  RepositorioLocalizacoes({
    BancoLocalizacoes? banco,
  }) : _banco = banco ?? BancoLocalizacoes();

  // Armazenamento temporário utilizado somente na Web.
  static final List<Localizacao> _localizacoesWeb = [];

  // Simula o ID autoincrementável do SQLite.
  static int _proximoIdWeb = 1;

  // Salva uma localização.
  Future<int> salvar(Localizacao localizacao) async {
    if (kIsWeb) {
      final id = _proximoIdWeb++;

      final novaLocalizacao = Localizacao(
        id: id,
        latitude: localizacao.latitude,
        longitude: localizacao.longitude,
        precisao: localizacao.precisao,
        instante: localizacao.instante,
      );

      _localizacoesWeb.add(novaLocalizacao);

      return id;
    }

    // No Android, continua utilizando SQLite.
    final db = await _banco.database;

    final dados = localizacao.toMap();

    dados.remove('id');

    return await db.insert(
      BancoLocalizacoes.tabela,
      dados,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Consulta as últimas 100 localizações.
  Future<List<Localizacao>> buscarUltimas() async {
    if (kIsWeb) {
      final localizacoes = List<Localizacao>.from(
        _localizacoesWeb,
      );

      // Ordena da mais recente para a mais antiga.
      localizacoes.sort((a, b) {
        final comparacao =
            b.instante.compareTo(a.instante);

        if (comparacao != 0) {
          return comparacao;
        }

        return (b.id ?? 0).compareTo(a.id ?? 0);
      });

      return localizacoes.take(100).toList();
    }

    // Consulta SQLite no Android.
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

  // Exclui todas as localizações.
  Future<int> limpar() async {
    if (kIsWeb) {
      final quantidade = _localizacoesWeb.length;

      _localizacoesWeb.clear();

      return quantidade;
    }

    // Exclui os registros do SQLite.
    final db = await _banco.database;

    return await db.delete(
      BancoLocalizacoes.tabela,
    );
  }
}
