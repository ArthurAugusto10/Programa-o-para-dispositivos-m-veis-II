import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/opcao_veiculo.dart';

class ApiVeiculos {
  static const String _dominio = 'parallelum.com.br';
  static const String _base = '/fipe/api/v1/carros';

  Future<List<OpcaoVeiculo>> buscarMarcas() async {
    final dados = await _consultar('$_base/marcas');

    return _converterLista(dados);
  }

  Future<List<OpcaoVeiculo>> buscarModelos(String codigoMarca) async {
    if (codigoMarca.trim().isEmpty) {
      throw ArgumentError('Selecione uma marca.');
    }

    final codigo = Uri.encodeComponent(codigoMarca);

    final dados = await _consultar(
      '$_base/marcas/$codigo/modelos',
    );

    if (dados is! Map<String, dynamic>) {
      throw const FormatException('Resposta de modelos inválida.');
    }

    return _converterLista(dados['modelos']);
  }

  Future<dynamic> _consultar(String caminho) async {
    final uri = Uri.https(_dominio, caminho);

    try {
      final resposta = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (resposta.statusCode == 429) {
        throw Exception(
          'Limite de consultas atingido. Tente novamente mais tarde.',
        );
      }

      if (resposta.statusCode != 200) {
        throw Exception(
          'Não foi possível consultar os veículos '
          '(HTTP ${resposta.statusCode}).',
        );
      }

      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on TimeoutException {
      throw Exception(
        'A consulta demorou demais. Tente novamente.',
      );
    } on http.ClientException {
      throw Exception(
        'Não foi possível conectar à API. Verifique sua internet.',
      );
    } on FormatException {
      throw Exception(
        'A API retornou dados em um formato inesperado.',
      );
    }
  }

  List<OpcaoVeiculo> _converterLista(dynamic dados) {
    if (dados is! List) {
      throw const FormatException('Lista de veículos inválida.');
    }

    final opcoes = dados.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Item da lista inválido.');
      }

      return OpcaoVeiculo.fromJson(item);
    }).toList();

    opcoes.sort(
      (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );

    return opcoes;
  }
}