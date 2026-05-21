/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:
modelo de uma startup
representa os dados da startup que aparecem no card de participação
*/

class StartupModel {
  final String id;
  final String nome;
  final String logo;
  final String descricao;
  final String estagio;
  final double capitalAportado;
  final int totalTokens;
  final int tokensDisponiveis;
  final int precoTokenInicialCentavos;
  final int precoTokenAtualCentavos;

  const StartupModel({
    required this.id,
    required this.nome,
    required this.logo,
    required this.descricao,
    required this.estagio,
    required this.capitalAportado,
    required this.totalTokens,
    required this.tokensDisponiveis,
    required this.precoTokenInicialCentavos,
    required this.precoTokenAtualCentavos,
  });

  double get precoAtualReais => precoTokenAtualCentavos / 100;
  double get precoInicialReais => precoTokenInicialCentavos / 100;
  double get variacaoPercent {
    if (precoTokenInicialCentavos == 0) return 0;
    return ((precoTokenAtualCentavos - precoTokenInicialCentavos) /
        precoTokenInicialCentavos *
        100);
  }

  factory StartupModel.fromMap(Map<String, dynamic> map) {
    final precoInicial =
        (map['precoTokenInicialCentavos'] ?? map['precoInicialCentavos'] ?? 0)
            .toInt();
    final precoAtual =
        (map['precoTokenAtualCentavos'] ??
                map['precoAtualCentavos'] ??
                precoInicial)
            .toInt();

    return StartupModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      logo: map['logo'] ?? '',
      descricao: map['descricao'] ?? '',
      estagio: map['estagio'] ?? '',
      capitalAportado: (map['capitalAportado'] ?? 0).toDouble(),
      totalTokens: (map['totalTokens'] ?? 0).toInt(),
      tokensDisponiveis: (map['tokensDisponiveis'] ?? 0).toInt(),
      precoTokenInicialCentavos: precoInicial,
      precoTokenAtualCentavos: precoAtual,
    );
  }
}
