class Veiculo {
  final int? id;
  final String marca;
  final String modelo;
  final int ano;
  final double cilindrada;

  const Veiculo({
    this.id,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cilindrada,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'cilindrada': cilindrada,
    };
  }

  factory Veiculo.fromMap(Map<String, Object?> map) {
    return Veiculo(
      id: (map['id'] as num?)?.toInt(),
      marca: map['marca'] as String,
      modelo: map['modelo'] as String,
      ano: (map['ano'] as num).toInt(),
      cilindrada: (map['cilindrada'] as num).toDouble(),
    );
  }
}