// Autor: Caio Ávila Marchi
// RA: 25008101

class Question {
  final String id;
  final String autorNome;
  final String texto;
  final bool isPublica;
  final String? resposta;
  final String? respondidoPor;

  Question({
    required this.id,
    required this.autorNome,
    required this.texto,
    required this.isPublica,
    this.resposta,
    this.respondidoPor,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      autorNome: json['autorNome'] ?? '',
      texto: json['texto'] ?? '',
      isPublica: json['isPublica'] ?? true,
      resposta: json['resposta'],
      respondidoPor: json['respondidoPor'],
    );
  }
}
