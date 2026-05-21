// Autor: Samuel Campovilla
// Este service concentra a regra de negócio das Fases 6 e 7.
// Os controllers chamam estas funções para validar entrada, calcular totais
// e delegar a persistência atômica ao offers.repo.ts.

import { AppError } from "../../shared/errors/app.error";
import {
  AcceptOfferResult,
  CancelOfferResult,
  CreateOfferResult,
  OffersRepo,
  StatusOferta,
} from "./offers.repo";

const offersRepo = new OffersRepo();

interface CreateOfferInput {
  startupId: unknown;
  quantidade: unknown;
  precoUnitarioCentavos: unknown;
}

interface CancelOfferInput {
  offerId: unknown;
}

interface AcceptOfferInput {
  offerId: unknown;
}

interface CreateOfferResponse {
  offerId: string;
  startupId: string;
  vendedorId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
  valorTotalCentavos: number;
  status: "ABERTA";
}

interface CancelOfferResponse {
  offerId: string;
  status: "CANCELADA";
  quantidadeDevolvida: number;
}

interface AcceptOfferResponse {
  offerId: string;
  status: "ACEITA";
  startupId: string;
  compradorId: string;
  vendedorId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
  valorTotalCentavos: number;
  buyerTransactionId: string;
  sellerTransactionId: string;
}

// Valida inteiros positivos usados no body dos endpoints e nos DTOs devolvidos.
// É chamada pelos parsers de entrada e pelos normalizadores de resposta.
function isPositiveInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value > 0;
}

// Valida strings não vazias para startupId, offerId e ids retornados pelo repo.
// É usada nos parsers de entrada e nos validadores do payload final.
function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

// Garante que o status retornado pelo repo continua aderente ao contrato público.
// É usada apenas antes de responder ao cliente.
function isStatusOferta(value: unknown): value is StatusOferta {
  return value === "ABERTA" || value === "ACEITA" || value === "CANCELADA";
}

// Garante que o uid foi preenchido pelo authMiddleware antes de entrar na regra de negócio.
// Todas as funções públicas deste service passam por aqui antes de falar com o repo.
function assertAuthenticated(uid: string | undefined): string {
  if (!uid) {
    throw new AppError("Usuário não autenticado.", 401, "UNAUTHENTICATED");
  }

  return uid;
}

// Normaliza o body de POST /offers.
// É chamada por createOfferService para concentrar a validação sem misturar HTTP e persistência.
function parseCreateOfferInput(input: CreateOfferInput): {
  startupId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
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

  if (!isPositiveInteger(input.precoUnitarioCentavos)) {
    throw new AppError(
      "precoUnitarioCentavos deve ser um inteiro positivo.",
      400,
      "INVALID_PRICE",
    );
  }

  return {
    startupId: input.startupId.trim(),
    quantidade: input.quantidade,
    precoUnitarioCentavos: input.precoUnitarioCentavos,
  };
}

// Normaliza o parâmetro da rota POST /offers/:offerId/cancel.
// É chamada por cancelOfferService antes de abrir a transaction no Firestore.
function parseCancelOfferInput(input: CancelOfferInput): {
  offerId: string;
} {
  if (!isNonEmptyString(input.offerId)) {
    throw new AppError(
      "offerId deve ser uma string não vazia.",
      400,
      "INVALID_OFFER_ID",
    );
  }

  return {
    offerId: input.offerId.trim(),
  };
}

// Normaliza o parâmetro da rota POST /offers/:offerId/accept.
// É chamada por acceptOfferService antes de abrir a transaction no Firestore.
function parseAcceptOfferInput(input: AcceptOfferInput): {
  offerId: string;
} {
  if (!isNonEmptyString(input.offerId)) {
    throw new AppError(
      "offerId deve ser uma string não vazia.",
      400,
      "INVALID_OFFER_ID",
    );
  }

  return {
    offerId: input.offerId.trim(),
  };
}

// Calcula valorTotalCentavos no service para manter a regra explícita fora do controller.
// É chamada somente por createOfferService antes de delegar a escrita ao repo.
function calculateValorTotalCentavos(
  quantidade: number,
  precoUnitarioCentavos: number,
): number {
  const valorTotalCentavos = quantidade * precoUnitarioCentavos;

  if (!Number.isSafeInteger(valorTotalCentavos) || valorTotalCentavos <= 0) {
    throw new AppError(
      "valorTotalCentavos inválido para os dados informados.",
      400,
      "INVALID_PRICE",
    );
  }

  return valorTotalCentavos;
}

// Valida e converte o resultado interno do repo no DTO público da criação de oferta.
// É chamada por createOfferService para evitar resposta inconsistente ao app.
function toCreateOfferResponse(result: CreateOfferResult): CreateOfferResponse {
  if (!isNonEmptyString(result.offerId)) {
    throw new AppError("Oferta sem identificador válido.", 500, "INTERNAL_ERROR");
  }

  if (!isNonEmptyString(result.startupId)) {
    throw new AppError("Resposta com startupId inválido.", 500, "INTERNAL_ERROR");
  }

  if (!isNonEmptyString(result.vendedorId)) {
    throw new AppError("Resposta com vendedorId inválido.", 500, "INTERNAL_ERROR");
  }

  if (!isPositiveInteger(result.quantidade)) {
    throw new AppError("Resposta com quantidade inválida.", 500, "INTERNAL_ERROR");
  }

  if (!isPositiveInteger(result.precoUnitarioCentavos)) {
    throw new AppError(
      "Resposta com precoUnitarioCentavos inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isPositiveInteger(result.valorTotalCentavos)) {
    throw new AppError(
      "Resposta com valorTotalCentavos inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (result.valorTotalCentavos !== result.quantidade * result.precoUnitarioCentavos) {
    throw new AppError(
      "Resposta com valorTotalCentavos inconsistente.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (result.status !== "ABERTA" || !isStatusOferta(result.status)) {
    throw new AppError("Resposta com status inválido.", 500, "INTERNAL_ERROR");
  }

  return {
    offerId: result.offerId,
    startupId: result.startupId,
    vendedorId: result.vendedorId,
    quantidade: result.quantidade,
    precoUnitarioCentavos: result.precoUnitarioCentavos,
    valorTotalCentavos: result.valorTotalCentavos,
    status: result.status,
  };
}

// Valida e converte o resultado interno do repo no DTO público do cancelamento.
// É chamada por cancelOfferService antes da resposta HTTP final.
function toCancelOfferResponse(result: CancelOfferResult): CancelOfferResponse {
  if (!isNonEmptyString(result.offerId)) {
    throw new AppError("Oferta sem identificador válido.", 500, "INTERNAL_ERROR");
  }

  if (!isPositiveInteger(result.quantidadeDevolvida)) {
    throw new AppError(
      "Resposta com quantidadeDevolvida inválida.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (result.status !== "CANCELADA" || !isStatusOferta(result.status)) {
    throw new AppError("Resposta com status inválido.", 500, "INTERNAL_ERROR");
  }

  return {
    offerId: result.offerId,
    status: result.status,
    quantidadeDevolvida: result.quantidadeDevolvida,
  };
}

// Valida e converte o resultado interno do repo no DTO público do aceite de oferta.
// É chamada por acceptOfferService para manter o contrato do endpoint consistente.
function toAcceptOfferResponse(result: AcceptOfferResult): AcceptOfferResponse {
  if (!isNonEmptyString(result.offerId)) {
    throw new AppError("Oferta sem identificador válido.", 500, "INTERNAL_ERROR");
  }

  if (!isNonEmptyString(result.startupId)) {
    throw new AppError("Resposta com startupId inválido.", 500, "INTERNAL_ERROR");
  }

  if (!isNonEmptyString(result.compradorId)) {
    throw new AppError("Resposta com compradorId inválido.", 500, "INTERNAL_ERROR");
  }

  if (!isNonEmptyString(result.vendedorId)) {
    throw new AppError("Resposta com vendedorId inválido.", 500, "INTERNAL_ERROR");
  }

  if (!isPositiveInteger(result.quantidade)) {
    throw new AppError("Resposta com quantidade inválida.", 500, "INTERNAL_ERROR");
  }

  if (!isPositiveInteger(result.precoUnitarioCentavos)) {
    throw new AppError(
      "Resposta com precoUnitarioCentavos inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isPositiveInteger(result.valorTotalCentavos)) {
    throw new AppError(
      "Resposta com valorTotalCentavos inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (result.valorTotalCentavos !== result.quantidade * result.precoUnitarioCentavos) {
    throw new AppError(
      "Resposta com valorTotalCentavos inconsistente.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonEmptyString(result.buyerTransactionId)) {
    throw new AppError(
      "Resposta com buyerTransactionId inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (!isNonEmptyString(result.sellerTransactionId)) {
    throw new AppError(
      "Resposta com sellerTransactionId inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  if (result.status !== "ACEITA" || !isStatusOferta(result.status)) {
    throw new AppError("Resposta com status inválido.", 500, "INTERNAL_ERROR");
  }

  return {
    offerId: result.offerId,
    status: result.status,
    startupId: result.startupId,
    compradorId: result.compradorId,
    vendedorId: result.vendedorId,
    quantidade: result.quantidade,
    precoUnitarioCentavos: result.precoUnitarioCentavos,
    valorTotalCentavos: result.valorTotalCentavos,
    buyerTransactionId: result.buyerTransactionId,
    sellerTransactionId: result.sellerTransactionId,
  };
}

// Regra de negócio do POST /offers.
// É chamada por createOfferController e coordena autenticação, validação, cálculo do total
// e a transaction que bloqueia tokens livres e cria a oferta ABERTA.
export async function createOfferService(
  uid: string | undefined,
  input: CreateOfferInput,
): Promise<CreateOfferResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const { startupId, quantidade, precoUnitarioCentavos } = parseCreateOfferInput(input);
  const valorTotalCentavos = calculateValorTotalCentavos(
    quantidade,
    precoUnitarioCentavos,
  );
  const result = await offersRepo.createOffer(
    authenticatedUid,
    startupId,
    quantidade,
    precoUnitarioCentavos,
    valorTotalCentavos,
  );

  return toCreateOfferResponse(result);
}

// Regra de negócio do POST /offers/:offerId/cancel.
// É chamada por cancelOfferController e coordena a validação com a transaction
// que devolve ao vendedor os tokens antes bloqueados na oferta aberta.
export async function cancelOfferService(
  uid: string | undefined,
  input: CancelOfferInput,
): Promise<CancelOfferResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const { offerId } = parseCancelOfferInput(input);
  const result = await offersRepo.cancelOffer(authenticatedUid, offerId);

  return toCancelOfferResponse(result);
}

// Regra de negócio do POST /offers/:offerId/accept.
// É chamada por acceptOfferController e coordena a validação com a transaction
// que move saldo, transfere tokens bloqueados e registra os dois lados do histórico.
export async function acceptOfferService(
  uid: string | undefined,
  input: AcceptOfferInput,
): Promise<AcceptOfferResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const { offerId } = parseAcceptOfferInput(input);
  const result = await offersRepo.acceptOffer(authenticatedUid, offerId);

  return toAcceptOfferResponse(result);
}
