import { getAuth, getDb } from '../../config/firebase';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import axios from 'axios';
import { env } from '../../config/env';


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
    const token = crypto.randomInt(10000, 99999).toString();
    const expiresAt = new Date(Date.now() + 2 * 60 * 1000);

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // Salva dados temporários no Firestore (ainda não cria o usuário)
    await getDb().collection('pendingUsers').doc(dados.email).set({
        ...dados,
        token: tokenHash,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        used: false,
    });

    return { token };
}

// 2. CONCLUI O CADASTRO — valida token e cria o usuário
export async function concluirCadastroService(email: string, token: string) {
    const docRef = getDb().collection('pendingUsers').doc(email);
    const doc = await docRef.get();

    if (!doc.exists) throw new Error('Nenhum cadastro pendente encontrado.');

    const dados = doc.data()!;

    const inputHash = crypto.createHash('sha256').update(token).digest('hex');

    if (dados.used) throw new Error('Este código já foi utilizado.');
    if (dados.expiresAt.toDate() < new Date()) throw new Error('Código expirado. Solicite um novo cadastro.');
    if (dados.token !== inputHash) throw new Error('Código inválido.');

    // Cria o usuário no Firebase Auth
    const userRecord = await getAuth().createUser({
        email: dados.email,
        password: dados.senha,
        displayName: dados.nomeCompleto,
    });

    const uid = userRecord.uid;

    // Salva no Firestore
    await getDb().collection('users').doc(uid).set({
        uid,
        dataNascimento: dados.dataNascimento,
        nomeCompleto: dados.nomeCompleto,
        email: dados.email,
        cpf: dados.cpf,
        telefone: dados.telefone,
        walletId: `wallets/${uid}`,
        mfaEnabled: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await getDb().collection('wallets').doc(uid).set({
        uid,
        saldo: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Marca como usado e remove o pendente
    await docRef.delete();

    return { uid };
}

// _______________   LOGIN   _______________ //

export async function loginService(email: string, senha: string) {
    const firebaseResponse = await axios.post(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${env.firebaseApiKey}`,
        {
            email,
            password: senha,
            returnSecureToken: true,
        }
    );

    const { idToken, localId: uid } = firebaseResponse.data;

    const userDoc = await getDb().collection('users').doc(uid).get();
    const userData = userDoc.data();

    // retorna tudo na raiz
    return {
        idToken,
        refreshToken: firebaseResponse.data.refreshToken,
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

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // Salva no Firestore com contador de tentativas
    await getDb().collection('passwordResetTokens').doc(user.uid).set({
        token: tokenHash,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        used: false,
        tentativas: 0,
    });

    return { token, uid: user.uid };
}

// 2. VALIDA O TOKEN (Com trava de segurança)
export async function validarTokenService(email: string, token: string) {
    const user = await getAuth().getUserByEmail(email);
    const docRef = getDb().collection('passwordResetTokens').doc(user.uid);
    const doc = await docRef.get();

    if (!doc.exists) throw new Error('Nenhum código ativo encontrado para este usuário.');

    const data = doc.data()!;

    const inputHash = crypto.createHash('sha256').update(token).digest('hex');

    if (data.used) throw new Error('Este código já foi utilizado.');
    if (data.expiresAt.toDate() < new Date()) throw new Error('Código expirado. Solicite um novo.');

    // Bloqueia se errou 5 vezes
    if (data.tentativas >= 5) {
        throw new Error('Muitas tentativas incorretas. Por segurança, solicite um novo código.');
    }

    // Se o token estiver errado, incrementa a tentativa e barra
    if (data.token !== inputHash) {
        await docRef.update({
            tentativas: admin.firestore.FieldValue.increment(1)
        });
        throw new Error('Código inválido.');
    }

    return { uid: user.uid, valid: true };
}

// 3. EFETIVA A TROCA DE SENHA
export async function novaSenhaService(email: string, token: string, novaSenha: string) {
    // Valida o token novamente por segurança antes de alterar
    const { uid } = await validarTokenService(email, token);

    // Altera a senha no Firebase Auth
    await getAuth().updateUser(uid, { password: novaSenha });

    // Documento da coleção é deletado para não ocupar espaço desnecessário no banco como é feito na validação de email
    await getDb().collection('passwordResetTokens').doc(uid).delete();

    return { success: true };
}

export async function reenviarTokenCadastroService(email: string) {
    const docRef = getDb().collection('pendingUsers').doc(email);
    const doc = await docRef.get();

    if (!doc.exists) throw new Error('Nenhum cadastro pendente encontrado para este e-mail.');

    const token = crypto.randomInt(10000, 99999).toString();
    const expiresAt = new Date(Date.now() + 2 * 60 * 1000);

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    await docRef.update({
        token: tokenHash,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        used: false,
    });

    return { token, email };
}

