
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { getFirestore } from 'firebase-admin/firestore';

export interface UserRecord {
  uid: string;
  nomeCompleto: string;
  email: string;
  telefone?: string;
  walletId?: string;
  createdAt?: FirebaseFirestore.Timestamp;
}

export interface WalletRecord {
  saldo: number;
  startupIds?: string[];
}

export class UsersRepo {
  private db = getFirestore();

  async findByUid(uid: string): Promise<UserRecord | null> {
    const snap = await this.db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return { uid: snap.id, ...snap.data() } as UserRecord;
  }

  async findWalletByUid(uid: string): Promise<WalletRecord | null> {
    const snap = await this.db.doc(`wallets/${uid}`).get();
    if (!snap.exists) return null;
    return snap.data() as WalletRecord;
  }
}