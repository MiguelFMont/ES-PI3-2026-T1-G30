// Autor: Samuel Campovilla
// Este controller adapta HTTP para a camada de service do módulo offers.
// Ele é chamado por offers.routes.ts e não acessa Firestore diretamente.

import { NextFunction, Request, Response } from "express";
import {
  acceptOfferService,
  cancelOfferService,
  createOfferService,
} from "./offers.service";

// Extrai o uid autenticado preenchido pelo authMiddleware.
// Os services usam esse uid para garantir que a oferta pertença ao usuário logado.
function getUid(req: Request): string | undefined {
  return req.user?.uid;
}

// Controller do POST /offers.
// Lê startupId, quantidade e precoUnitarioCentavos do body e delega toda a regra ao service.
export async function createOfferController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await createOfferService(getUid(req), {
      startupId: req.body?.startupId,
      quantidade: req.body?.quantidade,
      precoUnitarioCentavos: req.body?.precoUnitarioCentavos,
    });

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}

// Controller do POST /offers/:offerId/cancel.
// Lê offerId da URL e delega ao service a validação de posse e o desbloqueio atômico.
export async function cancelOfferController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await cancelOfferService(getUid(req), {
      offerId: req.params.offerId,
    });

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}

// Controller do POST /offers/:offerId/accept.
// Lê offerId da URL e delega ao service a transferência atômica entre comprador e vendedor.
export async function acceptOfferController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const result = await acceptOfferService(getUid(req), {
      offerId: req.params.offerId,
    });

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}
