import { getAuth, getDb } from '../../config/firebase';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

// _______________   CADASTRO   _______________ // 

export async function cadastroService(
    dataNascimento: string,
    nomeCompleto: string,
    email: string,
    cpf: string,
    telefone: string,
    senha: string
) {
    // criando o usuario
    const userRecord = await getAuth().createUser({
        email: email,
        password: senha,
        displayName: nomeCompleto
    });

    // pegando o ID do usuario
    // adminSDK tem um método (createUser) que recebe os dados do user e retorna o uid
    const uid = userRecord.uid;

    await getDb().collection('users').doc(uid).set({
        uid,
        dataNascimento,
        nomeCompleto,
        email,
        cpf,
        telefone,
        walletId: `wallets/${uid}`,
        //falso porque o user ativa o 2FA após o cadastro no app (de forma opcional).
        mfaEnabled: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        //usado para quando o user modificar alguma informação de perfil (ex: telefone)
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await getDb().collection('wallets').doc(uid).set({
        uid,
        saldo: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { uid }
}

// _______________   LOGIN   _______________ //

export async function loginService(idToken: string) {

    //valida o token recebido no firebase admin sdk
    const decondedToken = await getAuth().verifyIdToken(idToken);

    //pega o UID do token decodificado
    const uid = decondedToken.uid;

    //busca na coleção users o documento com o UID e pega seus dados
    const userDoc = await getDb().collection('users').doc(uid).get();

    //retorna os dados
    return userDoc.data;
}


// _______________   SENHA   _______________ //

// 1. GERA E SALVA O TOKEN
export async function enviarTokenRecuperacaoService(email: string) {
    const user = await getAuth().getUserByEmail(email);

    // Gera token de 6 dígitos
    const token = crypto.randomInt(100000, 999999).toString();

    // Expira em 15 minutos
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Salva no Firestore com contador de tentativas
    await getDb().collection('passwordResetTokens').doc(user.uid).set({
        token,
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

    if (data.used) throw new Error('Este código já foi utilizado.');
    if (data.expiresAt.toDate() < new Date()) throw new Error('Código expirado. Solicite um novo.');
    
    // Bloqueia se errou 5 vezes
    if (data.tentativas >= 5) {
        throw new Error('Muitas tentativas incorretas. Por segurança, solicite um novo código.');
    }

    // Se o token estiver errado, incrementa a tentativa e barra
    if (data.token !== token) {
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

    // Marca token como usado para não ser reaproveitado
    await getDb().collection('passwordResetTokens').doc(uid).update({ used: true });

    return { success: true };
}