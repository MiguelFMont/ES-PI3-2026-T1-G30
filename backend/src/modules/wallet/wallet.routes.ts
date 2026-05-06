/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo: 

define a rota
aponta para o controller 
o :uid é o ID do usuário que será passado na URL
*/

import { Router } from 'express';
import { getHistoricoOperacoesController, getDadosDashboardController } from './wallet.controller';
import { authMiddleware } from '../../shared/http/auth.middleware';
const router = Router();

router.get('/historico/:uid', authMiddleware, getHistoricoOperacoesController);
router.get('/dashboard/:uid', authMiddleware, getDadosDashboardController);

export default router;