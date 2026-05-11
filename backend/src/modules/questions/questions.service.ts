// Autor: Caio Ávila Marchi
// RA: 25008101

import { QuestionsRepo } from './questions.repo';
import { CreateQuestionDTO, AnswerQuestionDTO } from './questions.model';
import { Timestamp } from 'firebase-admin/firestore';

const repo = new QuestionsRepo();

export class QuestionsService {

  // Lista perguntas públicas de uma startup (qualquer usuário autenticado)
  async listarPublicas(startupId: string) {
    return repo.findPublicasByStartup(startupId);
  }

  // Lista todas as perguntas de uma startup (para investidores)
  async listarTodas(startupId: string) {
    return repo.findAllByStartup(startupId);
  }

  // Envia uma nova pergunta para uma startup
  async criar(dto: CreateQuestionDTO, autorId: string, autorNome: string) {
    if (!dto.texto || dto.texto.trim() === '') {
      throw new Error('O texto da pergunta não pode estar vazio');
    }
    if (!dto.startupId) {
      throw new Error('startupId é obrigatório');
    }

    return repo.createQuestion({
      startupId: dto.startupId,
      autorId,
      autorNome,
      texto: dto.texto.trim(),
      isPublica: dto.isPublica ?? true,
      criadoEm: Timestamp.now(),
    });
  }

  // Responde uma pergunta existente
  async responder(id: string, dto: AnswerQuestionDTO) {
    const question = await repo.findById(id);
    if (!question) {
      throw new Error('Pergunta não encontrada');
    }
    if (!dto.resposta || dto.resposta.trim() === '') {
      throw new Error('A resposta não pode estar vazia');
    }

    return repo.answerQuestion(id, dto.resposta.trim(), dto.respondidoPor);
  }
}
