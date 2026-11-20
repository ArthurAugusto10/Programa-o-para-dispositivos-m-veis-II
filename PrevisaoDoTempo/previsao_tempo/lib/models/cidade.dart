class Cidade {
  final String id;
  final String nome;
  final String uf;

  const Cidade({
    required this.id,
    required this.nome,
    required this.uf,
  });

  String get nomeCompleto => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'uf': uf,
    };
  }

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
    );
  }
}