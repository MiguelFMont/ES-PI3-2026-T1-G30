// Autor: Miguel Fernandes Monteiro — RA: 25014808

import * as speakeasy from 'speakeasy';
import * as QRCode from 'qrcode';
import * as crypto from 'crypto';
import { getDb } from '../../../config/firebase';
import { FieldValue } from 'firebase-admin/firestore';
import { encryptToken, decryptToken } from '../auth.service';

// ───── SETUP: gera secret e QR code ─────

export async function setupMfaService(uid: string, email: string) {
  const secret = speakeasy.generateSecret({
    name: `MesclaInvest (${email})`,
    issuer: 'MesclaInvest',
    length: 20,
  });

  // Salva o secret como pendente (criptografado) — só vira definitivo após verificação
  await getDb().collection('users').doc(uid).update({
    mfaSecretPending: encryptToken(secret.base32),
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

  const secretPlain = decryptToken(userData.mfaSecretPending);

  const isValid = speakeasy.totp.verify({
    secret: secretPlain,
    encoding: 'base32',
    token: code,
    window: 1, // tolera 30s de diferença de clock
  });

  if (!isValid) throw new Error('Código inválido. Tente novamente.');

  // Promove o secret de pendente para ativo (mantém criptografado)
  await getDb().collection('users').doc(uid).update({
    mfaEnabled: true,
    mfaSecret: userData.mfaSecretPending,
    mfaSecretPending: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

// ───── DISABLE: desativa MFA e remove secret ─────

export async function disableMfaService(uid: string) {
  const userDoc = await getDb().collection('users').doc(uid).get();
  const userData = userDoc.data();

  if (!userData?.mfaEnabled) {
    throw new Error('MFA já está desativado.');
  }

  await getDb().collection('users').doc(uid).update({
    mfaEnabled: false,
    mfaSecret: FieldValue.delete(),
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
  const mfaSecretPlain = decryptToken(userDoc.data()!.mfaSecret);

  const isValid = speakeasy.totp.verify({
    secret: mfaSecretPlain,
    encoding: 'base32',
    token: code,
    window: 1,
  });

  if (!isValid) throw new Error('Código inválido. Tente novamente.');

  // Descriptografa os tokens que foram guardados durante o login e limpa o documento
  const idToken = decryptToken(data.idToken);
  const refreshToken = decryptToken(data.refreshToken);
  await docRef.delete();

  return { idToken, refreshToken, uid };
}