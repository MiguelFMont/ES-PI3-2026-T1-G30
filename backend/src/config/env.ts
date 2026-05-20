import 'dotenv/config';

const required = ['APP_PROJECT_ID'];

required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Variavel de ambiente obrigatoria ausente: ${key}`);
  }
});

const firebaseApiKey = process.env.APP_API_KEY ?? process.env.FIREBASE_API_KEY;

if (!firebaseApiKey) {
  throw new Error(
    'Variavel de ambiente obrigatoria ausente: APP_API_KEY ou FIREBASE_API_KEY',
  );
}

export const env = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  projectId: process.env.APP_PROJECT_ID!,
  firebaseApiKey,
};
