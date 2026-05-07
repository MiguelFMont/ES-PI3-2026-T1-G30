// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { getFirestore } from "firebase-admin/firestore";

// Estrutura mínima do documento do usuário usada pelo módulo de perfil.
export interface UserRecord {
  uid: string;
  nomeCompleto: string;
  email: string;
  telefone?: string;
  walletId?: string;
  createdAt?: FirebaseFirestore.Timestamp;
}

// Estrutura mínima da wallet lida pelo módulo de perfil.
// Nesta fase o saldo passa a ser lido apenas de saldoCentavos.
export interface WalletRecord {
  saldoCentavos?: number;
  startupIds?: string[];
}

export class UsersRepo {
  private db = getFirestore();

  // Busca o documento users/{uid}.
  // É chamado por UsersService.getPerfil para montar os dados básicos da conta.
  async findByUid(uid: string): Promise<UserRecord | null> {
    const snap = await this.db.collection("users").doc(uid).get();
    if (!snap.exists) return null;
    return { uid: snap.id, ...snap.data() } as UserRecord;
  }

  // Busca o documento wallets/{uid}.
  // É chamado por UsersService.getPerfil para obter o saldo e métricas exibidas ao usuário.
  async findWalletByUid(uid: string): Promise<WalletRecord | null> {
    const snap = await this.db.doc(`wallets/${uid}`).get();
    if (!snap.exists) return null;
    return snap.data() as WalletRecord;
  }
}
