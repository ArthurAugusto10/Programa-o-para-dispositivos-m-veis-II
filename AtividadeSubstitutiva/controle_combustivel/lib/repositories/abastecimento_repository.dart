import '../models/abastecimento.dart';
import '../services/banco_local.dart';

class AbastecimentoRepository {
  Future<List<Abastecimento>> listar(int veiculoId) async {
    final db = await BancoLocal.instancia.banco;

    final registros = await db.query(
      'abastecimentos',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
    );

    final abastecimentos = registros
        .map(Abastecimento.fromMap)
        .toList();

    // Compara os instantes reais, sem depender da ordenação do texto.
    abastecimentos.sort((a, b) => a.dataHora.compareTo(b.dataHora));

    return abastecimentos;
  }

  Future<int> cadastrar(Abastecimento abastecimento) async {
    _validarCampos(abastecimento);

    final db = await BancoLocal.instancia.banco;

    return db.transaction((txn) async {
      final veiculos = await txn.query(
        'veiculos',
        where: 'id = ?',
        whereArgs: [abastecimento.veiculoId],
        limit: 1,
      );

      if (veiculos.isEmpty) {
        throw StateError('Cadastre um veículo antes de abastecer.');
      }

      final registros = await txn.query(
        'abastecimentos',
        where: 'veiculo_id = ?',
        whereArgs: [abastecimento.veiculoId],
      );

      for (final registro in registros) {
        final existente = Abastecimento.fromMap(registro);

        final comparacao = abastecimento.dataHora.compareTo(
          existente.dataHora,
        );

        if (comparacao == 0) {
          throw StateError(
            'Já existe um abastecimento nessa data e horário.',
          );
        }

        if (comparacao > 0 &&
            abastecimento.quilometragem <= existente.quilometragem) {
          throw StateError(
            'A quilometragem deve ser maior que a dos '
            'abastecimentos anteriores.',
          );
        }

        if (comparacao < 0 &&
            abastecimento.quilometragem >= existente.quilometragem) {
          throw StateError(
            'A quilometragem deve ser menor que a dos '
            'abastecimentos posteriores.',
          );
        }
      }

      final dados = abastecimento.toMap();
      dados.remove('id');

      return txn.insert('abastecimentos', dados);
    });
  }

  void _validarCampos(Abastecimento abastecimento) {
    if (!abastecimento.precoLitro.isFinite ||
        abastecimento.precoLitro <= 0) {
      throw ArgumentError('Informe um preço por litro maior que zero.');
    }

    if (!abastecimento.litros.isFinite || abastecimento.litros <= 0) {
      throw ArgumentError('Informe uma quantidade de litros maior que zero.');
    }

    if (!abastecimento.quilometragem.isFinite ||
        abastecimento.quilometragem < 0) {
      throw ArgumentError('Informe uma quilometragem válida.');
    }

    if (!abastecimento.valorTotal.isFinite) {
      throw ArgumentError('O valor total do abastecimento é inválido.');
    }

    if (abastecimento.dataHora.isAfter(DateTime.now())) {
      throw ArgumentError(
        'A data e o horário não podem estar no futuro.',
      );
    }
  }
}