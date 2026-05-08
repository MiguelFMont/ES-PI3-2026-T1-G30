// Samuel Campovilla
// Este arquivo converte requisições HTTP em chamadas para a camada de service.
// Ele é usado por wallet.routes.ts e não acessa Firestore diretamente.

import { NextFunction, Request, Response } from "express";
import {
  addBalanceService,
  getWalletService,
  listHoldingsService,
} from "./wallet.service";

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
