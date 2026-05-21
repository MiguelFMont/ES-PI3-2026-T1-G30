// Autor: Miguel Fernandes Monteiro — RA: 25014808

import * as speakeasy from 'speakeasy';
import * as QRCode from 'qrcode';
import * as crypto from 'crypto';
import { getDb } from '../../../config/firebase';
import { FieldValue } from 'firebase-admin/firestore';

// ───── SETUP: gera secret e QR code ─────

export async function setupMfaService(uid: string, email: string) {
  const secret = speakeasy.generateSecret({
    name: `MesclaInvest (${email})`,
    issuer: 'MesclaInvest',
    length: 20,
  });

  // Salva o secret como pendente — só vira definitivo após verificação
  await getDb().collection('users').doc(uid).update({
    mfaSecretPending: secret.base32,
  });

  const qrCodeDataUrl = await QRCode.toDataURL(secret.otpauth_url!);

  return {
    qrCodeDataUrl, // base64 PNG para exibir no Flutter
    secret: secret.base32, // entrada manual para quem não consegue escanear
  };
}

// ───── VERIFY: valida código e ativa MFA ─────

export async function verifyAndActivateMfaService(uid: string, code: string) {
  const userDoc = await getDb().collection('users').doc(uid).get();
  const userData = userDoc.data();

  if (!userData?.mfaSecretPending) {
    throw new Error('Nenhuma configuração de MFA pendente. Reinicie o processo.');
  }

  const isValid = speakeasy.totp.verify({
    secret: userData.mfaSecretPending,
    encoding: 'base32',
    token: code,
    window: 1, // tolera 30s de diferença de clock
  });

  if (!isValid) throw new Error('Código inválido. Tente novamente.');

  // Promove o secret de pendente para ativo
  await getDb().collection('users').doc(uid).update({
    mfaEnabled: true,
    mfaSecret: userData.mfaSecretPending,
    mfaSecretPending: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

// ───── CHALLENGE: valida MFA no login ─────

export async function mfaChallengeService(uid: string, tempToken: string, code: string) {
  const docRef = getDb().collection('mfaChallengePending').doc(uid);
  const doc = await docRef.get();

  if (!doc.exists) throw new Error('Sessão de MFA inválida ou expirada. Faça login novamente.');

  const data = doc.data()!;

  if (data.expiresAt.toDate() < new Date()) {
    await docRef.delete();
    throw new Error('Sessão expirada. Faça login novamente.');
  }

  const tokenHash = crypto.createHash('sha256').update(tempToken).digest('hex');
  if (data.tokenHash !== tokenHash) throw new Error('Token inválido.');

  const userDoc = await getDb().collection('users').doc(uid).get();
  const { mfaSecret } = userDoc.data()!;

  const isValid = speakeasy.totp.verify({
    secret: mfaSecret,
    encoding: 'base32',
    token: code,
    window: 1,
  });

  if (!isValid) throw new Error('Código inválido. Tente novamente.');

  // Recupera o idToken que foi guardado durante o login e limpa o documento
  const { idToken, refreshToken } = data;
  await docRef.delete();

  return { idToken, refreshToken, uid };
}