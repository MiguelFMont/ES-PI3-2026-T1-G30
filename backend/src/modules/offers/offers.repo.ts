// Autor: Samuel Campovilla
// Este repositório concentra o acesso ao Firestore para os fluxos do balcão.
// Ele é chamado por offers.service.ts e executa as mudanças atômicas de holding, offer e histórico.

import { FieldValue } from "firebase-admin/firestore";
import { getDb } from "../../config/firebase";
import { AppError } from "../../shared/errors/app.error";
import { PriceService } from "../prices/price.service";

export type StatusOferta = "ABERTA" | "ACEITA" | "CANCELADA";

interface WalletRecord {
  uid: string;
  saldoCentavos: number;
}

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

export interface AcceptOfferResult {
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

export class OffersRepo {
  private db = getDb();
  private priceService = new PriceService();

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

  // Garante que o status lido da oferta pertence ao contrato aceito pelo módulo.
  // É chamada quando a oferta é carregada para cancelamento.
  private isStatusOferta(value: unknown): value is StatusOferta {
    return value === "ABERTA" || value === "ACEITA" || value === "CANCELADA";
  }

  // Monta startups/{startupId}.
  // É usada por createOffer para validar a existência da startup dentro da transaction.
  private getStartupRef(startupId: string) {
    return this.db.collection("startups").doc(startupId);
  }

  // Monta wallets/{uid}.
  // É usada pelo aceite para transferir saldo entre comprador e vendedor.
  private getWalletRef(uid: string) {
    return this.db.collection("wallets").doc(uid);
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

  // Monta a coleção transactions.
  // É usada pelo aceite para registrar uma trilha contábil para cada lado da negociação.
  private getTransactionsRef() {
    return this.db.collection("transactions");
  }

  // Normaliza e valida a wallet lida do Firestore.
  // É chamada por acceptOffer antes de transferir saldo entre comprador e vendedor.
  private toWalletRecord(
    uid: string,
    data: FirebaseFirestore.DocumentData | undefined,
  ): WalletRecord {
    if (!this.isNonNegativeInteger(data?.saldoCentavos)) {
      throw new AppError(
        "Carteira com saldoCentavos inválido.",
        500,
        "INVALID_WALLET_STATE",
      );
    }

    return {
      uid: this.isNonEmptyString(data?.uid) ? data.uid.trim() : uid,
      saldoCentavos: data.saldoCentavos,
    };
  }

  // Normaliza e valida a holding lida do Firestore.
  // É chamada por createOffer, cancelOffer e acceptOffer antes de qualquer conta de bloqueio/desbloqueio.
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

    if (data.valorTotalCentavos !== data.quantidade * data.precoUnitarioCentavos) {
      throw new AppError(
        "Oferta com valorTotalCentavos inconsistente.",
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

  // Calcula o novo preço médio da holding do comprador.
  // É chamada por acceptOffer quando o comprador já possui tokens da mesma startup
  // e precisamos consolidar o custo médio da posição recebida no balcão.
  private calculateAveragePriceInCents(
    quantidadeAtual: number,
    precoMedioAtualCentavos: number,
    quantidadeComprada: number,
    precoCompraCentavos: number,
  ): number {
    const novaQuantidade = quantidadeAtual + quantidadeComprada;

    if (!this.isPositiveInteger(novaQuantidade)) {
      throw new AppError(
        "Holding com quantidade final inválida.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    const weightedTotal =
      quantidadeAtual * precoMedioAtualCentavos +
      quantidadeComprada * precoCompraCentavos;

    if (!Number.isSafeInteger(weightedTotal) || weightedTotal < 0) {
      throw new AppError(
        "Holding com preço médio inválido.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    return Math.floor(weightedTotal / novaQuantidade);
  }

  // Executa o aceite de oferta inteiro dentro de uma Firestore Transaction.
  // É chamada somente por acceptOfferService depois da validação de autenticação e offerId.
  // O aceite precisa ser atômico porque saldo, holdings, offer, histórico e preço
  // representam a mesma negociação e não podem divergir entre si.
  async acceptOffer(buyerId: string, offerId: string): Promise<AcceptOfferResult> {
    return this.db.runTransaction<AcceptOfferResult>(async (transaction) => {
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

      // O vendedor já bloqueou seus próprios tokens na criação da oferta.
      // Permitir autoaceite quebraria a regra de balcão e mascararia uma operação direta.
      if (offer.vendedorId === buyerId) {
        throw new AppError(
          "O comprador não pode aceitar a própria oferta.",
          409,
          "CANNOT_ACCEPT_OWN_OFFER",
        );
      }

      const sellerId = offer.vendedorId;
      const buyerWalletRef = this.getWalletRef(buyerId);
      const sellerWalletRef = this.getWalletRef(sellerId);
      const sellerHoldingRef = this.getHoldingRef(sellerId, offer.startupId);
      const buyerHoldingRef = this.getHoldingRef(buyerId, offer.startupId);
      const startupRef = this.getStartupRef(offer.startupId);
      const buyerTransactionRef = this.getTransactionsRef().doc();
      const sellerTransactionRef = this.getTransactionsRef().doc();

      const [
        buyerWalletDoc,
        sellerWalletDoc,
        sellerHoldingDoc,
        buyerHoldingDoc,
        startupDoc,
      ] = await Promise.all([
        transaction.get(buyerWalletRef),
        transaction.get(sellerWalletRef),
        transaction.get(sellerHoldingRef),
        transaction.get(buyerHoldingRef),
        transaction.get(startupRef),
      ]);

      if (!buyerWalletDoc.exists) {
        throw new AppError(
          "Carteira do comprador não encontrada.",
          404,
          "WALLET_NOT_FOUND",
        );
      }

      if (!sellerWalletDoc.exists) {
        throw new AppError(
          "Carteira do vendedor não encontrada.",
          404,
          "WALLET_NOT_FOUND",
        );
      }

      if (!sellerHoldingDoc.exists) {
        throw new AppError(
          "Holding do vendedor não encontrada para a startup informada.",
          404,
          "HOLDING_NOT_FOUND",
        );
      }

      if (!startupDoc.exists) {
        throw new AppError(
          "Startup da oferta não encontrada.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      const buyerWallet = this.toWalletRecord(buyerId, buyerWalletDoc.data());
      const sellerWallet = this.toWalletRecord(sellerId, sellerWalletDoc.data());
      const sellerHolding = this.toHoldingRecord(
        sellerId,
        offer.startupId,
        sellerHoldingDoc.data(),
      );
      const buyerHolding = buyerHoldingDoc.exists
        ? this.toHoldingRecord(buyerId, offer.startupId, buyerHoldingDoc.data())
        : null;

      if (buyerWallet.saldoCentavos < offer.valorTotalCentavos) {
        throw new AppError(
          "Saldo fictício insuficiente para aceitar a oferta.",
          409,
          "INSUFFICIENT_BALANCE",
        );
      }

      // O aceite consome apenas quantidadeBloqueada do vendedor.
      // Esses tokens foram reservados na criação da oferta e são a única fonte legítima da oferta aberta.
      if (sellerHolding.quantidadeBloqueada < offer.quantidade) {
        throw new AppError(
          "O vendedor não possui tokens bloqueados suficientes para esta oferta.",
          409,
          "INSUFFICIENT_LOCKED_TOKENS",
        );
      }

      const buyerSaldoAnteriorCentavos = buyerWallet.saldoCentavos;
      const sellerSaldoAnteriorCentavos = sellerWallet.saldoCentavos;
      const buyerSaldoNovoCentavos =
        buyerSaldoAnteriorCentavos - offer.valorTotalCentavos;
      const sellerSaldoNovoCentavos =
        sellerSaldoAnteriorCentavos + offer.valorTotalCentavos;

      if (
        !this.isNonNegativeInteger(buyerSaldoNovoCentavos) ||
        !this.isNonNegativeInteger(sellerSaldoNovoCentavos) ||
        sellerSaldoNovoCentavos < sellerSaldoAnteriorCentavos
      ) {
        throw new AppError(
          "Carteira com estado inválido após transferência de saldo.",
          500,
          "INVALID_WALLET_STATE",
        );
      }

      const sellerQuantidadeBloqueadaAtualizada =
        sellerHolding.quantidadeBloqueada - offer.quantidade;

      if (!this.isNonNegativeInteger(sellerQuantidadeBloqueadaAtualizada)) {
        throw new AppError(
          "Holding do vendedor com bloqueio inválido após aceite.",
          500,
          "INVALID_HOLDING_STATE",
        );
      }

      const buyerQuantidadeAnterior = buyerHolding?.quantidade ?? 0;
      const buyerQuantidadeBloqueada = buyerHolding?.quantidadeBloqueada ?? 0;
      const buyerQuantidadeAtual = buyerQuantidadeAnterior + offer.quantidade;

      if (
        !this.isNonNegativeInteger(buyerQuantidadeBloqueada) ||
        !this.isPositiveInteger(buyerQuantidadeAtual)
      ) {
        throw new AppError(
          "Holding do comprador com estado inválido após aceite.",
          500,
          "INVALID_HOLDING_STATE",
        );
      }

      // O preço médio do comprador é recalculado porque a posição agora mistura
      // lotes anteriores com o lote recebido da oferta pelo preço negociado.
      const buyerPrecoMedioCentavos = buyerHolding
        ? this.calculateAveragePriceInCents(
            buyerHolding.quantidade,
            buyerHolding.precoMedioCentavos,
            offer.quantidade,
            offer.precoUnitarioCentavos,
          )
        : offer.precoUnitarioCentavos;

      const commonTimestamp = FieldValue.serverTimestamp();

      transaction.update(buyerWalletRef, {
        saldoCentavos: buyerSaldoNovoCentavos,
        updatedAt: commonTimestamp,
      });

      transaction.update(sellerWalletRef, {
        saldoCentavos: sellerSaldoNovoCentavos,
        updatedAt: commonTimestamp,
      });

      transaction.update(sellerHoldingRef, {
        uid: sellerId,
        startupId: offer.startupId,
        quantidade: sellerHolding.quantidade,
        quantidadeBloqueada: sellerQuantidadeBloqueadaAtualizada,
        precoMedioCentavos: sellerHolding.precoMedioCentavos,
        updatedAt: commonTimestamp,
      });

      if (!buyerHoldingDoc.exists) {
        transaction.set(buyerHoldingRef, {
          uid: buyerId,
          startupId: offer.startupId,
          quantidade: buyerQuantidadeAtual,
          quantidadeBloqueada: 0,
          precoMedioCentavos: buyerPrecoMedioCentavos,
          createdAt: commonTimestamp,
          updatedAt: commonTimestamp,
        });
      } else {
        transaction.update(buyerHoldingRef, {
          uid: buyerId,
          startupId: offer.startupId,
          quantidade: buyerQuantidadeAtual,
          quantidadeBloqueada: buyerQuantidadeBloqueada,
          precoMedioCentavos: buyerPrecoMedioCentavos,
          updatedAt: commonTimestamp,
        });
      }

      transaction.update(offerRef, {
        status: "ACEITA",
        compradorId: buyerId,
        acceptedAt: commonTimestamp,
        updatedAt: commonTimestamp,
      });

      // O histórico registra duas transactions porque compra e venda são visões contábeis diferentes.
      // Isso permite que cada carteira reconstrua seu próprio saldo e a contraparte da negociação.
      transaction.set(buyerTransactionRef, {
        userId: buyerId,
        counterpartyUserId: sellerId,
        startupId: offer.startupId,
        offerId: offer.id,
        tipo: "COMPRA_BALCAO",
        quantidade: offer.quantidade,
        precoUnitarioCentavos: offer.precoUnitarioCentavos,
        valorTotalCentavos: offer.valorTotalCentavos,
        saldoAnteriorCentavos: buyerSaldoAnteriorCentavos,
        saldoNovoCentavos: buyerSaldoNovoCentavos,
        createdAt: commonTimestamp,
      });

      transaction.set(sellerTransactionRef, {
        userId: sellerId,
        counterpartyUserId: buyerId,
        startupId: offer.startupId,
        offerId: offer.id,
        tipo: "VENDA_BALCAO",
        quantidade: offer.quantidade,
        precoUnitarioCentavos: offer.precoUnitarioCentavos,
        valorTotalCentavos: offer.valorTotalCentavos,
        saldoAnteriorCentavos: sellerSaldoAnteriorCentavos,
        saldoNovoCentavos: sellerSaldoNovoCentavos,
        createdAt: commonTimestamp,
      });

      // OFERTA_ACEITA usa o preço negociado da própria oferta porque esse foi o preço
      // efetivamente aceito entre as partes e, portanto, é o sinal correto de alta ou baixa.
      try {
        this.priceService.applyTradePriceUpdateToTransaction({
          transaction,
          startupRef,
          startupId: offer.startupId,
          startupData: startupDoc.data(),
          quantidade: offer.quantidade,
          motivo: "OFERTA_ACEITA",
          commonTimestamp,
          transactionId: buyerTransactionRef.id,
          offerId: offer.id,
          precoNegociadoCentavos: offer.precoUnitarioCentavos,
        });
      } catch (error) {
        // No aceite, tratamos preço inválido como estado inválido da startup porque
        // o preço atual e seus metadados fazem parte do documento startups/{startupId}.
        if (error instanceof AppError && error.code === "INVALID_PRICE_STATE") {
          throw new AppError(error.message, 500, "INVALID_STARTUP_STATE");
        }

        if (error instanceof AppError && error.code === "INVALID_PRICE_IMPACT_REASON") {
          throw new AppError(error.message, 500, "INTERNAL_ERROR");
        }

        throw error;
      }

      return {
        offerId: offer.id,
        status: "ACEITA",
        startupId: offer.startupId,
        compradorId: buyerId,
        vendedorId: sellerId,
        quantidade: offer.quantidade,
        precoUnitarioCentavos: offer.precoUnitarioCentavos,
        valorTotalCentavos: offer.valorTotalCentavos,
        buyerTransactionId: buyerTransactionRef.id,
        sellerTransactionId: sellerTransactionRef.id,
      };
    });
  }
}
