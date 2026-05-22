// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { Router } from 'express';
import { authMiddleware } from '../../../shared/http/auth.middleware';
import { setupMfaController, verifyMfaController, mfaChallengeController, disableMfaController } from './mfa.controller';

const router = Router();

router.post('/setup', authMiddleware, setupMfaController);
router.post('/verify', authMiddleware, verifyMfaController);
router.post('/disable', authMiddleware, disableMfaController);
router.post('/challenge', mfaChallengeController); // público — só usa o tempToken

export default router;