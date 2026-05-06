import { getDb } from "../../config/firebase";
import { FieldValue } from "firebase-admin/firestore";
import { AppError } from "../../shared/errors/app.error";

// Este arquivo concentra apenas a persistência da carteira no Firestore.
// Ele é usado por wallet.service.ts, que chama o repositório
// depois de validar a entrada recebida pela API.
export type WalletBalanceUpdateResult = {
  uid: string;
  saldoAnteriorCentavos: number;
  valorAdicionadoCentavos: number;
  saldoAtualCentavos: number;
  saldoAnterior: number;
  valorAdicionado: number;
  saldoAtual: number;
};

export class WalletRepo {
  private toAmount(cents: number): number {
    return cents / 100;
  }

  private readBalanceInCents(
    walletData: FirebaseFirestore.DocumentData | undefined,
  ): number {
    const balanceInCents = walletData?.saldoCentavos;
    if (Number.isInteger(balanceInCents)) {
      return balanceInCents as number;
    }

    const legacyBalance = walletData?.saldo;
    if (typeof legacyBalance === "number" && Number.isFinite(legacyBalance)) {
      return Math.round(legacyBalance * 100);
    }

    return 0;
  }

  // Esta função soma saldo na carteira do usuário diretamente no Firestore.
  // Ela é chamada por addBalanceService em wallet.service.ts.
  // As camadas de rota e controller não acessam o banco diretamente.
  async addBalance(
    uid: string,
    amountInCents: number,
  ): Promise<WalletBalanceUpdateResult> {
    const db = getDb();
    const walletRef = db.collection("wallets").doc(uid);

    // A transaction garante que a leitura do saldo atual e a escrita do novo saldo
    // aconteçam como uma operação única.
    // Isso evita inconsistência quando duas requisições tentam atualizar
    // a mesma carteira quase ao mesmo tempo.
    return db.runTransaction<WalletBalanceUpdateResult>(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);

      // A carteira precisa existir porque ela é criada no cadastro do usuário.
      // Se o documento não existir, o fluxo lança erro e a requisição falha.
      if (!walletDoc.exists) {
        throw new AppError("Carteira não encontrada", 404);
      }

      const walletData = walletDoc.data();

      // Lê o saldo atual do documento.
      // Se o campo não existir ou vier com tipo inesperado, assume zero
      // para ainda conseguir calcular o novo saldo com segurança.
      const saldoAnteriorCentavos = this.readBalanceInCents(walletData);
      const saldoAtualCentavos = saldoAnteriorCentavos + amountInCents;

      // Grava o novo saldo e atualiza o timestamp de modificação.
      // Como isso acontece dentro da mesma transaction, o valor salvo
      // corresponde exatamente ao saldo lido acima.
      transaction.update(walletRef, {
        saldoCentavos: saldoAtualCentavos,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Esse retorno sobe por todas as camadas:
      // repo -> service -> controller -> resposta HTTP.
      return {
        uid,
        saldoAnteriorCentavos,
        valorAdicionadoCentavos: amountInCents,
        saldoAtualCentavos,
        saldoAnterior: this.toAmount(saldoAnteriorCentavos),
        valorAdicionado: this.toAmount(amountInCents),
        saldoAtual: this.toAmount(saldoAtualCentavos),
      };
    });
  }
}
