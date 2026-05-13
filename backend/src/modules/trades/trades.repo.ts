// Este arquivo concentra o acesso ao Firestore para compra e venda direta de tokens.
// O service chama este repositório depois de validar o body e a autenticação.

import { getDb } from "../../config/firebase";
import { AppError } from "../../shared/errors/app.error";
import { FieldValue } from "firebase-admin/firestore";

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
  createdAt?: unknown;
}

interface StartupRecord {
  id: string;
  tokensDisponiveis: number;
  precoTokenAtualCentavos: number;
}

interface DirectSellStartupRecord extends StartupRecord {
  descontoVendaDiretaBps: number;
  totalTokens?: number;
}

export interface DirectBuyResult {
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

export interface DirectSellResult {
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

export class TradesRepo {
  // Referência compartilhada do Firestore usada por este módulo.
  private db = getDb();

  // Valida inteiros estritamente positivos.
  // É usada para preço do token e quantidade de compra.
  private isPositiveInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value > 0;
  }

  // Valida inteiros maiores ou iguais a zero.
  // É usada para saldo, tokens disponíveis e campos da holding.
  private isNonNegativeInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value >= 0;
  }

  // Valida desconto em basis points no intervalo [0, 10000).
  // É usada para impedir recompra com desconto inválido na venda direta.
  private isBpsDiscount(value: unknown): value is number {
    return (
      typeof value === "number" &&
      Number.isInteger(value) &&
      value >= 0 &&
      value < 10000
    );
  }

  // Monta a referência wallets/{uid}.
  private getWalletRef(uid: string) {
    return this.db.collection("wallets").doc(uid);
  }

  // Monta a referência wallets/{uid}/holdings/{startupId}.
  private getHoldingRef(uid: string, startupId: string) {
    return this.getWalletRef(uid).collection("holdings").doc(startupId);
  }

  // Monta a referência startups/{startupId}.
  private getStartupRef(startupId: string) {
    return this.db.collection("startups").doc(startupId);
  }

  // Valida o documento da wallet lido do Firestore.
  // É chamada durante a transação de compra direta.
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
      uid: typeof data?.uid === "string" && data.uid.trim() !== "" ? data.uid : uid,
      saldoCentavos: data.saldoCentavos,
    };
  }

  // Valida o documento da holding lido do Firestore.
  // É chamada apenas quando o usuário já possui holding para a startup.
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
      uid: typeof data?.uid === "string" && data.uid.trim() !== "" ? data.uid : uid,
      startupId:
        typeof data?.startupId === "string" && data.startupId.trim() !== ""
          ? data.startupId
          : startupId,
      quantidade: data.quantidade,
      quantidadeBloqueada: data.quantidadeBloqueada,
      precoMedioCentavos: data.precoMedioCentavos,
      createdAt: data?.createdAt,
    };
  }

  // Valida o documento da startup lido do Firestore.
  // É chamada no início da transação para obter preço e estoque de tokens.
  private toStartupRecord(
    startupId: string,
    data: FirebaseFirestore.DocumentData | undefined,
  ): StartupRecord {
    if (!this.isNonNegativeInteger(data?.tokensDisponiveis)) {
      throw new AppError(
        "Startup com tokensDisponiveis inválido.",
        500,
        "INVALID_STARTUP_STATE",
      );
    }

    if (!this.isPositiveInteger(data?.precoTokenAtualCentavos)) {
      throw new AppError(
        "Startup com precoTokenAtualCentavos inválido.",
        500,
        "INVALID_STARTUP_STATE",
      );
    }

    return {
      id: startupId,
      tokensDisponiveis: data.tokensDisponiveis,
      precoTokenAtualCentavos: data.precoTokenAtualCentavos,
    };
  }

  // Samuel Campovilla:
  // Normaliza startups/{startupId} para o fluxo de venda direta.
  // É usada apenas por directSell, depois que a existência da startup já foi confirmada.
  // Aqui validamos os campos adicionais da Fase 3:
  // - descontoVendaDiretaBps, usado no cálculo do preço de recompra;
  // - totalTokens, quando existir, para impedir recompra acima do limite da startup.
  // Valida os campos extras usados exclusivamente na venda direta.
  // O totalTokens continua opcional para não quebrar startups legadas sem esse campo.
  private toDirectSellStartupRecord(
    startupId: string,
    data: FirebaseFirestore.DocumentData | undefined,
  ): DirectSellStartupRecord {
    const startup = this.toStartupRecord(startupId, data);

    if (!this.isBpsDiscount(data?.descontoVendaDiretaBps)) {
      throw new AppError(
        "Startup com descontoVendaDiretaBps inválido.",
        500,
        "INVALID_STARTUP_STATE",
      );
    }

    let totalTokens: number | undefined;

    if (
      data &&
      Object.prototype.hasOwnProperty.call(data, "totalTokens") &&
      data.totalTokens !== undefined
    ) {
      if (!this.isPositiveInteger(data.totalTokens)) {
        throw new AppError(
          "Startup com totalTokens inválido.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      totalTokens = data.totalTokens;
    }

    return {
      ...startup,
      descontoVendaDiretaBps: data.descontoVendaDiretaBps,
      totalTokens,
    };
  }

  // Calcula o novo preço médio da holding existente.
  // Essa conta roda dentro da transação porque depende do estado atual lido do Firestore.
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

  // Samuel Campovilla:
  // Calcula o preço unitário pago pela startup na recompra.
  // É usada apenas por directSell e segue a fórmula:
  // floor(precoTokenAtualCentavos * (10000 - descontoVendaDiretaBps) / 10000).
  // O valor final precisa permanecer inteiro positivo em centavos.
  // Calcula o preço unitário da recompra com desconto em bps.
  // O valor precisa continuar inteiro positivo em centavos.
  private calculateDirectSellPriceInCents(
    precoTokenAtualCentavos: number,
    descontoVendaDiretaBps: number,
  ): number {
    const precoUnitarioCentavos = Math.floor(
      (precoTokenAtualCentavos * (10000 - descontoVendaDiretaBps)) / 10000,
    );

    if (!this.isPositiveInteger(precoUnitarioCentavos)) {
      throw new AppError(
        "Startup com preço de recompra inválido.",
        500,
        "INVALID_STARTUP_STATE",
      );
    }

    return precoUnitarioCentavos;
  }

  // Executa a compra direta inteira dentro de uma Firestore Transaction.
  // Atualiza wallet, startup, holding e registra a transaction de COMPRA_DIRETA.
  async directBuy(
    uid: string,
    startupId: string,
    quantidade: number,
  ): Promise<DirectBuyResult> {
    return this.db.runTransaction<DirectBuyResult>(async (transaction) => {
      const walletRef = this.getWalletRef(uid);
      const holdingRef = this.getHoldingRef(uid, startupId);
      const startupRef = this.getStartupRef(startupId);
      const transactionRef = this.db.collection("transactions").doc();

      const [startupDoc, walletDoc, holdingDoc] = await Promise.all([
        transaction.get(startupRef),
        transaction.get(walletRef),
        transaction.get(holdingRef),
      ]);

      if (!startupDoc.exists) {
        throw new AppError(
          "Startup não encontrada.",
          404,
          "STARTUP_NOT_FOUND",
        );
      }

      const startup = this.toStartupRecord(startupId, startupDoc.data());
      const wallet = walletDoc.exists
        ? this.toWalletRecord(uid, walletDoc.data())
        : {
            uid,
            saldoCentavos: 0,
          };

      const holding = holdingDoc.exists
        ? this.toHoldingRecord(uid, startupId, holdingDoc.data())
        : null;

      const precoUnitarioCentavos = startup.precoTokenAtualCentavos;
      const valorTotalCentavos = precoUnitarioCentavos * quantidade;

      if (!Number.isSafeInteger(valorTotalCentavos) || valorTotalCentavos <= 0) {
        throw new AppError(
          "Valor total da compra é inválido.",
          400,
          "INVALID_QUANTITY",
        );
      }

      if (wallet.saldoCentavos < valorTotalCentavos) {
        throw new AppError(
          "Saldo fictício insuficiente para realizar a compra.",
          409,
          "INSUFFICIENT_BALANCE",
        );
      }

      if (startup.tokensDisponiveis < quantidade) {
        throw new AppError(
          "A startup não possui tokens suficientes para esta compra.",
          409,
          "INSUFFICIENT_STARTUP_TOKENS",
        );
      }

      const saldoAnteriorCentavos = wallet.saldoCentavos;
      const saldoNovoCentavos = saldoAnteriorCentavos - valorTotalCentavos;
      const quantidadeAnterior = holding?.quantidade ?? 0;
      const quantidadeBloqueada = holding?.quantidadeBloqueada ?? 0;
      const quantidadeAtual = quantidadeAnterior + quantidade;
      const precoMedioCentavos = holding
        ? this.calculateAveragePriceInCents(
            holding.quantidade,
            holding.precoMedioCentavos,
            quantidade,
            precoUnitarioCentavos,
          )
        : precoUnitarioCentavos;

      const commonTimestamp = FieldValue.serverTimestamp();

      if (!walletDoc.exists) {
        transaction.set(walletRef, {
          uid,
          saldoCentavos: saldoNovoCentavos,
          createdAt: commonTimestamp,
          updatedAt: commonTimestamp,
        });
      } else {
        transaction.update(walletRef, {
          saldoCentavos: saldoNovoCentavos,
          updatedAt: commonTimestamp,
        });
      }

      transaction.update(startupRef, {
        tokensDisponiveis: startup.tokensDisponiveis - quantidade,
        updatedAt: commonTimestamp,
      });

      if (!holdingDoc.exists) {
        transaction.set(holdingRef, {
          uid,
          startupId,
          quantidade: quantidadeAtual,
          quantidadeBloqueada: 0,
          precoMedioCentavos,
          createdAt: commonTimestamp,
          updatedAt: commonTimestamp,
        });
      } else {
        transaction.update(holdingRef, {
          uid,
          startupId,
          quantidade: quantidadeAtual,
          quantidadeBloqueada,
          precoMedioCentavos,
          updatedAt: commonTimestamp,
        });
      }

      transaction.set(transactionRef, {
        userId: uid,
        startupId,
        tipo: "COMPRA_DIRETA",
        quantidade,
        precoUnitarioCentavos,
        valorTotalCentavos,
        saldoAnteriorCentavos,
        saldoNovoCentavos,
        createdAt: commonTimestamp,
      });

      return {
        transactionId: transactionRef.id,
        startupId,
        quantidade,
        precoUnitarioCentavos,
        valorTotalCentavos,
        saldoAnteriorCentavos,
        saldoNovoCentavos,
        quantidadeAtual,
        quantidadeBloqueada,
        precoMedioCentavos,
      };
    });
  }

  // Samuel Campovilla:
  // Executa a Fase 3 inteira dentro de uma única Firestore Transaction.
  // Este método é chamado somente por directSellService e centraliza todo o fluxo atômico:
  // 1) lê startup, wallet e holding do usuário;
  // 2) valida estado dos documentos;
  // 3) calcula o preço de recompra com desconto;
  // 4) valida posse usando apenas holding.quantidade;
  // 5) atualiza saldoCentavos, holding.quantidade e startup.tokensDisponiveis;
  // 6) registra a transaction com tipo VENDA_DIRETA.
  //
  // Regra crítica: quantidadeBloqueada nunca é somada na validação de posse.
  // Tokens bloqueados em oferta continuam preservados e não podem ser vendidos aqui.
  // Executa a venda direta inteira dentro de uma Firestore Transaction.
  // Usa apenas holding.quantidade como tokens livres e preserva quantidadeBloqueada.
  async directSell(
    uid: string,
    startupId: string,
    quantidade: number,
  ): Promise<DirectSellResult> {
    return this.db.runTransaction<DirectSellResult>(async (transaction) => {
      const walletRef = this.getWalletRef(uid);
      const holdingRef = this.getHoldingRef(uid, startupId);
      const startupRef = this.getStartupRef(startupId);
      const transactionRef = this.db.collection("transactions").doc();

      const [startupDoc, walletDoc, holdingDoc] = await Promise.all([
        transaction.get(startupRef),
        transaction.get(walletRef),
        transaction.get(holdingRef),
      ]);

      if (!startupDoc.exists) {
        throw new AppError(
          "Startup não encontrada.",
          404,
          "STARTUP_NOT_FOUND",
        );
      }

      if (!walletDoc.exists) {
        throw new AppError(
          "Carteira não encontrada.",
          404,
          "WALLET_NOT_FOUND",
        );
      }

      if (!holdingDoc.exists) {
        throw new AppError(
          "Holding não encontrada para a startup informada.",
          404,
          "HOLDING_NOT_FOUND",
        );
      }

      const startup = this.toDirectSellStartupRecord(startupId, startupDoc.data());
      const wallet = this.toWalletRecord(uid, walletDoc.data());
      const holding = this.toHoldingRecord(uid, startupId, holdingDoc.data());

      // Samuel Campovilla:
      // A posse para venda direta considera somente tokens livres em holding.quantidade.
      // quantidadeBloqueada representa tokens presos em ofertas abertas e não entra aqui.
      if (holding.quantidade < quantidade) {
        throw new AppError(
          "Você não possui tokens livres suficientes para vender.",
          409,
          "INSUFFICIENT_TOKENS",
        );
      }

      const precoUnitarioCentavos = this.calculateDirectSellPriceInCents(
        startup.precoTokenAtualCentavos,
        startup.descontoVendaDiretaBps,
      );
      const valorTotalCentavos = precoUnitarioCentavos * quantidade;

      if (!Number.isSafeInteger(valorTotalCentavos) || valorTotalCentavos <= 0) {
        throw new AppError(
          "Valor total da venda é inválido.",
          500,
          "INTERNAL_ERROR",
        );
      }

      const saldoAnteriorCentavos = wallet.saldoCentavos;
      const saldoNovoCentavos = saldoAnteriorCentavos + valorTotalCentavos;

      if (
        !Number.isSafeInteger(saldoNovoCentavos) ||
        saldoNovoCentavos < saldoAnteriorCentavos
      ) {
        throw new AppError(
          "Saldo resultante da venda é inválido.",
          500,
          "INVALID_WALLET_STATE",
        );
      }

      const tokensDisponiveisAtualizados = startup.tokensDisponiveis + quantidade;

      if (
        !Number.isSafeInteger(tokensDisponiveisAtualizados) ||
        tokensDisponiveisAtualizados < startup.tokensDisponiveis
      ) {
        throw new AppError(
          "Quantidade de tokens da startup é inválida após a venda.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      if (
        startup.totalTokens !== undefined &&
        tokensDisponiveisAtualizados > startup.totalTokens
      ) {
        throw new AppError(
          "A startup excederia totalTokens após a recompra.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      const quantidadeAtual = holding.quantidade - quantidade;
      const quantidadeBloqueada = holding.quantidadeBloqueada;
      const commonTimestamp = FieldValue.serverTimestamp();

      // A escrita preserva explicitamente quantidadeBloqueada e precoMedioCentavos.
      // A Fase 3 só reduz os tokens livres do usuário e credita o saldo correspondente.
      transaction.update(walletRef, {
        saldoCentavos: saldoNovoCentavos,
        updatedAt: commonTimestamp,
      });

      transaction.update(holdingRef, {
        uid,
        startupId,
        quantidade: quantidadeAtual,
        quantidadeBloqueada,
        precoMedioCentavos: holding.precoMedioCentavos,
        updatedAt: commonTimestamp,
      });

      transaction.update(startupRef, {
        tokensDisponiveis: tokensDisponiveisAtualizados,
        updatedAt: commonTimestamp,
      });

      transaction.set(transactionRef, {
        userId: uid,
        startupId,
        tipo: "VENDA_DIRETA",
        quantidade,
        precoUnitarioCentavos,
        valorTotalCentavos,
        saldoAnteriorCentavos,
        saldoNovoCentavos,
        createdAt: commonTimestamp,
      });

      return {
        transactionId: transactionRef.id,
        startupId,
        quantidade,
        precoUnitarioCentavos,
        valorTotalCentavos,
        saldoAnteriorCentavos,
        saldoNovoCentavos,
        quantidadeAtual,
        quantidadeBloqueada,
      };
    });
  }
}
