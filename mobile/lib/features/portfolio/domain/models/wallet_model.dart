/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
modelo da carteira do usuário
representa os dados gerais da carteira do usuário
o que aparece no card principal da tela
*/

import 'participacao_model.dart';
import 'operacao_model.dart';

class WalletModel {
  // uid do usuário da carteira (mesmo do Firebase Auth)
  final String uid;
  final double saldoCentavos;
  // lista de startups que o usuário possui tokens (holdings)
  final List<ParticipacaoModel> participacoes;
  // lista das operações do usuário
  final List<OperacaoModel> operacoes;

  const WalletModel({
    required this.uid,
    required this.saldoCentavos,
    required this.participacoes,
    required this.operacoes,
  });

  // saldo disponível em reais 
  double get saldo => saldoCentavos / 100;

  // calculo do valor total da carteira 
  // soma o valor de todas as participações 
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

  // calcula o lucro total
  double get lucroTotal => valorTotalCarteira - totalInvestido;

  // calculo do retorno percentual 
  double get retornoPercent {
    if (totalInvestido == 0) return 0.0;
    return (lucroTotal / totalInvestido) * 100;
  }

  // tranforma o retorno do Firestore (Map) em instancia da classe (objeto dart)
  factory WalletModel.fromDashboard(String uid, Map<String, dynamic> dashboardMap,
    List<ParticipacaoModel> participacoes, List<OperacaoModel> operacoes) {
      return WalletModel (
        uid: uid,
        // back retorna saldo em reais - converte para centavos 
        saldoCentavos: ((dashboardMap['saldoDisponivel'] ?? 0) * 100).toInt(),
        participacoes: participacoes,
        operacoes: operacoes,
      );
    }
}