/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
modelo de uma participação do usuário em uma startup
representa uma startup específica que o usuário é investidor (tem tokens)
*/

class ParticipacaoModel {
  final String startupId;
  final int quantidade;
  final int quantidadeBloqueada;
  final double precoMedioCentavos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParticipacaoModel({
    required this.startupId,
    required this.quantidade,
    required this.quantidadeBloqueada,
    required this.precoMedioCentavos,
    required this.createdAt,
    required this.updatedAt,
  });

  // preço médio em reais
  double get precoMedio => precoMedioCentavos / 100;
  // posse total inclui tokens livres e bloqueados em ofertas abertas
  int get totalTokens => quantidade + quantidadeBloqueada;
  // valor total da posição em reais
  double get valorDaPosicao => totalTokens * precoMedio;
  // total investido em reais
  double get totalInvestido => valorDaPosicao;

  // tranforma o retorno do Firestore (Map) em instancia da classe (objeto dart)
  factory ParticipacaoModel.fromMap(Map<String, dynamic> map) {
    return ParticipacaoModel(
      startupId: map['startupId'] ?? '',
      quantidade: (map['quantidade'] ?? 0).toInt(),
      quantidadeBloqueada: (map['quantidadeBloqueada'] ?? 0).toInt(),
      precoMedioCentavos: (map['precoMedioCentavos'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
