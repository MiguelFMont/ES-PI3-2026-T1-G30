import { getAuth, getDb } from "../../config/firebase";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as crypto from "crypto";
import axios from "axios";
import { env } from "../../config/env";

// _______________   CRIPTOGRAFIA AES-256-GCM   _______________ //

function getEncryptionKey(): Buffer {
  // Lido em runtime para funcionar com Firebase Secrets (injetado em process.env)
  const key = process.env.TOKEN_ENCRYPTION_KEY;
  if (!key) throw new Error("TOKEN_ENCRYPTION_KEY não configurada.");
  return crypto.createHash("sha256").update(key).digest();
}

export function encryptToken(plaintext: string): string {
  const key = getEncryptionKey();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return [iv.toString("hex"), encrypted.toString("hex"), tag.toString("hex")].join(":");
}

export function decryptToken(ciphertext: string): string {
  const key = getEncryptionKey();
  const [ivHex, encHex, tagHex] = ciphertext.split(":");
  const decipher = crypto.createDecipheriv("aes-256-gcm", key, Buffer.from(ivHex, "hex"));
  decipher.setAuthTag(Buffer.from(tagHex, "hex"));
  return decipher.update(Buffer.from(encHex, "hex")) + decipher.final("utf8");
}

// _______________   VALIDAÇÃO DE SENHA   _______________ //

// Regras espelhadas no frontend (cadastro_page / reset_password_page):
// mínimo 8 caracteres, letra maiúscula, número e caractere especial.
export function validarSenhaForte(senha: string) {
  if (!senha || senha.length < 8)
    throw new Error("A senha deve ter no mínimo 8 caracteres.");
  if (!/[A-Z]/.test(senha))
    throw new Error("A senha deve conter ao menos uma letra maiúscula.");
  if (!/[0-9]/.test(senha))
    throw new Error("A senha deve conter ao menos um número.");
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(senha))
    throw new Error("A senha deve conter ao menos um caractere especial.");
}

// _______________   VERIFICAÇÃO DE CPF   _______________ //

// Verifica se o CPF já está cadastrado em algum usuário.
export async function verificarCpfDisponivelService(cpf: string) {
  const snap = await getDb()
    .collection("users")
    .where("cpf", "==", cpf)
    .limit(1)
    .get();

  return { disponivel: snap.empty };
}

// _______________   CADASTRO EM 2 ETAPAS   _______________ //

// 1. INICIA O CADASTRO — salva dados temporários e envia token por email
export async function iniciarCadastroService(dados: {
  dataNascimento: string;
  nomeCompleto: string;
  email: string;
  cpf: string;
  telefone: string;
  senha: string;
}) {
  // Valida a força da senha antes de qualquer escrita/envio de email
  validarSenhaForte(dados.senha);

  // E-mail não pode estar cadastrado no Firebase Auth
  let emailEmUso = false;
  try {
    await getAuth().getUserByEmail(dados.email);
    emailEmUso = true;
  } catch (e: any) {
    if (e.code !== "auth/user-not-found") throw e;
  }
  if (emailEmUso) throw new Error("E-mail já cadastrado.");

  // CPF não pode estar cadastrado em outro usuário
  const cpfSnap = await getDb()
    .collection("users")
    .where("cpf", "==", dados.cpf)
    .limit(1)
    .get();
  if (!cpfSnap.empty) throw new Error("CPF já cadastrado.");

  const token = crypto.randomInt(10000, 99999).toString();
  const expiresAt = new Date(Date.now() + 2 * 60 * 1000);
  const tokenHash = crypto.createHash("sha256").update(token).digest("hex");

  // Remove a senha do objeto usando desestruturação
  const { senha, ...dadosParaSalvar } = dados;

  // Salva dados temporários no Firestore (ainda não cria o usuário)
  await getDb()
    .collection("pendingUsers")
    .doc(dados.email)
    .set({
      ...dadosParaSalvar,
      token: tokenHash,
      expiresAt: Timestamp.fromDate(expiresAt),
      used: false,
    });

  return { token };
}

// 2. CONCLUI O CADASTRO — valida token e cria o usuário
export async function concluirCadastroService(
  email: string,
  token: string,
  senha: string,
) {
  const docRef = getDb().collection("pendingUsers").doc(email);
  const doc = await docRef.get();

  if (!doc.exists) throw new Error("Nenhum cadastro pendente encontrado.");

  const dados = doc.data()!;

  const inputHash = crypto.createHash("sha256").update(token).digest("hex");

  if (dados.used) throw new Error("Este código já foi utilizado.");
  if (dados.expiresAt.toDate() < new Date())
    throw new Error("Código expirado. Solicite um novo cadastro.");
  if (dados.token !== inputHash) throw new Error("Código inválido.");

  validarSenhaForte(senha);

  // Cria o usuário no Firebase Auth
  const userRecord = await getAuth().createUser({
    email: dados.email,
    password: senha,
    displayName: dados.nomeCompleto,
  });

  const uid = userRecord.uid;

  // Salva no Firestore
  await getDb()
    .collection("users")
    .doc(uid)
    .set({
      uid,
      dataNascimento: dados.dataNascimento,
      nomeCompleto: dados.nomeCompleto,
      email: dados.email,
      cpf: dados.cpf,
      telefone: dados.telefone,
      walletId: `wallets/${uid}`,
      mfaEnabled: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

  await getDb().collection("wallets").doc(uid).set({
    uid,
    saldoCentavos: 0,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Marca como usado e remove o pendente
  await docRef.delete();

  return { uid };
}

// _______________   LOGIN   _______________ //

export async function loginService(email: string, senha: string) {
  const firebaseResponse = await axios.post(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${env.firebaseApiKey}`,
    { email, password: senha, returnSecureToken: true },
  );

  const { idToken, localId: uid, refreshToken } = firebaseResponse.data;

  const userDoc = await getDb().collection('users').doc(uid).get();
  const userData = userDoc.data();

  // Se MFA estiver ativo, guarda o idToken temporariamente e retorna tempToken
  if (userData?.mfaEnabled) {
    const tempToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(tempToken).digest('hex');

    await getDb().collection('mfaChallengePending').doc(uid).set({
      tokenHash,
      idToken: encryptToken(idToken),
      refreshToken: encryptToken(refreshToken),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 5 * 60 * 1000)), // 5 min
      deleteAt: Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000)), // TTL: 1h
    });

    return { mfaRequired: true, tempToken, uid };
  }

  // Sem MFA: fluxo normal
  return {
    mfaRequired: false,
    idToken,
    refreshToken,
    uid,
    ...userData,
  };
}

// _______________   SENHA   _______________ //

// 1. GERA E SALVA O TOKEN
export async function enviarTokenRecuperacaoService(email: string) {
  const user = await getAuth().getUserByEmail(email);

  // Gera token de 5 dígitos
  const token = crypto.randomInt(10000, 99999).toString();

  // Expira em 2 minutos
  const expiresAt = new Date(Date.now() + 2 * 60 * 1000);

  const tokenHash = crypto.createHash("sha256").update(token).digest("hex");

  // Salva no Firestore com contador de tentativas
  await getDb()
    .collection("passwordResetTokens")
    .doc(user.uid)
    .set({
      token: tokenHash,
      expiresAt: Timestamp.fromDate(expiresAt),
      used: false,
      tentativas: 0,
    });

  return { token, uid: user.uid };
}

// 2. VALIDA O TOKEN (Com trava de segurança)
export async function validarTokenService(email: string, token: string) {
  const user = await getAuth().getUserByEmail(email);
  const docRef = getDb().collection("passwordResetTokens").doc(user.uid);
  const doc = await docRef.get();

  if (!doc.exists)
    throw new Error("Nenhum código ativo encontrado para este usuário.");

  const data = doc.data()!;

  const inputHash = crypto.createHash("sha256").update(token).digest("hex");

  if (data.used) throw new Error("Este código já foi utilizado.");
  if (data.expiresAt.toDate() < new Date())
    throw new Error("Código expirado. Solicite um novo.");

  // Bloqueia se errou 5 vezes
  if (data.tentativas >= 5) {
    throw new Error(
      "Muitas tentativas incorretas. Por segurança, solicite um novo código.",
    );
  }

  // Se o token estiver errado, incrementa a tentativa e barra
  if (data.token !== inputHash) {
    await docRef.update({
      tentativas: FieldValue.increment(1),
    });
    throw new Error("Código inválido.");
  }

  return { uid: user.uid, valid: true };
}

// 3. EFETIVA A TROCA DE SENHA
export async function novaSenhaService(
  email: string,
  token: string,
  novaSenha: string,
) {
  validarSenhaForte(novaSenha);

  // Valida o token novamente por segurança antes de alterar
  const { uid } = await validarTokenService(email, token);

  // Altera a senha no Firebase Auth
  await getAuth().updateUser(uid, { password: novaSenha });

  // Documento da coleção é deletado para não ocupar espaço desnecessário no banco como é feito na validação de email
  await getDb().collection("passwordResetTokens").doc(uid).delete();

  return { success: true };
}

export async function reenviarTokenCadastroService(email: string) {
  const docRef = getDb().collection("pendingUsers").doc(email);
  const doc = await docRef.get();

  if (!doc.exists)
    throw new Error("Nenhum cadastro pendente encontrado para este e-mail.");

  const token = crypto.randomInt(10000, 99999).toString();
  const expiresAt = new Date(Date.now() + 2 * 60 * 1000);

  const tokenHash = crypto.createHash("sha256").update(token).digest("hex");

  await docRef.update({
    token: tokenHash,
    expiresAt: Timestamp.fromDate(expiresAt),
    used: false,
  });

  return { token, email };
}

// _______________   LOGOUT   _______________ //

export async function logoutService(uid: string) {
    // Revoga todos os refresh tokens do usuário no Firebase Auth
    await getAuth().revokeRefreshTokens(uid);
    return { success: true };
}

