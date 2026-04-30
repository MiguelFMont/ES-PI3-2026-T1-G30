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

