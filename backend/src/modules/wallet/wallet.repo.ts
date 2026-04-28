/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:
ele vai herdar a classe base do repositório do firestore 
acessa a wallets/{uid}/operações
ordena esses dados por data, de forma decrescente (mais recente primeiro)
retornar a lista de operações 

acessar a wallet 
pegar os dados sa subcoleção dos tokens e das operações 
trasnformar esses documentos em objetos
retornar as coleções de objetos como informações pro dashboard e para os gráficos de valorização 
*/

import * as admin from 'firebase-admin';
import { FirestoreBaseRepo } from "../../infra/repositories/firestore.base.repo";
// função que retorna a instancia do firestore 
// ela permite acessar o banco de dados 
import { getDb } from "../../config/firebase";

// função que herda o que o firebaserepo tem 
export class WalletRepo extends FirestoreBaseRepo {
    constructor() {
        // chama o construtor da classe pai (firestorebaserepo)
        super('wallets');
    }
    // busca o histórico de operações do usuário, ordenado por data 
    async getHistoricoOperacoes (uid: string) {
        const db = getDb(); // retorna a instancia do firestore

        const operacoesSnapshot = await db 
            .collection('wallets') // acessa a coleção wallets 
            .doc(uid)
            .collection('operacoes')// acessa o documento do usuário 
            .orderBy('data', 'desc') // ordena os resultados por data (mais recente pro mais antigo)
            .get(); // executa e retorna os resultados 
        // verifica se teve retono do resultado
        if (operacoesSnapshot.empty) return [];
        // retorna a lista de documentos encontrados (array)
        // .map transforma cada documento em um objeto simples
        // doc.id é o id do documento do firestore 
        // doc.data espalha todos os campos do documento 
        return operacoesSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => ({
        id: doc.id,
        ...doc.data(),
        }));
    }


    // busca os dados agregados da wallet para o dashboard 
    async getDadosDashboard(uid:string) {
        const db = getDb();
        // busca o documento principal da wallet
        const walletDoc = await db
            .collection('wallets')
            .doc(uid)
            .get();
        // verifica se o usuário tem wallet cadastrada (documento no firestore)
        if (!walletDoc.exists) return null;

        // busca todos os tokens do usuário
        const tokensSnapshot = await db
            .collection('wallets')
            .doc(uid)
            .collection('tokens')
            .get();
        // busca todas as operações do usuário
        const operacoesSnapshot = await db
            .collection('wallets')
            .doc(uid)
            .collection('operacoes')
            .orderBy('data', 'asc')
            .get();
        // retorna os campos do documento wallet 
        const wallet = walletDoc.data();
        // obejtos tokens 
        const tokens =tokensSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => ({
            id: doc.id,
            ...doc.data(),
        }));
        // objetos operações 
        const operacoes = operacoesSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => ({
            id: doc.id, 
            ...doc.data(),
        }));
        // retorna os conjuntos de objetos em um único objeto 
        return { wallet, tokens, operacoes };
    }
}