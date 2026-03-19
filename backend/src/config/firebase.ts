import * as admin from 'firebase-admin';

// Alterei import * as serviceAccount from '../../serviceAccountKey.json'
// O TypeScript trata imports de JSON como objetos somente leitura (módulo congelado).
// O Firebase Admin SDK precisa modificar as propriedades da credencial internamente,
// o que causa o erro: "Cannot set property project_id of #<Object> which has only a getter".
// Solução: usar require().

const serviceAccount = require('../../serviceAccountKey.json');

export function initializeFirebase(): void {
  admin.initializeApp({
    credential: admin.credential.cert(
      serviceAccount as admin.ServiceAccount
    ),
  });
}

// Funções que retornam as instâncias após a inicialização
export const getDb = () => admin.firestore();
export const getAuth = () => admin.auth();