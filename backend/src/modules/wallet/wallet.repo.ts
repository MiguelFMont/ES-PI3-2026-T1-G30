/* 
significado do arquivo:

ele vai herdar o repositório do firebase 
acessa a wallets/{uid}/operações
ordena esses dados por data, de forma decrescente (mais recente primeiro)
retornar a lista de operações 
*/

import { FirestoreBaseRepo } from "../../infra/repositories/firestore.base.repo";
import { getDb } from "../../config/firebase";

export class WalletRepo extends FirestoreBaseRepo {
    constructor() {
        super('wallets');
    }
    // busca o histórico de operações do usuário, ordenado por data 
    async getHistoricoOperacoes (uid: string) {
        const snapshot = await getDb() 
            .collection('wallets');
            .doc(uid);
            .orderBy('data', 'desc');
            .get();

        if (snapshot.empty) return [];

        return snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        }));
    }
}
