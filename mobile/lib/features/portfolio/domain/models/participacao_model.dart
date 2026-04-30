/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
representa uma startup que o usuário é investidor (tem tokens)
*/

class ParticipacaoModel {
  final String id;
  final String nome;
  final String categoria;
  final String estagio;
  final String logoUrl;
  final int tokens;
  final double precoMedio;
  final double precoAtual;
  // porcentagem da valorizacao do token 
  final double variacaoPercent;

  const ParticipacaoModel({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.estagio,
    required this.logoUrl,
    required this.tokens,
    required this.precoMedio,
    required this.precoAtual,
    required this.variacaoPercent,
  });

  // calculo da posição (quanto os tokens comprados estão valendo atualmente)
  double get valorDaPosicao => tokens * precoAtual;
  // calculo do quanto o usuario investiu na época da compra 
  double get totalInvestido => tokens * precoMedio;
  // calculo do lucro/prejuízo 
  double get lucro => valorDaPosicao - totalInvestido;

  // tranforma o retorno do Firestore (Map) em instancia da classe (objeto dart)
  factory ParticipacaoModel.fromMap(String id, Map<String, dynamic> map) {
    return ParticipacaoModel(
      id: id,
      nome: map['nome'] ?? '',
      categoria : map['categoria'] ?? '',
      estagio: map['estagio'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      tokens: (map['tokens'] ?? 0).toInt(),
      precoMedio: (map['precoMedio'] ?? 0).toDouble(),
      precoAtual: (map['precoAtual'] ?? 0).toDouble(),
      variacaoPercent: (map['variacaoPercent'] ?? 0).toDouble(),
    );
  }
}