// Autor: Caio Ávila Marchi
// RA: 25008101

import { FirestoreBaseRepo } from '../../infra/repositories/firestore.base.repo';
import { getDb } from '../../config/firebase';
import { Question } from './questions.model';
import { Timestamp } from 'firebase-admin/firestore';

export class QuestionsRepo extends FirestoreBaseRepo {
  constructor() {
    super('questions');
  }

  // Busca todas as perguntas públicas de uma startup
  async findPublicasByStartup(startupId: string): Promise<Question[]> {
    const snapshot = await getDb()
      .collection('questions')
      .where('startupId', '==', startupId)
      .where('isPublica', '==', true)
      .orderBy('criadoEm', 'desc')
      .get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    } as Question));
  }

  // Busca todas as perguntas de uma startup (públicas + privadas — para investidores)
  async findAllByStartup(startupId: string): Promise<Question[]> {
    const snapshot = await getDb()
      .collection('questions')
      .where('startupId', '==', startupId)
      .orderBy('criadoEm', 'desc')
      .get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    } as Question));
  }

  // Cria uma nova pergunta
  async createQuestion(data: Omit<Question, 'id'>): Promise<string> {
    const ref = await getDb().collection('questions').add({
      ...data,
      criadoEm: Timestamp.now(),
    });
    return ref.id;
  }

  // Registra a resposta em uma pergunta existente
  async answerQuestion(
    id: string,
    resposta: string,
    respondidoPor: string
  ): Promise<void> {
    await getDb().collection('questions').doc(id).update({
      resposta,
      respondidoPor,
      respondidoEm: Timestamp.now(),
    });
  }
}
