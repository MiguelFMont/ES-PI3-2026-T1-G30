// Este arquivo concentra o acesso ao Firestore para a compra direta de tokens.
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
}
