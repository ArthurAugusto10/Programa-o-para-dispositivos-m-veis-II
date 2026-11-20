import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cidade.dart';

class ArmazenamentoService {
  late final _prefs = SharedPreferencesAsync();

  static const _chave = 'cidades_favoritas';

  Future<List<Cidade>> buscarFavoritas() async {
    final conteudo = await _prefs.getString(_chave);

    if (conteudo == null) return [];

    final dados = jsonDecode(conteudo);

    if (dados is! List) {
      throw const FormatException('Lista de favoritos inválida.');
    }

    final cidades = dados.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Cidade favorita inválida.');
      }

      final cidade = Cidade.fromJson(item);

      if (cidade.id.isEmpty || cidade.nome.isEmpty) {
        throw const FormatException('Cidade favorita incompleta.');
      }

      return cidade;
    }).toList();

    cidades.sort(
      (a, b) => a.nomeCompleto.compareTo(b.nomeCompleto),
    );

    return cidades;
  }

  Future<void> salvarFavorita(Cidade cidade) async {
    final cidades = await buscarFavoritas();

    // O identificador do serviço evita cidades duplicadas.
    cidades.removeWhere((item) => item.id == cidade.id);
    cidades.add(cidade);

    await _gravar(cidades);
  }

  Future<void> removerFavorita(String id) async {
    final cidades = await buscarFavoritas();

    cidades.removeWhere((cidade) => cidade.id == id);

    await _gravar(cidades);
  }

  Future<void> _gravar(List<Cidade> cidades) async {
    final conteudo = jsonEncode(
      cidades.map((cidade) => cidade.toJson()).toList(),
    );

    await _prefs.setString(_chave, conteudo);
  }
}