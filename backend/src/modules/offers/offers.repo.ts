// Autor: Samuel Campovilla
// Este repositório concentra o acesso ao Firestore para a Fase 6 do balcão.
// Ele é chamado por offers.service.ts e executa as mudanças atômicas de holding e offer.

import { FieldValue } from "firebase-admin/firestore";
import { getDb } from "../../config/firebase";
import { AppError } from "../../shared/errors/app.error";

export type StatusOferta = "ABERTA" | "ACEITA" | "CANCELADA";

interface HoldingRecord {
  uid: string;
  startupId: string;
  quantidade: number;
  quantidadeBloqueada: number;
  precoMedioCentavos: number;
}

interface OfferRecord {
  id: string;
  vendedorId: string;
  startupId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
  valorTotalCentavos: number;
  status: StatusOferta;
}

export interface CreateOfferResult {
  offerId: string;
  startupId: string;
  vendedorId: string;
  quantidade: number;
  precoUnitarioCentavos: number;
  valorTotalCentavos: number;
  status: "ABERTA";
}

export interface CancelOfferResult {
  offerId: string;
  status: "CANCELADA";
  quantidadeDevolvida: number;
}

export class OffersRepo {
  private db = getDb();

  // Valida inteiros positivos usados em quantidade, preço unitário e valor total.
  // É chamada pelos normalizadores internos antes de confiar nos documentos do Firestore.
  private isPositiveInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value > 0;
  }

  // Valida inteiros maiores ou iguais a zero para o estado da holding.
  // É usada para impedir leituras corrompidas de quantidade livre ou bloqueada.
  private isNonNegativeInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value >= 0;
  }

  // Valida strings não vazias como ids persistidos no Firestore.
  // É usada pelos normalizadores de holding e offer para evitar ids inconsistentes.
  private isNonEmptyString(value: unknown): value is string {
    return typeof value === "string" && value.trim().length > 0;
  }

  // Garante que o status lido da oferta pertence ao contrato da Fase 6.
  // É chamada quando a oferta é carregada para cancelamento.
  private isStatusOferta(value: unknown): value is StatusOferta {
    return value === "ABERTA" || value === "ACEITA" || value === "CANCELADA";
  }

  // Monta startups/{startupId}.
  // É usada por createOffer para validar a existência da startup dentro da transaction.
  private getStartupRef(startupId: string) {
    return this.db.collection("startups").doc(startupId);
  }

  // Monta wallets/{uid}/holdings/{startupId}.
  // É usada pelos fluxos de criação e cancelamento para mover tokens entre livre e bloqueado.
  private getHoldingRef(uid: string, startupId: string) {
    return this.db.collection("wallets").doc(uid).collection("holdings").doc(startupId);
  }

  // Monta offers/{offerId}.
  // É usada por cancelOffer para localizar a oferta alvo dentro da transaction.
  private getOfferRef(offerId: string) {
    return this.db.collection("offers").doc(offerId);
  }

  // Monta a coleção offers.
  // É usada por createOffer para gerar o id da nova oferta antes da escrita atômica.
  private getOffersRef() {
    return this.db.collection("offers");
  }

  // Normaliza e valida a holding lida do Firestore.
  // É chamada por createOffer e cancelOffer antes de qualquer conta de bloqueio/desbloqueio.
  private toHoldingRecord(
    uid: string,
    startupId: string,
    data: FirebaseFirestore.DocumentData | undefined,
  ): HoldingRecord {
    if (!this.isNonNegativeInteger(data?.quantidade)) {
      throw new AppError(
        "Holding com quantidade inválida.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    if (!this.isNonNegativeInteger(data?.quantidadeBloqueada)) {
      throw new AppError(
        "Holding com quantidadeBloqueada inválida.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    if (!this.isNonNegativeInteger(data?.precoMedioCentavos)) {
      throw new AppError(
        "Holding com precoMedioCentavos inválido.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    return {
      uid: this.isNonEmptyString(data?.uid) ? data.uid.trim() : uid,
      startupId: this.isNonEmptyString(data?.startupId)
        ? data.startupId.trim()
        : startupId,
      quantidade: data.quantidade,
      quantidadeBloqueada: data.quantidadeBloqueada,
      precoMedioCentavos: data.precoMedioCentavos,
    };
  }

  // Normaliza e valida a oferta lida do Firestore.
  // É chamada por cancelOffer para garantir que o documento aberto pode ser manipulado com segurança.
  private toOfferRecord(
    offerId: string,
    data: FirebaseFirestore.DocumentData | undefined,
  ): OfferRecord {
    if (!this.isNonEmptyString(data?.vendedorId)) {
      throw new AppError(
        "Oferta com vendedorId inválido.",
        500,
        "INVALID_OFFER_STATE",
      );
    }

    if (!this.isNonEmptyString(data?.startupId)) {
      throw new AppError(
        "Oferta com startupId inválido.",
        500,
        "INVALID_OFFER_STATE",
      );
    }

    if (!this.isPositiveInteger(data?.quantidade)) {
      throw new AppError(
        "Oferta com quantidade inválida.",
        500,
        "INVALID_OFFER_STATE",
      );
    }

    if (!this.isPositiveInteger(data?.precoUnitarioCentavos)) {
      throw new AppError(
        "Oferta com precoUnitarioCentavos inválido.",
        500,
        "INVALID_OFFER_STATE",
      );
    }

    if (!this.isPositiveInteger(data?.valorTotalCentavos)) {
      throw new AppError(
        "Oferta com valorTotalCentavos inválido.",
        500,
        "INVALID_OFFER_STATE",
      );
    }

    if (!this.isStatusOferta(data?.status)) {
      throw new AppError(
        "Oferta com status inválido.",
        500,
        "INVALID_OFFER_STATE",
      );
    }

    return {
      id: offerId,
      vendedorId: data.vendedorId.trim(),
      startupId: data.startupId.trim(),
      quantidade: data.quantidade,
      precoUnitarioCentavos: data.precoUnitarioCentavos,
      valorTotalCentavos: data.valorTotalCentavos,
      status: data.status,
    };
  }

  // Executa a criação de oferta inteira dentro de uma Firestore Transaction.
  // É chamada somente por createOfferService depois das validações de entrada.
  // A regra central aqui é bloquear apenas tokens livres: quantidade sai de livre e entra em bloqueada.
  async createOffer(
    uid: string,
    startupId: string,
    quantidade: number,
    precoUnitarioCentavos: number,
    valorTotalCentavos: number,
  ): Promise<CreateOfferResult> {
    return this.db.runTransaction<CreateOfferResult>(async (transaction) => {
      const startupRef = this.getStartupRef(startupId);
      const holdingRef = this.getHoldingRef(uid, startupId);
      const offerRef = this.getOffersRef().doc();

      const [startupDoc, holdingDoc] = await Promise.all([
        transaction.get(startupRef),
        transaction.get(holdingRef),
      ]);

      if (!startupDoc.exists) {
        throw new AppError(
          "Startup não encontrada.",
          404,
          "STARTUP_NOT_FOUND",
        );
      }

      if (!holdingDoc.exists) {
        throw new AppError(
          "Holding não encontrada para a startup informada.",
          404,
          "HOLDING_NOT_FOUND",
        );
      }

      const holding = this.toHoldingRecord(uid, startupId, holdingDoc.data());

      // A oferta usa somente tokens livres. quantidadeBloqueada já representa
      // tokens presos em outras ofertas abertas e não pode ser reutilizada.
      if (holding.quantidade < quantidade) {
        throw new AppError(
          "Você não possui tokens livres suficientes para criar a oferta.",
          409,
          "INSUFFICIENT_TOKENS",
        );
      }

      const quantidadeLivreAtualizada = holding.quantidade - quantidade;
      const quantidadeBloqueadaAtualizada = holding.quantidadeBloqueada + quantidade;

      // Validamos o estado final antes de escrever para não persistir underflow,
      // overflow ou uma regressão numérica causada por documento inconsistente.
      if (
        !this.isNonNegativeInteger(quantidadeLivreAtualizada) ||
        !this.isNonNegativeInteger(quantidadeBloqueadaAtualizada) ||
        quantidadeBloqueadaAtualizada < holding.quantidadeBloqueada
      ) {
        throw new AppError(
          "Holding com estado inválido após bloquear tokens.",
          500,
          "INVALID_HOLDING_STATE",
        );
      }

      const commonTimestamp = FieldValue.serverTimestamp();

      // Holding e offer são gravados na mesma transaction para impedir oferta
      // aberta sem bloqueio correspondente, ou bloqueio sem a oferta persistida.
      transaction.update(holdingRef, {
        uid,
        startupId,
        quantidade: quantidadeLivreAtualizada,
        quantidadeBloqueada: quantidadeBloqueadaAtualizada,
        precoMedioCentavos: holding.precoMedioCentavos,
        updatedAt: commonTimestamp,
      });

      transaction.set(offerRef, {
        vendedorId: uid,
        startupId,
        quantidade,
        precoUnitarioCentavos,
        valorTotalCentavos,
        status: "ABERTA",
        createdAt: commonTimestamp,
        updatedAt: commonTimestamp,
      });

      return {
        offerId: offerRef.id,
        startupId,
        vendedorId: uid,
        quantidade,
        precoUnitarioCentavos,
        valorTotalCentavos,
        status: "ABERTA",
      };
    });
  }

  // Executa o cancelamento inteiro dentro de uma Firestore Transaction.
  // É chamada somente por cancelOfferService depois da validação de autenticação e offerId.
  // A lógica desfaz exatamente o bloqueio anterior, devolvendo tokens ao saldo livre do vendedor.
  async cancelOffer(uid: string, offerId: string): Promise<CancelOfferResult> {
    return this.db.runTransaction<CancelOfferResult>(async (transaction) => {
      const offerRef = this.getOfferRef(offerId);
      const offerDoc = await transaction.get(offerRef);

      if (!offerDoc.exists) {
        throw new AppError(
          "Oferta não encontrada.",
          404,
          "OFFER_NOT_FOUND",
        );
      }

      const offer = this.toOfferRecord(offerId, offerDoc.data());

      if (offer.status !== "ABERTA") {
        throw new AppError(
          "A oferta informada não está aberta.",
          409,
          "OFFER_NOT_OPEN",
        );
      }

      // Apenas o vendedor original pode liberar os próprios tokens bloqueados.
      if (offer.vendedorId !== uid) {
        throw new AppError(
          "Apenas o vendedor pode cancelar esta oferta.",
          403,
          "ONLY_SELLER_CAN_CANCEL_OFFER",
        );
      }

      const holdingRef = this.getHoldingRef(uid, offer.startupId);
      const holdingDoc = await transaction.get(holdingRef);

      if (!holdingDoc.exists) {
        throw new AppError(
          "Holding não encontrada para a startup informada.",
          404,
          "HOLDING_NOT_FOUND",
        );
      }

      const holding = this.toHoldingRecord(uid, offer.startupId, holdingDoc.data());

      if (holding.quantidadeBloqueada < offer.quantidade) {
        throw new AppError(
          "A holding não possui tokens bloqueados suficientes para cancelar a oferta.",
          409,
          "INSUFFICIENT_LOCKED_TOKENS",
        );
      }

      const quantidadeLivreAtualizada = holding.quantidade + offer.quantidade;
      const quantidadeBloqueadaAtualizada = holding.quantidadeBloqueada - offer.quantidade;

      // O estado final precisa continuar íntegro porque o cancelamento não pode
      // fabricar tokens nem deixar o bloqueio negativo ao devolver o saldo livre.
      if (
        !this.isNonNegativeInteger(quantidadeLivreAtualizada) ||
        !this.isNonNegativeInteger(quantidadeBloqueadaAtualizada) ||
        quantidadeLivreAtualizada < holding.quantidade
      ) {
        throw new AppError(
          "Holding com estado inválido após devolver tokens bloqueados.",
          500,
          "INVALID_HOLDING_STATE",
        );
      }

      const commonTimestamp = FieldValue.serverTimestamp();

      // O cancelamento também é atômico para não existir devolução parcial:
      // ou a offer muda para CANCELADA e os tokens voltam juntos, ou nada muda.
      transaction.update(holdingRef, {
        uid,
        startupId: offer.startupId,
        quantidade: quantidadeLivreAtualizada,
        quantidadeBloqueada: quantidadeBloqueadaAtualizada,
        precoMedioCentavos: holding.precoMedioCentavos,
        updatedAt: commonTimestamp,
      });

      transaction.update(offerRef, {
        status: "CANCELADA",
        cancelledAt: commonTimestamp,
        updatedAt: commonTimestamp,
      });

      return {
        offerId: offer.id,
        status: "CANCELADA",
        quantidadeDevolvida: offer.quantidade,
      };
    });
  }
}
