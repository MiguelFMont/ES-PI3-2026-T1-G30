// Este arquivo concentra a regra de negócio de compra e venda direta.
// O controller chama estas funções para validar entrada, executar a operação no repo
// e normalizar a resposta final antes de enviar JSON ao cliente.

import { AppError } from "../../shared/errors/app.error";
import { StartupsRepo } from "../startups/startups.repo";
import { WalletRepo } from "../wallet/wallet.repo";
import {
  DirectBuyResult,
  DirectSellResult,
  TradesRepo,
} from "./trades.repo";

const tradesRepo = new TradesRepo();
const startupsRepo = new StartupsRepo();
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

// Samuel Campovilla:
// DTO bruto do body recebido em POST /trades/direct-sell.
// O controller apenas repassa esses valores; a validação real ocorre em parseDirectSellInput.
interface DirectSellInput {
  startupId: unknown;
  quantidade: unknown;
}

// Samuel Campovilla:
// DTO de resposta do endpoint de venda direta.
// Ele espelha exatamente o contrato público retornado ao app mobile após a transaction.
interface DirectSellResponse {
  transactionId: string;
  startupId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
  valorTotalCentavos: number;
  saldoAnteriorCentavos: number;
  saldoNovoCentavos: number;
  quantidadeAtual: number;
  quantidadeBloqueada: number;
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
// É chamada pelos endpoints de compra e venda direta antes de iniciar a operação.
function parseTradeInput(input: {
  startupId: unknown;
  quantidade: unknown;
}): {
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

// Alias semântico para manter a intenção explícita no fluxo da compra direta.
function parseDirectBuyInput(input: DirectBuyInput) {
  return parseTradeInput(input);
}

// Alias semântico para manter a intenção explícita no fluxo da venda direta.
// É usado por directSellService para deixar claro que a validação pertence ao endpoint de venda.
function parseDirectSellInput(input: DirectSellInput) {
  return parseTradeInput(input);
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

// Samuel Campovilla:
// Converte o resultado interno do repo no payload público da venda direta.
// É usada somente por directSellService e garante que a resposta saia com os campos
// esperados pelo contrato, mesmo que algum retorno interno venha corrompido.
// Valida a estrutura retornada pelo repositório antes de responder.
// É chamada por directSellService para manter a saída do endpoint consistente.
function toDirectSellResponse(result: DirectSellResult): DirectSellResponse {
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

  if (!isNonNegativeInteger(result.quantidadeAtual)) {
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
  const startup = await startupsRepo.findByIdMerged(startupId);
  const canonicalStartupId = startup?.id ?? startupId;
  // Garante a existência da wallet antes da compra.
  // Isso mantém o comportamento atual de criação automática da wallet quando necessário.
  await walletRepo.getOrCreateWallet(authenticatedUid);
  const result = await tradesRepo.directBuy(
    authenticatedUid,
    canonicalStartupId,
    quantidade,
  );

  return toDirectBuyResponse(result);
}

// Samuel Campovilla:
// Regra de negócio do POST /trades/direct-sell.
// Este service faz a coordenação da venda direta:
// - valida autenticação;
// - valida startupId e quantidade;
// - chama o repo, que executa a Firestore Transaction;
// - normaliza a resposta final do endpoint.
// Regra de negócio do POST /trades/direct-sell.
// É chamada pelo controller e dispara a transação atômica no repositório.
export async function directSellService(
  uid: string | undefined,
  input: DirectSellInput,
): Promise<DirectSellResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const { startupId, quantidade } = parseDirectSellInput(input);
  const startup = await startupsRepo.findByIdMerged(startupId);
  const canonicalStartupId = startup?.id ?? startupId;
  const holdingStartupIds = startup == null
    ? [canonicalStartupId]
    : [
        canonicalStartupId,
        ...(startup.aliasIds ?? []).filter(
          (aliasId) => aliasId !== canonicalStartupId,
        ),
      ];
  const result = await tradesRepo.directSell(
    authenticatedUid,
    canonicalStartupId,
    quantidade,
    holdingStartupIds,
  );

  return toDirectSellResponse(result);
}
