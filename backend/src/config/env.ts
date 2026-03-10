import 'dotenv/config';

// Valida presença das variáveis obrigatórias antes de subir o servidor
const required = ['PORT', 'FIREBASE_PROJECT_ID'];
required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Variável de ambiente obrigatória ausente: ${key}`);
  }
});

// Exporta as variáveis tipadas para uso no restante da aplicação
export const env = {
  PORT: process.env.PORT || '3000',
  NODE_ENV: process.env.NODE_ENV || 'development',
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID!,
};