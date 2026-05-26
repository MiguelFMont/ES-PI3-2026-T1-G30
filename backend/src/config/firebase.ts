// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'dotenv/config';
import * as admin from 'firebase-admin';
import { existsSync } from 'fs';
import path from 'path';

if (!admin.apps.length) {
  const appOptions: admin.AppOptions = {};
  const configuredCredentialPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localCredentialPath = path.resolve(
    process.cwd(),
    configuredCredentialPath || 'serviceAccountKey.json',
  );

  if (process.env.APP_PROJECT_ID) {
    appOptions.projectId = process.env.APP_PROJECT_ID;
  }

  if (!process.env.FIRESTORE_EMULATOR_HOST && existsSync(localCredentialPath)) {
    appOptions.credential = admin.credential.cert(localCredentialPath);
  }

  admin.initializeApp(appOptions);
}

export const getDb = () => admin.firestore();
export const getAuth = () => admin.auth();
