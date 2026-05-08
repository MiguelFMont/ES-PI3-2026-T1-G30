// Este arquivo adapta a requisição HTTP para a camada de service.
// Ele é chamado por trades.routes.ts e não acessa Firestore diretamente.

import { NextFunction, Request, Response } from "express";
import { directBuyService } from "./trades.service";

// Extrai o uid autenticado preenchido pelo authMiddleware.
// O service usa esse uid para localizar a wallet e registrar a transação.
function getUid(req: Request): string | undefined {
  return req.user?.uid;
}

// Controller do POST /trades/direct-buy.
// Lê startupId e quantidade do body e delega a compra direta ao service.
export async function directBuyController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await directBuyService(getUid(req), {
      startupId: req.body?.startupId,
      quantidade: req.body?.quantidade,
    });

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}
