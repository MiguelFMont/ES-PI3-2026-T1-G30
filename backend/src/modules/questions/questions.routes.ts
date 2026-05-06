// Autor: Caio Ávila Marchi
// RA: 25008101

import { Router } from 'express';
import { QuestionsController } from './questions.controller';
import { authMiddleware } from '../../shared/http/auth.middleware';

const router = Router();
const controller = new QuestionsController();

// Rotas protegidas — todas exigem token JWT válido

// GET /v1/questions/:startupId/publicas
router.get('/:startupId/publicas', authMiddleware, (req, res) =>
  controller.listarPublicas(req, res)
);

// GET /v1/questions/:startupId/todas  (investidores)
router.get('/:startupId/todas', authMiddleware, (req, res) =>
  controller.listarTodas(req, res)
);

// POST /v1/questions
router.post('/', authMiddleware, (req, res) =>
  controller.criar(req, res)
);

// PUT /v1/questions/:id/responder
router.put('/:id/responder', authMiddleware, (req, res) =>
  controller.responder(req, res)
);

export default router;
