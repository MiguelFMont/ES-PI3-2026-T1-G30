/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
"ponte" entre a tela e o datasource  
trata os erros antes de chegar na tela 
recebe o token JWT e repassa pro datasource
*/

// importa o datasource 
import '../datasource/portfolio_datasource.dart';
// importa os models
import '../../domain/models/wallet_model.dart';
import '../../domain/models/participacao_model.dart';
import '../../domain/models/operacao_model.dart';
 
class PortfolioRepository {
  // instancia do datasource 
    final PortfolioDatasource _datasource;
    PortfolioRepository(this._datasource);
    
    // busca todos os dados da carteira do usuário 
    Future<WalletModel> getWallet(String uid) async {
      try {
        // chama o datasource e retorna o resultado
        return await _datasource.getWallet(uid);
      } catch (e) {
        // se der erro, lança uma exceção 
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    }

    // busca as participações do usuário
    Future<List<ParticipacaoModel>> getParticipacoes (String uid) async {
      try {
        return await _datasource.getParticipacoes();
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    }

    // busca o histórico de operações do usuário
    Future<List<OperacaoModel>> getOperacoes(String uid) async {
      try {
        return await _datasource.getOperacoes();
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    }
}