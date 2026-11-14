class OpcaoVeiculo {
  final String codigo;
  final String nome;

  const OpcaoVeiculo({
    required this.codigo,
    required this.nome,
  });

  factory OpcaoVeiculo.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo'];
    final nome = json['nome'];

    if (codigo == null || nome is! String || nome.trim().isEmpty) {
      throw const FormatException('Opção de veículo inválida.');
    }

    return OpcaoVeiculo(
      codigo: codigo.toString(),
      nome: nome.trim(),
    );
  }
}