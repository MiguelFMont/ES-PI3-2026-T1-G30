
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { Request, Response } from 'express';
import { getAuth } from 'firebase-admin/auth';
import { UsersService } from './users.service';

const service = new UsersService();

export async function getMe(req: Request, res: Response) {
  try {
    const authHeader = req.headers.authorization ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ erro: 'Token ausente' });
    }

    const idToken = authHeader.slice(7);
    const decoded = await getAuth().verifyIdToken(idToken);

    const perfil = await service.getPerfil(decoded.uid);
    return res.status(200).json(perfil);
  } catch (e: any) {
    if (e.code?.startsWith('auth/')) {
      return res.status(401).json({ erro: 'Token inválido ou expirado' });
    }
    return res.status(500).json({ erro: e.message });
  }
}