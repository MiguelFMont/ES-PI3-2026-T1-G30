/*
significado do arquivo: 

define a rota: GET /historico/:uid
aponta para o controller 
o :uid é o ID do usuário que será passado na URL
*/

import { Router } from 'express';
import { getHistoricoOperacoesController } from './wallet.controller';

const router = Router();

// rota 
router.get('/historico/:uid', getHistoricoOperacoesController);

export default router;