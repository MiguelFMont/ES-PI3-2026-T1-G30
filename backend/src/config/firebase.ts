// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

if (!admin.apps.length) {
  const serviceAccountPath =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ??
    path.resolve(__dirname, '../../serviceAccountKey.json');

  if (
    process.env.NODE_ENV !== 'production' &&
    fs.existsSync(serviceAccountPath)
  ) {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
    });
  } else {
    admin.initializeApp();
  }
}

export const getDb = () => admin.firestore();
export const getAuth = () => admin.auth();
