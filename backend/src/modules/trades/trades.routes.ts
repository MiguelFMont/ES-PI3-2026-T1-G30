// Este arquivo registra as rotas HTTP do módulo de trades.
// Ele é importado por src/modules/index.ts, que monta o prefixo /trades.
// 

import { Router } from "express";
import { authMiddleware } from "../../shared/http/auth.middleware";
import {
  directBuyController,
  directSellController,
} from "./trades.controller";

const router = Router();

// Todas as rotas de trades exigem autenticação.
// O middleware valida o token Firebase e injeta req.user para o controller.
router.use(authMiddleware);

// Compra direta de tokens da reserva da startup.
// O controller delega as validações e a operação atômica ao trades.service.ts.
router.post("/direct-buy", directBuyController);

// Samuel Campovilla:
// Registra a rota interna POST /trades/direct-sell.
// Como src/modules/index.ts monta este router em /trades e o servidor monta /v1,
// o endpoint publicado pela Cloud Function fica /api/v1/trades/direct-sell.
// Venda direta de tokens livres de volta para a startup.
// O controller delega as validações e a operação atômica ao trades.service.ts.
router.post("/direct-sell", directSellController);

export default router;
