import { FirestoreBaseRepo } from '../../infra/repositories/firestore.base.repo';
import { getDb } from '../../config/firebase';
import { Startup } from './startups.modal';

export class StartupsRepo extends FirestoreBaseRepo {
  constructor() {
    super('startups');
  }

  async findByEstagio(estagio: string): Promise<Startup[]> {
    const db = getDb();
    const snapshot = await db.collection('startups')
      .where('estagio', '==', estagio)
      .get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data()
    } as Startup));
  }
}