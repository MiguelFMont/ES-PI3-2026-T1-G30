// Este arquivo concentra a regra de negócio da Fase 2.
// O controller chama estas funções para validar entrada e normalizar a resposta da compra direta.

import { AppError } from "../../shared/errors/app.error";
import { WalletRepo } from "../wallet/wallet.repo";
import { DirectBuyResult, TradesRepo } from "./trades.repo";

const tradesRepo = new TradesRepo();
const walletRepo = new WalletRepo();

interface DirectBuyInput {
  startupId: unknown;
  quantidade: unknown;
}

interface DirectBuyResponse {
  transactionId: string;
  startupId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
  valorTotalCentavos: number;
  saldoAnteriorCentavos: number;
  saldoNovoCentavos: number;
  quantidadeAtual: number;
  quantidadeBloqueada: number;
  precoMedioCentavos: number;
}

// Valida inteiros estritamente positivos.
// É usada para verificar a quantidade comprada e os números retornados pelo repositório.
function isPositiveInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value > 0;
}

// Valida inteiros maiores ou iguais a zero.
// É usada para conferir saldos e quantidades que podem assumir zero.
function isNonNegativeInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0;
}

// Valida strings não vazias.
// É usada para garantir startupId e transactionId legíveis antes de responder ao cliente.
function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

// Garante que o uid foi preenchido pelo authMiddleware.
// Todas as funções públicas deste service passam por aqui antes de falar com o Firestore.
function assertAuthenticated(uid: string | undefined): string {
  if (!uid) {
    throw new AppError("Usuário não autenticado.", 401, "UNAUTHENTICATED");
  }

  return uid;
}

// Normaliza e valida o body recebido pelo controller.
// É chamada por directBuyService antes de iniciar a operação de compra.
function parseDirectBuyInput(input: DirectBuyInput): {
  startupId: string;
  quantidade: number;
} {
  if (!isNonEmptyString(input.startupId)) {
    throw new AppError(
      "startupId deve ser uma string não vazia.",
      400,
      "INVALID_STARTUP_ID",
    );
  }

  if (!isPositiveInteger(input.quantidade)) {
    throw new AppError(
      "quantidade deve ser um inteiro positivo.",
      400,
      "INVALID_QUANTITY",
    );
  }

  return {
    startupId: input.startupId.trim(),
    quantidade: input.quantidade,
  };
}

// Valida a estrutura retornada pelo repositório antes de responder.
// É chamada por directBuyService para manter a saída do endpoint consistente.
function toDirectBuyResponse(result: DirectBuyResult): DirectBuyResponse {
  if (!isNonEmptyString(result.transactionId)) {
    throw new AppError(
      "Transação sem identificador válido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonEmptyString(result.startupId)) {
    throw new AppError(
      "Resposta com startupId inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isPositiveInteger(result.quantidade)) {
    throw new AppError(
      "Resposta com quantidade inválida.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isPositiveInteger(result.precoUnitarioCentavos)) {
    throw new AppError(
      "Resposta com preço unitário inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isPositiveInteger(result.valorTotalCentavos)) {
    throw new AppError(
      "Resposta com valor total inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonNegativeInteger(result.saldoAnteriorCentavos)) {
    throw new AppError(
      "Resposta com saldo anterior inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonNegativeInteger(result.saldoNovoCentavos)) {
    throw new AppError(
      "Resposta com saldo novo inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isPositiveInteger(result.quantidadeAtual)) {
    throw new AppError(
      "Resposta com quantidade atual inválida.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonNegativeInteger(result.quantidadeBloqueada)) {
    throw new AppError(
      "Resposta com quantidade bloqueada inválida.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonNegativeInteger(result.precoMedioCentavos)) {
    throw new AppError(
      "Resposta com preço médio inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  return {
    transactionId: result.transactionId,
    startupId: result.startupId,
    quantidade: result.quantidade,
    precoUnitarioCentavos: result.precoUnitarioCentavos,
    valorTotalCentavos: result.valorTotalCentavos,
    saldoAnteriorCentavos: result.saldoAnteriorCentavos,
    saldoNovoCentavos: result.saldoNovoCentavos,
    quantidadeAtual: result.quantidadeAtual,
    quantidadeBloqueada: result.quantidadeBloqueada,
    precoMedioCentavos: result.precoMedioCentavos,
  };
}

// Regra de negócio do POST /trades/direct-buy.
// É chamada pelo controller e dispara a transação atômica no repositório.
export async function directBuyService(
  uid: string | undefined,
  input: DirectBuyInput,
): Promise<DirectBuyResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const { startupId, quantidade } = parseDirectBuyInput(input);
  // Garante a existência da wallet antes da compra.
  // Isso mantém o comportamento de criação automática definido na Fase 1.
  await walletRepo.getOrCreateWallet(authenticatedUid);
  const result = await tradesRepo.directBuy(authenticatedUid, startupId, quantidade);

  return toDirectBuyResponse(result);
}
