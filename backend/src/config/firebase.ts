// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

export const getDb = () => admin.firestore();
export const getAuth = () => admin.auth();