/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
representa uma transação (compra ou venda) que o usuário fez
*/
 
// representa uma única operação (compra ou venda) do usuário
class OperacaoModel {
  // id da operação no firestore
  final String id;
  final String tipo;
  final String startupNome;
  final int quantidade;
  // preço por token (no momento da operação)
  final double preco;
  // data da operação
  final DateTime data;  

  const OperacaoModel({
    required this.id,
    required this.tipo,
    required this.startupNome,
    required this.quantidade,
    required this.preco,
    required this.data,
  });

  // método factory - converte um map (JSON do Firestore) em OperacaoModel
  // ele cria uma instancia da classe (objeto dart) a partir dos dados do Firestore
  // o Firestore retorna os dados no formato de Map (Map<String, dynamic>)
  factory OperacaoModel.fromMap(String id, Map<String, dynamic> map) {
    return OperacaoModel(
      // pega o id passado como parametro (id do documento do Firestore)
      id: id, 
      // pega o campo tipo do map 
      tipo: map['tipo'] ?? '',
      // pega o campo startupNome do map
      startupNome: map['startupNome'] ?? '',
      // converte o campo quantidade para int 
      quantidade: (map['quantidade'] ?? 0).toInt(),
      // converte o campo preco para double
      preco: (map['preco'] ?? 0).toDouble(),
      // converte o campo data (Timestamp do Firestore) para DateTime
      data: (map['data'] as dynamic).toDate(),
    );
  }

  // calculo do valor total da operacao
  // não precisa salvar no banco
  double get valorTotal => quantidade * preco; 

}