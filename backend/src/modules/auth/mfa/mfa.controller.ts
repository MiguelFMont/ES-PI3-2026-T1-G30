// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { Request, Response } from 'express';
import { getDb } from '../../../config/firebase';
import { setupMfaService, verifyAndActivateMfaService, mfaChallengeService, disableMfaService } from './mfa.service';
import { sendError, sendSuccess } from '../../../shared/utils/response.utils';

export async function setupMfaController(req: Request, res: Response) {
  try {
    const uid = req.user!.uid;

    const userDoc = await getDb().collection('users').doc(uid).get();
    const { email } = userDoc.data()!;

    const result = await setupMfaService(uid, email);
    return sendSuccess(res, result, 200);
  } catch (error: any) {
    console.error('Erro no setup do MFA:', error);
    return sendError(res, error.message || 'Erro ao configurar MFA.', 500);
  }
}

export async function verifyMfaController(req: Request, res: Response) {
  try {
    const uid = req.user!.uid;
    const { code } = req.body;

    if (!code) return sendError(res, 'Código é obrigatório.', 400);

    await verifyAndActivateMfaService(uid, code);
    return sendSuccess(res, { message: 'MFA ativado com sucesso!' }, 200);
  } catch (error: any) {
    console.error('Erro na verificação do MFA:', error);
    return sendError(res, error.message || 'Erro ao verificar código.', 400);
  }
}

export async function disableMfaController(req: Request, res: Response) {
  try {
    const uid = req.user!.uid;
    await disableMfaService(uid);
    return sendSuccess(res, { message: 'MFA desativado com sucesso.' }, 200);
  } catch (error: any) {
    console.error('Erro ao desativar MFA:', error);
    return sendError(res, error.message || 'Erro ao desativar MFA.', 400);
  }
}

export async function mfaChallengeController(req: Request, res: Response) {
  try {
    const { uid, tempToken, code } = req.body;

    if (!uid || !tempToken || !code) {
      return sendError(res, 'uid, tempToken e code são obrigatórios.', 400);
    }

    const result = await mfaChallengeService(uid, tempToken, code);
    return sendSuccess(res, result, 200);
  } catch (error: any) {
    console.error('Erro no challenge do MFA:', error);
    return sendError(res, error.message || 'Erro ao validar MFA.', 401);
  }
}