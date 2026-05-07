// Autor: Caio Ávila Marchi
// RA: 25008101

import { Timestamp } from 'firebase-admin/firestore';

export interface Question {
  id?: string;
  startupId: string;       // ID da startup que a pergunta pertence
  autorId: string;         // ID do usuário que fez a pergunta
  autorNome: string;       // Nome exibido
  texto: string;           // Texto da pergunta
  isPublica: boolean;      // true = visível a todos; false = só para investidores
  resposta?: string;       // Preenchido quando a equipe responder
  respondidoPor?: string;  // Quem respondeu
  respondidoEm?: Timestamp;
  criadoEm: Timestamp;
}

export interface CreateQuestionDTO {
  startupId: string;
  texto: string;
  isPublica: boolean;
}

export interface AnswerQuestionDTO {
  resposta: string;
  respondidoPor: string;
}
