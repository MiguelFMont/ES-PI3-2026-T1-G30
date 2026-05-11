/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:

recebe a requisição http da busca 
pega o uid do usuário pelos parametros da rota (/historico/:uid)
chama o service 
retorna o resultado com status 200
*/

import  {NextFunction, Request, Response } from 'express';
import { 
  getHistoricoOperacoesService, 
  getDadosDashboardService,
  addBalanceService,
  getWalletService,
  listHoldingsService
} from './wallet.service';

// controller histórico de operações 
export async function getHistoricoOperacoesController (req: Request, res: Response) {
    // pega o uid do usuário pelos parametros da rota 
    const uid = req.params.uid as string;

    // chama o service 
    const result = await getHistoricoOperacoesService(uid);

    // retorna o resultado 
    res.status(200).json(result);
}

// controller dos dados do dashboard 
export async function getDadosDashboardController (req: Request, res: Response) {
    // pega o uid do usuário pelos parametros da rota 
    const uid = req.params.uid as string;

    // chama o service 
    const result = await getDadosDashboardService(uid);

    // retorna o resultado
    res.status(200).json(result);
}

// Samuel Campovilla
// Este arquivo converte requisições HTTP em chamadas para a camada de service.
// Ele é usado por wallet.routes.ts e não acessa Firestore diretamente.

// Extrai o uid já validado pelo authMiddleware.
// Todos os controllers deste módulo usam essa função antes de chamar o service.
function getUid(req: Request): string | undefined {
  return req.user?.uid;
}

// Controller do GET /wallet.
// É chamado em wallet.routes.ts e devolve a carteira do usuário autenticado.
export async function getWalletController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await getWalletService(getUid(req));
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}

// Controller do GET /wallet/holdings.
// É chamado em wallet.routes.ts e devolve a lista de holdings do usuário.
export async function listHoldingsController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await listHoldingsService(getUid(req));
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}

// Controller do POST /wallet/add-balance.
// É chamado em wallet.routes.ts e repassa o uid autenticado e o valor recebido no body.
export async function addBalanceController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await addBalanceService(getUid(req), req.body?.valorCentavos);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}
