import * as admin from 'firebase-admin';
import * as serviceAccount from '../../serviceAccountKey.json';

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