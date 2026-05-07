// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'dotenv/config';
import * as admin from 'firebase-admin';

const projectId =
  process.env.GCLOUD_PROJECT ??
  process.env.GOOGLE_CLOUD_PROJECT ??
  process.env.APP_PROJECT_ID;

if (projectId) {
  process.env.GCLOUD_PROJECT ??= projectId;
  process.env.GOOGLE_CLOUD_PROJECT ??= projectId;
}

if (!admin.apps.length) {
  if (projectId) {
    admin.initializeApp({ projectId });
  } else {
    admin.initializeApp();
  }
}

export const getDb = () => admin.firestore();
export const getAuth = () => admin.auth();
