/*
Esse arquivo diz pro TypeScript: "o objeto Request do Express também pode ter uma propriedade user do tipo DecodedIdToken".
Depois disso o erro some e o req.user fica tipado corretamente em todos os controllers.
*/
import { DecodedIdToken } from 'firebase-admin/auth';

// Estende a interface Request do Express adicionando a propriedade user
declare global {
  namespace Express {
    interface Request {
      user?: DecodedIdToken;
    }
  }
}