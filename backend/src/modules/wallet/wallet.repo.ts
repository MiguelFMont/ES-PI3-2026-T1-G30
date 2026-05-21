/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:
ele vai herdar a classe base do repositório do firestore 
entra na coleção de transações, filtra pelo uid do usuário 
ordena esses dados por data, de forma decrescente (mais recente primeiro)
retornar a lista de operações 

acessar a wallet 
pegar os dados sa subcoleção das holdings e das transações 
trasnformar esses documentos em objetos
retornar as coleções de objetos como informações pro dashboard e para os gráficos de valorização 
*/

// Autor: Samuel Campovilla
// Este arquivo concentra o acesso ao Firestore para o módulo de carteira.
// Ele é chamado por wallet.service.ts, que valida regras de negócio antes de persistir dados.

import * as admin from 'firebase-admin';
import { FirestoreBaseRepo } from "../../infra/repositories/firestore.base.repo";
// função que retorna a instancia do firestore 
// ela permite acessar o banco de dados 
import { getDb } from "../../config/firebase";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { AppError } from "../../shared/errors/app.error";

// Representa o documento wallets/{uid} como ele é manipulado internamente no backend.
// Os timestamps ficam como unknown aqui porque o service faz a validação/serialização final.
export interface WalletRecord {
  uid: string;
  saldoCentavos: number;
  createdAt: unknown;
  updatedAt: unknown;
}

// Representa cada documento da subcoleção wallets/{uid}/holdings/{startupId}.
export interface HoldingRecord {
  uid: string;
  startupId: string;
  quantidade: number;
  quantidadeBloqueada: number;
  precoMedioCentavos: number;
  createdAt: unknown;
  updatedAt: unknown;
}

// Fonte única dos tipos oficiais aceitos pelo contrato público do histórico.
// Service e repository reutilizam esta lista para manter validação e persistência consistentes.
export const VALID_TRANSACTION_TYPES = [
  "ADICIONAR_SALDO",
  "SACAR_SALDO",
  "COMPRA_DIRETA",
  "VENDA_DIRETA",
  "COMPRA_BALCAO",
  "VENDA_BALCAO",
] as const;

export type TipoTransacao = (typeof VALID_TRANSACTION_TYPES)[number];

// Representa o documento transactions/{transactionId} como ele é transportado internamente.
// O service normaliza os tipos e omite userId do DTO público antes de responder ao cliente.
export interface TransactionRecord {
  id: string;
  userId: unknown;
  counterpartyUserId?: unknown;
  startupId?: unknown;
  offerId?: unknown;
  tipo: unknown;
  quantidade?: unknown;
  precoUnitarioCentavos?: unknown;
  valorTotalCentavos: unknown;
  saldoAnteriorCentavos?: unknown;
  saldoNovoCentavos?: unknown;
  createdAt: unknown;
}

export interface TransactionFilters {
  startupId?: string;
  tipo?: TipoTransacao;
}

// função que herda o que o firebaserepo tem 
export class WalletRepo extends FirestoreBaseRepo {
  // Referência compartilhada do Firestore para todas as operações deste repositório.
  private db = getDb();

  constructor() {
    // chama o construtor da classe pai (firestorebaserepo)
    super('wallets');
  }

  // Monta a referência do documento principal da carteira.
  // É usada por getWallet, getOrCreateWallet, listHoldings e addBalance.
  private getWalletRef(uid: string) {
    return this.db.collection("wallets").doc(uid);
  }

  // Monta a referência da coleção transactions.
  // É usada pelo histórico e pelo registro atômico de ADICIONAR_SALDO.
  private getTransactionsRef() {
    return this.db.collection("transactions");
  }

  // Garante que um valor vindo do Firestore é inteiro e não negativo.
  // É usada para validar saldo e os campos numéricos das holdings.
  private isNonNegativeInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value >= 0;
  }

  // Normaliza um documento de wallet lido do Firestore para a estrutura interna do módulo.
  // É chamada pelos métodos getWallet, getOrCreateWallet e addBalance.
  private toWalletRecord(
    uid: string,
    walletData: FirebaseFirestore.DocumentData | undefined,
  ): WalletRecord {
    if (!this.isNonNegativeInteger(walletData?.saldoCentavos)) {
      throw new AppError(
        "Carteira com saldo inválido.",
        500,
        "INVALID_WALLET_STATE",
      );
    }

    return {
      // Se o documento não tiver uid salvo corretamente, o repo usa o uid do caminho.
      uid:
        typeof walletData?.uid === "string" && walletData.uid.trim() !== ""
          ? walletData.uid
          : uid,
      saldoCentavos: walletData.saldoCentavos,
      createdAt: walletData?.createdAt,
      updatedAt: walletData?.updatedAt,
    };
  }

  // Normaliza um documento de holding lido do Firestore.
  // É chamada por listHoldings para que o service receba uma estrutura consistente.
  private toHoldingRecord(
    uid: string,
    startupId: string,
    holdingData: FirebaseFirestore.DocumentData | undefined,
  ): HoldingRecord {
    if (!this.isNonNegativeInteger(holdingData?.quantidade)) {
      throw new AppError(
        "Holding com quantidade inválida.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    if (!this.isNonNegativeInteger(holdingData?.quantidadeBloqueada)) {
      throw new AppError(
        "Holding com quantidade bloqueada inválida.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    if (!this.isNonNegativeInteger(holdingData?.precoMedioCentavos)) {
      throw new AppError(
        "Holding com preço médio inválido.",
        500,
        "INVALID_HOLDING_STATE",
      );
    }

    return {
      // O uid e o startupId podem ser inferidos do caminho caso o documento venha incompleto.
      uid:
        typeof holdingData?.uid === "string" && holdingData.uid.trim() !== ""
          ? holdingData.uid
          : uid,
      startupId:
        typeof holdingData?.startupId === "string" &&
        holdingData.startupId.trim() !== ""
          ? holdingData.startupId
          : startupId,
      quantidade: holdingData.quantidade,
      quantidadeBloqueada: holdingData.quantidadeBloqueada,
      precoMedioCentavos: holdingData.precoMedioCentavos,
      createdAt: holdingData?.createdAt,
      updatedAt: holdingData?.updatedAt,
    };
  }

  // Samuel Campovilla:
  // A query do histórico sempre começa pelo userId autenticado.
  // Filtros extras apenas refinam o conjunto já limitado ao dono da carteira.
  async listTransactions(
    uid: string,
    filters: TransactionFilters,
  ): Promise<TransactionRecord[]> {
    let query: admin.firestore.Query = this
      .getTransactionsRef()
      .where('userId', '==', uid);

    if (filters.startupId) {
      query = query.where('startupId', '==', filters.startupId);
    }

    if (filters.tipo) {
      query = query.where('tipo', '==', filters.tipo);
    }

    const operacoesSnapshot = await query
      .orderBy('createdAt', 'desc')
      .get();

    if (operacoesSnapshot.empty) {
      return [];
    }

    return operacoesSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => {
      const data = doc.data();

      return {
        id: doc.id,
        userId: data.userId,
        counterpartyUserId: data.counterpartyUserId,
        startupId: data.startupId,
        offerId: data.offerId,
        tipo: data.tipo,
        quantidade: data.quantidade,
        precoUnitarioCentavos: data.precoUnitarioCentavos,
        valorTotalCentavos: data.valorTotalCentavos,
        saldoAnteriorCentavos: data.saldoAnteriorCentavos,
        saldoNovoCentavos: data.saldoNovoCentavos,
        createdAt: data.createdAt,
      };
    });
  }

  // busca os dados agregados da wallet para o dashboard 
  async getDadosDashboard(uid: string) {
    const db = getDb();

    // busca o documento principal da wallet
    const walletDoc = await db
      .collection('wallets')
      .doc(uid)
      .get();

    // verifica se o usuário tem wallet cadastrada (documento no firestore)
    if (!walletDoc.exists) return null;

    // busca todos as holdings do usuário (tokens por startup)
    const holdingsSnapshot = await db
      .collection('wallets')
      .doc(uid)
      .collection('holdings')
      .get();

    // busca todas as transações do usuário
    const transacoesSnapshot = await db
      .collection('transactions')
      .where('userId', '==', uid)
      .orderBy('createdAt', 'asc')
      .get();

    // retorna os campos do documento wallet 
    const wallet = walletDoc.data();

    // obejtos holdings 
    const holdings = holdingsSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // objetos transações 
    const transacoes = transacoesSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // retorna os conjuntos de objetos em um único objeto 
    return { wallet, holdings, transacoes };
  }

  // Busca a carteira do usuário sem criar nada.
  // Este método está disponível para cenários de leitura pura, embora o fluxo principal use getOrCreateWallet.
  async getWallet(uid: string): Promise<WalletRecord | null> {
    const walletDoc = await this.getWalletRef(uid).get();

    if (!walletDoc.exists) {
      return null;
    }

    return this.toWalletRecord(uid, walletDoc.data());
  }

  // Busca a carteira e cria automaticamente com saldoCentavos = 0 se ela não existir.
  // É chamada por getWalletService para evitar que o app quebre quando o usuário ainda não tem wallet.
  async getOrCreateWallet(uid: string): Promise<WalletRecord> {
    return this.db.runTransaction<WalletRecord>(async (transaction) => {
      const walletRef = this.getWalletRef(uid);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        const now = Timestamp.now();
        const wallet: WalletRecord = {
          uid,
          saldoCentavos: 0,
          createdAt: now,
          updatedAt: now,
        };

        transaction.set(walletRef, wallet);
        return wallet;
      }

      return this.toWalletRecord(uid, walletDoc.data());
    });
  }

  // Lista todas as holdings da carteira.
  // É chamada por listHoldingsService e retorna [] quando a subcoleção ainda não tem documentos.
  async listHoldings(uid: string): Promise<HoldingRecord[]> {
    const holdingsSnapshot = await this
      .getWalletRef(uid)
      .collection("holdings")
      .get();

    return holdingsSnapshot.docs.map((holdingDoc) =>
      this.toHoldingRecord(uid, holdingDoc.id, holdingDoc.data()),
    );
  }

  // Soma valorCentavos ao saldo atual da carteira dentro de uma transação.
  // É chamada por addBalanceService para garantir consistência mesmo com chamadas simultâneas.
  async addBalance(uid: string, valorCentavos: number): Promise<WalletRecord> {
    return this.db.runTransaction<WalletRecord>(async (transaction) => {
      const walletRef = this.getWalletRef(uid);
      const transactionRef = this.getTransactionsRef().doc();
      const walletDoc = await transaction.get(walletRef);
      const now = Timestamp.now();
      const createdAt = FieldValue.serverTimestamp();

      // Se a carteira ainda não existir, ela já nasce com o valor adicionado.
      if (!walletDoc.exists) {
        const wallet: WalletRecord = {
          uid,
          saldoCentavos: valorCentavos,
          createdAt: now,
          updatedAt: now,
        };

        transaction.set(walletRef, wallet);
        // O histórico de ADICIONAR_SALDO é escrito na mesma transação da wallet
        // para não existir saldo atualizado sem o respectivo registro de auditoria.
        transaction.set(transactionRef, {
          userId: uid,
          tipo: "ADICIONAR_SALDO",
          valorTotalCentavos: valorCentavos,
          saldoAnteriorCentavos: 0,
          saldoNovoCentavos: valorCentavos,
          createdAt,
        });
        return wallet;
      }

      const currentWallet = this.toWalletRecord(uid, walletDoc.data());
      const saldoAnteriorCentavos = currentWallet.saldoCentavos;
      const saldoCentavos = currentWallet.saldoCentavos + valorCentavos;

      if (!this.isNonNegativeInteger(saldoCentavos)) {
        throw new AppError(
          "Carteira com saldo inválido.",
          500,
          "INVALID_WALLET_STATE",
        );
      }

      // Esta operação atualiza apenas saldoCentavos e updatedAt.
      transaction.update(walletRef, {
        saldoCentavos,
        updatedAt: now,
      });

      // O histórico público da carteira depende deste documento.
      // A gravação aqui mantém o add-balance alinhado com compra e venda direta na coleção transactions.
      transaction.set(transactionRef, {
        userId: uid,
        tipo: "ADICIONAR_SALDO",
        valorTotalCentavos: valorCentavos,
        saldoAnteriorCentavos,
        saldoNovoCentavos: saldoCentavos,
        createdAt,
      });

      return {
        ...currentWallet,
        saldoCentavos,
        updatedAt: now,
      };
    });
  }

  // Debita valorCentavos do saldo atual da carteira dentro de uma transação.
  // Garante saldo suficiente e registra a movimentação SACAR_SALDO no histórico.
  async withdraw(uid: string, valorCentavos: number): Promise<WalletRecord> {
    return this.db.runTransaction<WalletRecord>(async (transaction) => {
      const walletRef = this.getWalletRef(uid);
      const transactionRef = this.getTransactionsRef().doc();
      const walletDoc = await transaction.get(walletRef);
      const now = Timestamp.now();
      const createdAt = FieldValue.serverTimestamp();

      if (!walletDoc.exists) {
        throw new AppError(
          "Saldo insuficiente para realizar o saque.",
          409,
          "INSUFFICIENT_BALANCE",
        );
      }

      const currentWallet = this.toWalletRecord(uid, walletDoc.data());
      const saldoAnteriorCentavos = currentWallet.saldoCentavos;

      if (saldoAnteriorCentavos < valorCentavos) {
        throw new AppError(
          "Saldo insuficiente para realizar o saque.",
          409,
          "INSUFFICIENT_BALANCE",
        );
      }

      const saldoCentavos = saldoAnteriorCentavos - valorCentavos;

      if (!this.isNonNegativeInteger(saldoCentavos)) {
        throw new AppError(
          "Carteira com saldo inválido.",
          500,
          "INVALID_WALLET_STATE",
        );
      }

      transaction.update(walletRef, {
        saldoCentavos,
        updatedAt: now,
      });

      transaction.set(transactionRef, {
        userId: uid,
        tipo: "SACAR_SALDO",
        valorTotalCentavos: valorCentavos,
        saldoAnteriorCentavos,
        saldoNovoCentavos: saldoCentavos,
        createdAt,
      });

      return {
        ...currentWallet,
        saldoCentavos,
        updatedAt: now,
      };
    });
  }
}
