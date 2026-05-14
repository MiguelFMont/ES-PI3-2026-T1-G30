// Este arquivo adapta a requisição HTTP para a camada de service.
// Ele é chamado por trades.routes.ts e não acessa Firestore diretamente.

import { NextFunction, Request, Response } from "express";
import { directBuyService, directSellService } from "./trades.service";

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

// Samuel Campovilla:
// Controller do endpoint POST /trades/direct-sell.
// Ele existe apenas para adaptar HTTP -> regra de negócio:
// 1) lê uid de req.user preenchido pelo authMiddleware;
// 2) lê startupId e quantidade do body;
// 3) delega toda a validação e a transaction para directSellService.
// Controller do POST /trades/direct-sell.
// Lê startupId e quantidade do body e delega a venda direta ao service.
export async function directSellController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await directSellService(getUid(req), {
      startupId: req.body?.startupId,
      quantidade: req.body?.quantidade,
    });

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}
