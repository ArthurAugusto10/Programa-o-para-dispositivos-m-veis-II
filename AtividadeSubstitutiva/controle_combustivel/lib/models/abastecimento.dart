enum TipoCombustivel {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  final String descricao;

  const TipoCombustivel(this.descricao);
}

class Abastecimento {
  final int? id;
  final int veiculoId;
  final TipoCombustivel combustivel;
  final double precoLitro;
  final double quilometragem;
  final double litros;
  final DateTime dataHora;

  const Abastecimento({
    this.id,
    required this.veiculoId,
    required this.combustivel,
    required this.precoLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
  });

  double get valorTotal => precoLitro * litros;

  double distanciaDesde(Abastecimento anterior) {
    return quilometragem - anterior.quilometragem;
  }

  double? consumoDesde(Abastecimento anterior) {
    final distancia = distanciaDesde(anterior);

    if (veiculoId != anterior.veiculoId ||
        !dataHora.isAfter(anterior.dataHora) ||
        distancia <= 0 ||
        litros <= 0) {
      return null;
    }

    return distancia / litros;
  }

  double? custoPorKmDesde(Abastecimento anterior) {
    final distancia = distanciaDesde(anterior);

    if (veiculoId != anterior.veiculoId ||
        !dataHora.isAfter(anterior.dataHora) ||
        distancia <= 0 ||
        litros <= 0 ||
        precoLitro <= 0) {
      return null;
    }

    return valorTotal / distancia;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'veiculo_id': veiculoId,
      'combustivel': combustivel.name,
      'preco_litro': precoLitro,
      'quilometragem': quilometragem,
      'litros': litros,
      'data_hora': dataHora.toUtc().toIso8601String(),
    };
  }

  factory Abastecimento.fromMap(Map<String, Object?> map) {
    return Abastecimento(
      id: (map['id'] as num?)?.toInt(),
      veiculoId: (map['veiculo_id'] as num).toInt(),
      combustivel: TipoCombustivel.values.byName(
        map['combustivel'] as String,
      ),
      precoLitro: (map['preco_litro'] as num).toDouble(),
      quilometragem: (map['quilometragem'] as num).toDouble(),
      litros: (map['litros'] as num).toDouble(),
      dataHora: DateTime.parse(map['data_hora'] as String).toLocal(),
    );
  }
}