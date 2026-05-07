import { NextFunction, Request, Response } from "express";
import { addBalanceService } from "./wallet.service";

// Controller do endpoint de adicionar saldo.
// Esta função é usada em wallet.routes.ts na rota POST /add-balance.
// O papel dela é transformar a requisição HTTP em parâmetros simples
// para a camada de service e devolver a resposta ao cliente.
export async function addBalanceController(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    // req.user?.uid é preenchido pelo authMiddleware depois da validação do token.
    // req.body.amount é o valor enviado pelo cliente no JSON da requisição.
    const result = await addBalanceService(req.user?.uid, req.body.amount);

    // A resposta devolve os dados calculados pelo repo:
    // saldo anterior, valor adicionado e saldo final da carteira.
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}
