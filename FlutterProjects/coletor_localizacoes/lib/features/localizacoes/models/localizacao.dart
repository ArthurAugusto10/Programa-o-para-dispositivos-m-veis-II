class Localizacao {
  final int? id;
  final double latitude;
  final double longitude;
  final double precisao;
  final DateTime instante;

  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  // Converte o objeto em um Map para o SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': instante.toUtc().toIso8601String(),
    };
  }

  // Converte os dados do SQLite em um objeto Localizacao.
  factory Localizacao.fromMap(Map<String, Object?> map) {
    return Localizacao(
      id: map['id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      precisao: (map['precisao'] as num).toDouble(),
      instante: DateTime.parse(map['instante'] as String),
    );
  }
}