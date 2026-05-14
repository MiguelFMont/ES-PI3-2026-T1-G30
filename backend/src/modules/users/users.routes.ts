// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { Router } from 'express';
import { alterarSenhaController, getMe, updateMe } from './users.controller';
import { authMiddleware } from '../../shared/http/auth.middleware';

const router = Router();

// GET  /v1/users/me
router.get('/me', getMe);

// PATCH /v1/users/me
router.patch('/me', updateMe);

router.patch('/me/senha', authMiddleware, alterarSenhaController);

export default router;