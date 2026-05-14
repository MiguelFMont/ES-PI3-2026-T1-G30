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
  getTransactionsService,
  getDadosDashboardService,
  addBalanceService,
  getWalletService,
  listHoldingsService
} from './wallet.service';

// Extrai apenas os filtros públicos aceitos pelo contrato do histórico.
// O endpoint não aceita uid externo em params, query ou body.
function getTransactionsFilters(req: Request) {
  return {
    startupId: req.query?.startupId,
    tipo: req.query?.tipo,
  };
}

// Samuel Campovilla:
// O endpoint oficial do histórico usa exclusivamente o UID autenticado.
// Isso evita que um cliente force outro userId na URL ou na query para ler transações alheias.
export async function getTransactionsController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await getTransactionsService(
      getUid(req),
      getTransactionsFilters(req),
    );
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}

// A rota legada /wallet/historico/:uid continua disponível por compatibilidade.
// O parâmetro da URL é ignorado deliberadamente; a consulta usa apenas req.user.uid.
export async function getHistoricoOperacoesController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await getHistoricoOperacoesService(
      getUid(req),
      getTransactionsFilters(req),
    );
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}

// controller dos dados do dashboard 
// usa o token JWT para identificar o usuário 
export async function getDadosDashboardController (
  req: Request, 
  res: Response, 
  next: NextFunction,
) {
  try {
    const result = await getDadosDashboardService(getUid(req));
    res.status(200).json(result);
  } catch (error) {
      next(error);
    }
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
