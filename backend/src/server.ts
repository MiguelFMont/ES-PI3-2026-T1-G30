// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import express from 'express';
import cors from 'cors';
import { corsOptions } from './config/cors';
import routes from './modules/index';
import { errorMiddleware } from './shared/errors/error.middleware';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

import './config/firebase';

const RESEND_API_KEY = defineSecret('RESEND_API_KEY');

const app = express();

app.use(cors(corsOptions));
app.use(express.json());
app.use('/v1', routes);
app.use(errorMiddleware);

export const api = onRequest(
    {
        secrets: [RESEND_API_KEY],
        region: 'southamerica-east1',
    },
    app
);