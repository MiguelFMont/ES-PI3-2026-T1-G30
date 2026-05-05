/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
responsável por fazer as chamadas HTTP para o backend (Firebase Functions)
ele usa a url do backend e busca os dados 
*/

// importa o pacote http para fazer as requisições
import 'package:http/http.dart' as http;
// importa o dart:convert para converter JSON em Map
import 'dart:convert';
// importa os models 
import '../../domain/models/wallet_model.dart';
import '../../domain/models/participacao_model.dart';
import '../../domain/models/operacao_model.dart';

// classe responsável por fazer as chamadas HTTP para o backend 
class PortfolioDatasource {
    // url base do backend 
    final String _baseUrl;
    // construtor
    PortfolioDatasource(this._baseUrl);

    // busca todos os dados da carteira do usuário 
    Future<WalletModel> getWallet(String uid) async {
        // monta a url completa pra buscar os dados 
        final url = Uri.parse('$_baseUrl/api/v1/wallet/dashboard/$uid');
        // faz a requisição GET para o backend 
        final response = await http.get(
            url,
            // envia o header informando que esperamos JSON de volta
            headers: {'Content-Type': 'application/json'},
        );
        // verifica se a requisição foi bem sucedida 
        if (response.statusCode != 200) {
            throw Exception('Erro ao buscar dados da carteira');
        }
        // converte o body da resposta de String pra Map (jsonDecode) 
        final Map<String, dynamic> body = jsonDecode(response.body);
        // pega os dados do dashboard dentro do body 
        final Map<String, dynamic> dashboardData = body['dashboard'];
        // busca as participações do usuário
        final participacoes = await getParticipacoes(uid);
        // busca o histórico de operações
        final operacoes = await getOperacoes(uid);
        // monta e retorna o wallet model com os dados 
        return WalletModel.fromMap(uid, dashboardData, participacoes, operacoes);
    }

    // busca as participações do usuário
    Future<List<ParticipacaoModel>> getParticipacoes(String uid) async {
        final url = Uri.parse('$_baseUrl/api/v1/wallet/participacoes/$uid');
        final response = await http.get(
            url,
            headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode != 200) {
            throw Exception('Erro ao buscar participações');
        }
        final Map<String, dynamic> body = jsonDecode(response.body);
        // pega a lista de participações do body
        // converte para o formato list do dart
        final List participacoesData = body['participacoes'] as List;
        // parcorre a lista e converte cada item em participacao model
        return participacoesData.map((item) { 
            return ParticipacaoModel.fromMap(
                // pega o id 
                item['id'],
                // passa o map completo do item 
                item as Map<String, dynamic>,
            );
        }).toList();
    }

    // pega o histórico de operações do usuário
    Future<List<OperacaoModel>> getOperacoes(String uid) async {
        final url = Uri.parse('$_baseUrl/api/v1/wallet/historico/$uid');
        final response = await http.get (
            url,
            headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode != 200) {
            throw Exception('Erro ao buscar histórico de operações');
        }
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List operacoesData = body['operacoes'] as List;
        // percorre a lista e converte cada item em operacao model
        return operacoesData.map((item) {
            return OperacaoModel.fromMap(
                item['id'],
                item as Map<String, dynamic>,
            );
        }).toList();
    }
}