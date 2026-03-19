// Framework HTTP
import express from 'express';
// Middlewares globais
import cors from 'cors';
// Configurações
import { initializeFirebase } from './config/firebase';
import { env } from './config/env';
import { corsOptions } from './config/cors';
// Rotas
import routes from './modules/index';
// Middlewares compartilhados
import { errorMiddleware } from './shared/errors/error.middleware';

// Inicializa o Firebase antes de qualquer coisa
initializeFirebase();

const app = express();

// Middlewares globais
app.use(cors(corsOptions));
app.use(express.json()); // interpreta o body das requisições como JSON

// Rotas
app.use('/api/v1', routes);

// Erro — deve ser o último middleware registrado
app.use(errorMiddleware);

// Sobe o servidor
app.listen(env.PORT, () => {
  console.log(`Servidor rodando na porta ${env.PORT}`);
});