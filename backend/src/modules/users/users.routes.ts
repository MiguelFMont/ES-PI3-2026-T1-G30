// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { Router } from 'express';
import { getMe, updateMe } from './users.controller';

const router = Router();

// GET  /v1/users/me
router.get('/me', getMe);

// PATCH /v1/users/me
router.patch('/me', updateMe);

export default router;