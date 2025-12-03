class Aluno {
  final String id;
  final String nome;
  Set<String> presencasRegistradas;

  Aluno({
    required this.id,
    required this.nome,
    Set<String>? presencasRegistradas,
  }) : presencasRegistradas = presencasRegistradas ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'presencasRegistradas': presencasRegistradas.toList(),
    };
  }

  factory Aluno.fromJson(Map<String, dynamic> json) {
    final lista = json['presencasRegistradas'] as List<dynamic>? ?? [];
    return Aluno(
      id: json['id'],
      nome: json['nome'],
      presencasRegistradas: lista.map((e) => e.toString()).toSet(),
    );
  }
}