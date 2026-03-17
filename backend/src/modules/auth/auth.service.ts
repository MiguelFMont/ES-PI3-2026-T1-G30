import { getAuth, getDb } from '../../config/firebase';
import * as admin from 'firebase-admin';

// _______________   CADASTRO   _______________ // 

export async function cadastroService(
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

export async function recoverPasswordService(email: string){

    // gera o link para redefinir a senha (o proprio firebase ja tem essa função)
    const link = await getAuth().generatePasswordResetLink(email);

    return { link }
}
