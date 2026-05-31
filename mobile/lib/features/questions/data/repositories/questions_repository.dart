// Autor: Caio Ávila Marchi
// RA: 25008101

import '../../domain/question_model.dart';
import '../datasource/questions_datasource.dart';

class QuestionsRepository {
  final _datasource = QuestionsDatasource();

  Future<List<Question>> buscarPublicas(String startupId, String token) =>
      _datasource.buscarPublicas(startupId, token);

  Future<void> enviarPergunta(
    String startupId,
    String texto,
    bool isPublica,
    String token,
  ) => _datasource.enviarPergunta(startupId, texto, isPublica, token);
}
