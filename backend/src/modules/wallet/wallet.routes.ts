import { Router } from 'express';
import { addBalanceController } from './wallet.controller';
import { authMiddleware } from '../../shared/http/auth.middleware';

const router = Router();

router.post('/add-balance', authMiddleware, addBalanceController);

export default router;
