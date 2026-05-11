// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { FirestoreBaseRepo } from '../../infra/repositories/firestore.base.repo';
import { getDb } from '../../config/firebase';

export class UsersRepo extends FirestoreBaseRepo {
  constructor() {
    super('users');
  }

  // Busca o documento do usuário pelo campo uid
  // (o Firestore usa doc IDs gerados automaticamente, então uid é um campo separado)
  async findByUid(uid: string) {
    const snapshot = await getDb()
      .collection(this.collectionName)
      .where('uid', '==', uid)
      .limit(1)
      .get();

    if (snapshot.empty) return null;

    const doc = snapshot.docs[0];
    return { id: doc.id, ...doc.data() } as any;
  }

  // Busca a carteira do usuário na coleção 'wallets'
  async findWalletByUid(uid: string) {
    const snapshot = await getDb()
      .collection('wallets')
      .where('uid', '==', uid)
      .limit(1)
      .get();

    if (snapshot.empty) return null;

    return snapshot.docs[0].data() as any;
  }
}
