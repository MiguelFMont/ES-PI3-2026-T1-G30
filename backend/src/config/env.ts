import 'dotenv/config';

// Valida presença das variáveis obrigatórias antes de subir o servidor
const required = ['APP_PROJECT_ID'];
required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Variável de ambiente obrigatória ausente: ${key}`);
  }
});

// Exporta as variáveis tipadas para uso no restante da aplicação
export const env = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  projectId: process.env.APP_PROJECT_ID!,
  resendApi: process.env.RESEND_API_KEY,
  firebaseApiKey: process.env.APP_API_KEY,
};