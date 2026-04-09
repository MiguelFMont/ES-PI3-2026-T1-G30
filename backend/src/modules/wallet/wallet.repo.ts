import { getDb } from '../../config/firebase';
import * as admin from 'firebase-admin';

// Este arquivo concentra apenas a persistência da carteira no Firestore.
// Ele é usado por wallet.service.ts, que chama o repositório
// depois de validar a entrada recebida pela API.
export type WalletBalanceUpdateResult = {
  uid: string;
  saldoAnterior: number;
  valorAdicionado: number;
  saldoAtual: number;
};

export class WalletRepo {
  // Esta função soma saldo na carteira do usuário diretamente no Firestore.
  // Ela é chamada por addBalanceService em wallet.service.ts.
  // As camadas de rota e controller não acessam o banco diretamente.
  async addBalance(
    uid: string,
    amount: number
  ): Promise<WalletBalanceUpdateResult> {
    const db = getDb();
    const walletRef = db.collection('wallets').doc(uid);

    // A transaction garante que a leitura do saldo atual e a escrita do novo saldo
    // aconteçam como uma operação única.
    // Isso evita inconsistência quando duas requisições tentam atualizar
    // a mesma carteira quase ao mesmo tempo.
    return db.runTransaction<WalletBalanceUpdateResult>(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);

      // A carteira precisa existir porque ela é criada no cadastro do usuário.
      // Se o documento não existir, o fluxo lança erro e a requisição falha.
      if (!walletDoc.exists) {
        throw new Error('Carteira não encontrada');
      }

      const walletData = walletDoc.data();

      // Lê o saldo atual do documento.
      // Se o campo não existir ou vier com tipo inesperado, assume zero
      // para ainda conseguir calcular o novo saldo com segurança.
      const saldoAnterior =
        typeof walletData?.saldo === 'number' ? walletData.saldo : 0;
      const saldoAtual = saldoAnterior + amount;

      // Grava o novo saldo e atualiza o timestamp de modificação.
      // Como isso acontece dentro da mesma transaction, o valor salvo
      // corresponde exatamente ao saldo lido acima.
      transaction.update(walletRef, {
        saldo: saldoAtual,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Esse retorno sobe por todas as camadas:
      // repo -> service -> controller -> resposta HTTP.
      return {
        uid,
        saldoAnterior,
        valorAdicionado: amount,
        saldoAtual,
      };
    });
  }
}
