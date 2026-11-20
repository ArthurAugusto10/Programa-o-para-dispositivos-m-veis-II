import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';

class CptecException implements Exception {
  final String mensagem;

  const CptecException(this.mensagem);

  @override
  String toString() => mensagem;
}

class CptecService {
  static const _host = 'servicos.cptec.inpe.br';
  static const _limite = Duration(seconds: 20);

  Future<List<Cidade>> buscarCidades(String nome) async {
    final pesquisa = _removerAcentos(nome.trim().toLowerCase());

    if (pesquisa.isEmpty) {
      return [];
    }

    final uri = Uri.http(
      _host,
      '/XML/listaCidades',
      {'city': pesquisa},
    );

    final documento = await _consultarXml(uri);
    final raiz = documento.rootElement;

    if (raiz.name.local != 'cidades') {
      throw const CptecException(
        'O serviço retornou uma lista de cidades inválida.',
      );
    }

    final cidades = <Cidade>[];

    for (final elemento in raiz.findElements('cidade')) {
      final id = _texto(elemento, 'id');
      final nomeCidade = _texto(elemento, 'nome');
      final uf = _texto(elemento, 'uf');

      // Sem identificador ou nome não é possível selecionar a cidade.
      if (id.isEmpty || nomeCidade.isEmpty) {
        continue;
      }

      cidades.add(
        Cidade(
          id: id,
          nome: nomeCidade,
          uf: uf,
        ),
      );
    }

    return cidades;
  }

  Future<PrevisaoCidade> buscarPrevisao(Cidade cidade) async {
    if (!RegExp(r'^[1-9]\d*$').hasMatch(cidade.id)) {
      throw const CptecException(
        'A cidade não possui um identificador válido.',
      );
    }

    final uri = Uri.http(
      _host,
      '/XML/cidade/${cidade.id}/previsao.xml',
    );

    final documento = await _consultarXml(uri);
    final raiz = documento.rootElement;

    if (raiz.name.local != 'cidade') {
      throw const CptecException(
        'O serviço retornou uma previsão inválida.',
      );
    }

    final dias = raiz.findElements('previsao').map((elemento) {
      return PrevisaoDia(
        data: DateTime.tryParse(_texto(elemento, 'dia')),
        codigoTempo: _texto(elemento, 'tempo').toLowerCase(),
        minima: _numero(_texto(elemento, 'minima')),
        maxima: _numero(_texto(elemento, 'maxima')),
        indiceUv: _numero(_texto(elemento, 'iuv')),
      );
    }).toList();

    if (dias.isEmpty) {
      throw const CptecException(
        'Não há previsão disponível para esta cidade.',
      );
    }

    return PrevisaoCidade(
      cidade: cidade,
      atualizacao: DateTime.tryParse(_texto(raiz, 'atualizacao')),
      dias: dias,
    );
  }

   Future<XmlDocument> _consultarXml(Uri uri) async {
    final http.Response resposta;

    try {
      resposta = await http.get(uri).timeout(_limite);
    } on TimeoutException catch (erro) {
      debugPrint('CPTEC: tempo esgotado em $uri');
      debugPrint('Detalhes: $erro');

      throw const CptecException(
        'O serviço demorou para responder. Tente novamente.',
      );
    } on Exception catch (erro) {
      debugPrint('CPTEC: falha ao acessar $uri');
      debugPrint('Tipo: ${erro.runtimeType}');
      debugPrint('Detalhes: $erro');

      throw const CptecException(
        'Não foi possível conectar ao CPTEC/INPE. '
        'Verifique sua conexão e tente novamente.',
      );
    }

    if (resposta.statusCode != 200) {
      throw CptecException(
        'O CPTEC/INPE está indisponível no momento '
        '(HTTP ${resposta.statusCode}). Tente novamente.',
      );
    }

    if (resposta.bodyBytes.isEmpty) {
      throw const CptecException(
        'O serviço retornou uma resposta vazia.',
      );
    }

    try {
      final conteudo = _decodificar(resposta);
      return XmlDocument.parse(conteudo);
    } on Exception catch (erro) {
      debugPrint('CPTEC: falha ao interpretar XML de $uri');
      debugPrint('Detalhes: $erro');

      throw const CptecException(
        'O serviço retornou dados em formato inválido.',
      );
    }
  }

  String _decodificar(http.Response resposta) {
    // O XML pode declarar uma codificação diferente de UTF-8.
    final inicio = latin1.decode(
      resposta.bodyBytes.take(200).toList(),
    ).toLowerCase();

    final tipo = (resposta.headers['content-type'] ?? '').toLowerCase();

    if (inicio.contains('iso-8859-1') ||
        tipo.contains('iso-8859-1')) {
      return latin1.decode(resposta.bodyBytes);
    }

    try {
      return utf8.decode(resposta.bodyBytes);
    } on FormatException {
      return latin1.decode(resposta.bodyBytes);
    }
  }

  String _texto(XmlElement elemento, String campo) {
    return elemento.getElement(campo)?.innerText.trim() ?? '';
  }

  double? _numero(String valor) {
    final numero = double.tryParse(valor.replaceAll(',', '.'));

    return numero != null && numero.isFinite ? numero : null;
  }

  String _removerAcentos(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const semAcento = 'aaaaaeeeeiiiiooooouuuuc';

    var resultado = texto;

    for (var i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }

    return resultado;
  }
}