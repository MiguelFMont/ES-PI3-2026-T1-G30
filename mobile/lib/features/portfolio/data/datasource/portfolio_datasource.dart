/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
responsável por fazer as chamadas HTTP para o backend (Firebase Functions)
ele usa a url do backend e busca os dados 
envia o token JWT no header para autenticação 
endpoints usam esse token pra autenticação
*/

// importa o pacote http para fazer as requisições
import 'package:http/http.dart' as http;
// importa o dart:convert para converter JSON em Map
import 'dart:convert';
// importa os models 
import '../../domain/models/wallet_model.dart';
import '../../domain/models/participacao_model.dart';
import '../../domain/models/operacao_model.dart';
import '../../domain/models/startup_model.dart';

// classe responsável por fazer as chamadas HTTP para o backend 
class PortfolioDatasource {
    // url base do backend 
    final String _baseUrl;
    // token JWT do usuário autenticado
    // enviado no header de todas as requisições 
    final String _token;

    // construtor 
    PortfolioDatasource(this._baseUrl, this._token);

    // header padrão com o token JWT 
    Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    // busca os dados do dashboard 
    Future<Map<String, dynamic>> getDashboard(String uid) async {
        // url do endpoint do dashboard
        final url = Uri.parse('$_baseUrl/v1/wallet/dashboard');
        // faz a requisição GET pro endpoint com o header de autenticação
        final response = await http.get(url, headers: _headers);
        // caso de erro 
        if (response.statusCode != 200) {
          throw Exception('Erro ao buscar dados do dashboard');
        }
        // converte o corpo da resposta de JSON para Map
        final Map<String, dynamic> body = jsonDecode(response.body);
        // retorna o mapa do dashboard com os dados 
        return body['dashboard'] as Map<String, dynamic>;
    }

    // busca todos os dados da carteira do usuário 
    Future<WalletModel> getWallet(String uid) async {
        // busca os dados do dashboard (saldo disponível)
        final dashboardData = await getDashboard(uid);
        // busca as participações 
        final participacoes = await getParticipacoes();
        // busca o histórico de operações 
        final operacoes = await getOperacoes();
        // monta e retorna o walletmodel com os dados 
        return WalletModel.fromDashboard(
          uid,
          dashboardData,
          participacoes,
          operacoes,
        );
    }

    // busca as participações do usuário
    // usa o token JWT para identificar o usuário
    Future<List<ParticipacaoModel>> getParticipacoes() async {
        final url = Uri.parse('$_baseUrl/v1/wallet/holdings');
        final response = await http.get(url, headers: _headers);
        if (response.statusCode != 200) {
            throw Exception('Erro ao buscar participações');
        }
        final Map<String, dynamic> body = jsonDecode(response.body);
        // pega a lista de participações do body
        // converte para o formato list do dart
        final List items = body['items'] as List;
        // parcorre a lista e converte cada item em participacao model
        return items.map((item) { 
            return ParticipacaoModel.fromMap(item as Map<String, dynamic>);
        }).toList();
    }

    // pega o histórico de operações do usuário
    // usa o token JWT para identificar o usuário
    Future<List<OperacaoModel>> getOperacoes() async {
        final url = Uri.parse('$_baseUrl/v1/wallet/transactions');
        final response = await http.get (url, headers: _headers);
        if (response.statusCode != 200) {
            throw Exception('Erro ao buscar histórico de operações');
        }
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List items = body['items'] as List;
        // percorre a lista e converte cada item em operacao model
        return items.map((item) {
            final map = item as Map<String, dynamic>;
            return OperacaoModel.fromMap(map['id'], map);
        }).toList();
    }

    // pega lista de startups disponíveis para investimento 
    Future<List<StartupModel>> getStartups() async {
      final url = Uri.parse('$_baseUrl/v1/startups');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200){
        throw Exception('Erro ao buscar startups');
      }
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List items = (body['data'] ?? body['items'] ?? []) as List;
      return items.map((item) {
        return StartupModel.fromMap(item as Map<String, dynamic>);
      }).toList();
    }
}
