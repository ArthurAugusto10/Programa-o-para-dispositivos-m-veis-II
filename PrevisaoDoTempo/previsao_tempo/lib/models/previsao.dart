import 'cidade.dart';

class PrevisaoDia {
  final DateTime? data;
  final String codigoTempo;
  final double? minima;
  final double? maxima;
  final double? indiceUv;

  const PrevisaoDia({
    required this.data,
    required this.codigoTempo,
    required this.minima,
    required this.maxima,
    required this.indiceUv,
  });
}

class PrevisaoCidade {
  final Cidade cidade;
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  PrevisaoCidade({
    required this.cidade,
    required this.atualizacao,
    required List<PrevisaoDia> dias,
  }) : dias = List.unmodifiable(dias);
}