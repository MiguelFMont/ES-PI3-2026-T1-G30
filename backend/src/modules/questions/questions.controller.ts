// Autor: Caio Ávila Marchi
// RA: 25008101

import { Request, Response } from 'express';
import { QuestionsService } from './questions.service';

const service = new QuestionsService();

export class QuestionsController {

  // GET /v1/questions/:startupId/publicas
  // Retorna perguntas públicas de uma startup (qualquer usuário autenticado)
  async listarPublicas(req: Request, res: Response) {
    try {
      const startupId = req.params.startupId as string;
      const questions = await service.listarPublicas(startupId);
      res.status(200).json({ data: questions });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  // GET /v1/questions/:startupId/todas
  // Retorna todas as perguntas (públicas + privadas) — para investidores
  async listarTodas(req: Request, res: Response) {
    try {
      const startupId = req.params.startupId as string;
      const questions = await service.listarTodas(startupId);
      res.status(200).json({ data: questions });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  // POST /v1/questions
  // Cria uma nova pergunta
  // body: { startupId, texto, isPublica }
  async criar(req: Request, res: Response) {
    try {
      const autorId = (req as any).user.uid;
      const autorNome = (req as any).user.name ?? (req as any).user.email;
      const id = await service.criar(req.body, autorId, autorNome);
      res.status(201).json({ id });
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }

  // PUT /v1/questions/:id/responder
  // Registra a resposta de uma pergunta
  // body: { resposta, respondidoPor }
  async responder(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      await service.responder(id, req.body);
      res.status(200).json({ message: 'Resposta registrada com sucesso' });
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  }
}