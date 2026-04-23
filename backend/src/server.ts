// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import express from 'express';
import cors from 'cors';
import { corsOptions } from './config/cors';
import routes from './modules/index';
import { errorMiddleware } from './shared/errors/error.middleware';
import * as functions from 'firebase-functions';

// Firebase inicializa automaticamente ao importar o config
import './config/firebase';

const app = express();

app.use(cors(corsOptions));
app.use(express.json());
app.use('/api/v1', routes);
app.use(errorMiddleware);

export const api = functions.https.onRequest(app);