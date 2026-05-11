/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo: 

define a rota
aponta para o controller 
o :uid é o ID do usuário que será passado na URL
*/

// Samuel Campovilla
// Este arquivo registra as rotas HTTP do módulo de carteira.
// Ele é importado em src/modules/index.ts, que monta o prefixo /wallet.
// O server.ts aplica /v1 acima disso, então os caminhos finais ficam /api/v1/wallet...
import { Router } from 'express';
import {
  getHistoricoOperacoesController,
  getDadosDashboardController,
  addBalanceController,
  getWalletController,
  listHoldingsController,
} from './wallet.controller';
import { authMiddleware } from '../../shared/http/auth.middleware';

const router = Router();

// Todas as rotas de carteira exigem usuário autenticado.
// O authMiddleware valida o token Firebase e preenche req.user para os controllers.
router.use(authMiddleware);

// Consulta a wallet do usuário autenticado.
// Chama getWalletController, que delega a regra de negócio ao wallet.service.ts.
router.get('/', getWalletController);

// Lista as holdings do usuário autenticado.
// Chama listHoldingsController, que busca wallets/{uid}/holdings via service/repo.
router.get('/holdings', listHoldingsController);

// Soma saldo fictício em centavos na carteira do usuário autenticado.
// Chama addBalanceController, que valida req.body.valorCentavos no service.
router.post('/add-balance', addBalanceController);

// Retorna o histórico de operações do usuário
// o :uid é o ID do usuário que será passado na URL
router.get('/historico/:uid', getHistoricoOperacoesController);

// Retorna os dados agregados da wallet para o dashboard
router.get('/dashboard/:uid', getDadosDashboardController);

export default router;