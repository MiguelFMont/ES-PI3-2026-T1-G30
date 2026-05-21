// Autor: Samuel Campovilla
// Este arquivo registra as rotas HTTP do módulo offers.
// Ele é importado por src/modules/index.ts, que monta o prefixo /offers.

import { Router } from "express";
import { authMiddleware } from "../../shared/http/auth.middleware";
import {
  acceptOfferController,
  cancelOfferController,
  createOfferController,
} from "./offers.controller";

const router = Router();

// Todas as rotas do balcão nesta fase exigem autenticação.
// O middleware injeta req.user para que os controllers sempre operem no uid autenticado.
router.use(authMiddleware);

// Criar oferta não vende tokens; apenas move tokens livres para quantidadeBloqueada.
router.post("/", createOfferController);

// O aceite transfere saldo e tokens em uma única negociação de balcão entre dois usuários.
router.post("/:offerId/accept", acceptOfferController);

// O cancelamento existe só para o próprio vendedor desfazer uma oferta ainda ABERTA.
router.post("/:offerId/cancel", cancelOfferController);

export default router;
