// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { Request, Response } from 'express';
import { getAuth } from 'firebase-admin/auth';
import { UsersService } from './users.service';
import { sendError, sendSuccess } from '../../shared/utils/response.utils';


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

export async function updateMe(req: Request, res: Response) {
  try {
    const authHeader = req.headers.authorization ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ erro: 'Token ausente' });
    }

    const idToken = authHeader.slice(7);
    const decoded = await getAuth().verifyIdToken(idToken);

    await service.updatePerfil(decoded.uid, req.body);
    return res.status(204).send();
  } catch (e: any) {
    if (e.code?.startsWith('auth/')) {
      return res.status(401).json({ erro: 'Token inválido ou expirado' });
    }
    return res.status(500).json({ erro: e.message });
  }
}

export async function alterarSenhaController(req: Request, res: Response) {
  try {
    const uid = req.user!.uid;
    const { senhaAtual, novaSenha } = req.body;

    if (!senhaAtual || !novaSenha) {
      return sendError(res, 'Senha atual e nova senha são obrigatórias.', 400);
    }
    if (novaSenha.length < 8) {
      return sendError(res, 'A nova senha deve ter pelo menos 8 caracteres.', 400);
    }

    await service.alterarSenha(uid, senhaAtual, novaSenha);
    return sendSuccess(res, { message: 'Senha alterada com sucesso!' }, 200);
  } catch (error: any) {
    return sendError(res, error.message || 'Erro ao alterar senha.', 400);
  }
}