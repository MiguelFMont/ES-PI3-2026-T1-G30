/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
representa os dados gerais da carteira do usuário
o que aparece no card principal da tela
*/

import 'participacao_model.dart';
import 'operacao_model.dart';

class WalletModel {
  // uid do usuário da carteira (mesmo do Firebase Auth)
  final String uid;
  final double saldo;
  // lista de startups que o usuário possui tokens (participações)
  final List<ParticipacaoModel> participacoes;
  // lista das últimas operações do usuário
  final List<OperacaoModel> operacoes;

  const WalletModel({
    required this.uid,
    required this.saldo,
    required this.participacoes,
    required this.operacoes,
  });

  // calculo do valor total da carteira 
  double get valorTotalCarteira {
    // .fold() - percorre a lista acumulando os valores
    // comeca em 0.0 e soma o valor da posicão de cada participção
    return participacoes.fold (0.0,
    (soma, participacao) => soma + participacao.valorDaPosicao,
    );
  }
  // calculo do total investido 
  double get totalInvestido {
    return participacoes.fold (0.0, 
    (soma, participacao) => soma + participacao.totalInvestido,
    );
  }

  double get lucroTotal => valorTotalCarteira - totalInvestido;

  // calculo do retorno percentual 
  double get retornoPercent {
    if (totalInvestido == 0) return 0.0;
    return (lucroTotal / totalInvestido) * 100;
  }

  // tranforma o retorno do Firestore (Map) em instancia da classe (objeto dart)
  factory WalletModel.fromMap(String uid, Map<String, dynamic> map,
    List<ParticipacaoModel> participacoes, List<OperacaoModel> operacoes) {
      return WalletModel (
        uid: uid,
        saldo: (map['saldo'] ?? 0).toDouble(),
        participacoes: participacoes,
        operacoes: operacoes,
      );
    }
}