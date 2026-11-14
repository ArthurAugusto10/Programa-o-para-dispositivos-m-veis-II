import 'package:flutter_test/flutter_test.dart';
import 'package:controle_combustivel/models/abastecimento.dart';

void main() {
  Abastecimento criar({
    required double km,
    required double litros,
    required double preco,
    required DateTime data,
    int veiculoId = 1,
  }) {
    return Abastecimento(
      veiculoId: veiculoId,
      combustivel: TipoCombustivel.gasolina,
      precoLitro: preco,
      quilometragem: km,
      litros: litros,
      dataHora: data,
    );
  }

  group('Cálculos de abastecimento', () {
    final primeiro = criar(
      km: 10000,
      litros: 40,
      preco: 6,
      data: DateTime(2026, 11, 1),
    );

    final segundo = criar(
      km: 10400,
      litros: 32,
      preco: 6,
      data: DateTime(2026, 11, 5),
    );

    test('Calcula o valor total', () {
      expect(primeiro.valorTotal, closeTo(240, 0.000001));
      expect(segundo.valorTotal, closeTo(192, 0.000001));
    });

    test('Calcula a distância entre abastecimentos', () {
      expect(segundo.distanciaDesde(primeiro), 400);
    });

    test('Calcula o consumo usando os litros do registro atual', () {
      expect(
        segundo.consumoDesde(primeiro),
        closeTo(12.5, 0.000001),
      );
    });

    test('Calcula o custo por quilômetro', () {
      expect(
        segundo.custoPorKmDesde(primeiro),
        closeTo(0.48, 0.000001),
      );
    });

    test('Não calcula indicadores quando a distância é zero', () {
      final atual = criar(
        km: 10000,
        litros: 30,
        preco: 6,
        data: DateTime(2026, 11, 5),
      );

      expect(atual.consumoDesde(primeiro), isNull);
      expect(atual.custoPorKmDesde(primeiro), isNull);
    });

    test('Não calcula indicadores com registros fora de ordem', () {
      expect(primeiro.consumoDesde(segundo), isNull);
      expect(primeiro.custoPorKmDesde(segundo), isNull);
    });

    test('Não compara abastecimentos de veículos diferentes', () {
      final outro = criar(
        km: 10400,
        litros: 32,
        preco: 6,
        data: DateTime(2026, 11, 5),
        veiculoId: 2,
      );

      expect(outro.consumoDesde(primeiro), isNull);
      expect(outro.custoPorKmDesde(primeiro), isNull);
    });

    test('Preserva os dados na conversão para armazenamento', () {
      final restaurado = Abastecimento.fromMap(segundo.toMap());

      expect(restaurado.veiculoId, segundo.veiculoId);
      expect(restaurado.combustivel, segundo.combustivel);
      expect(restaurado.precoLitro, segundo.precoLitro);
      expect(restaurado.quilometragem, segundo.quilometragem);
      expect(restaurado.litros, segundo.litros);
      expect(
        restaurado.dataHora.isAtSameMomentAs(segundo.dataHora),
        isTrue,
      );
    });
  });
}