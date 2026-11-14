import '../models/veiculo.dart';
import '../services/banco_local.dart';

class VeiculoRepository {
  Future<Veiculo?> buscar() async {
    final db = await BancoLocal.instancia.banco;
    final registros = await db.query('veiculos', limit: 1);

    if (registros.isEmpty) {
      return null;
    }

    return Veiculo.fromMap(registros.first);
  }

  Future<void> cadastrar(Veiculo veiculo) async {
    if (veiculo.marca.trim().isEmpty ||
        veiculo.modelo.trim().isEmpty ||
        veiculo.ano <= 0 ||
        !veiculo.cilindrada.isFinite ||
        veiculo.cilindrada <= 0) {
      throw ArgumentError('Preencha os dados do veículo corretamente.');
    }

    final db = await BancoLocal.instancia.banco;

    await db.transaction((txn) async {
      final existentes = await txn.query('veiculos', limit: 1);

      if (existentes.isNotEmpty) {
        throw StateError(
          'Exclua o veículo atual antes de cadastrar outro.',
        );
      }

      final dados = veiculo.toMap();
      dados['id'] = 1;
      dados['marca'] = veiculo.marca.trim();
      dados['modelo'] = veiculo.modelo.trim();

      await txn.insert('veiculos', dados);
    });
  }

  Future<void> excluir() async {
    final db = await BancoLocal.instancia.banco;

    // O banco exclui também os abastecimentos vinculados.
    await db.delete(
      'veiculos',
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}