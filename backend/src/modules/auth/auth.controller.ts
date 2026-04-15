import { Request, Response } from 'express';
import { Resend } from 'resend';
import {
    cadastroService,
    loginService,
    enviarTokenRecuperacaoService,
    novaSenhaService
} from './auth.service';
import { env } from '../../config/env';
import { sendError, sendSuccess } from '../../shared/utils/response.utils';
import { json } from 'zod';


const resend = new Resend(env.resendApi);

export async function cadastroController(req: Request, res: Response) {
    try {
        const { dataNascimento, nomeCompleto, email, cpf, telefone, senha } = req.body;

        const result = await cadastroService(dataNascimento, nomeCompleto, email, cpf, telefone, senha);

        return sendSuccess(res, result, 200);

    } catch (error: any) {
        console.error('Erro no cadastro:', error);
        
        return sendError(res , error.message || 'Erro ao realizar cadastro', 400)
    }
}

export async function loginController(req: Request, res: Response) {
    try {
        const { idToken } = req.body;
        
        if (!idToken) return sendError(res, 'Token não fornecido.', 400);

        const result = await loginService(idToken);

        return sendSuccess(res, result, 200);

    } catch (error: any) {
        console.error('Erro no login:', error);
        return sendError(res, 'Falha na autenticação.', 401);
    }
}

export async function solicitarRecuperacaoSenha(req: Request, res: Response) {
    try {
        const { email } = req.body;
        if (!email) return sendError(res, 'E-mail é obrigatório')

        // Gera o token no Firestore
        const { token } = await enviarTokenRecuperacaoService(email);

        // Dispara o e-mail
        await resend.emails.send({
            from: 'App PI_III <suporte@seudominio.com.br>', 
            to: email,
            subject: 'Seu código de recuperação de senha',
            html: `
                <div style="font-family: sans-serif; text-align: center; padding: 20px;">
                    <h2>Recuperação de Senha</h2>
                    <p>Você solicitou a redefinição de senha.</p>
                    <p>Use o código abaixo no aplicativo:</p>
                    <h1 style="background: #f4f4f4; padding: 15px; letter-spacing: 8px; border-radius: 8px; display: inline-block;">
                        ${token}
                    </h1>
                    <p style="color: #888; font-size: 12px;">Este código expira em 15 minutos.</p>
                </div>
            `,
        });

        return sendSuccess(res, json({message:'código enviado com sucesso!'}));

    } catch (error: any) {
        console.error('Erro ao solicitar recuperação:', error);
        if (error.code === 'auth/user-not-found') {
        
            // Segurança: Não avisar que o e-mail não existe
            return sendSuccess(res, json({ message: 'Se o e-mail existir, o código foi enviado.'}));
        }
        return sendError(res, error.message || 'Erro interno do servidor.');
    }
}

// _______________   REDEFINIR SENHA   _______________ //

export async function redefinirSenha(req: Request, res: Response) {
    try {
        const { email, token, novaSenha } = req.body;

        if (!email || !token || !novaSenha) {
            return sendError(res, 'E-mail, token e nova senha são obrigatórios.' );
        }

        // Tenta trocar a senha (a validação do token já acontece lá dentro)
        await novaSenhaService(email, token, novaSenha);

        return sendSuccess(res, json({ message: 'Senha alterada com sucesso!' }));

    } catch (error: any) {
        // Retornamos status 400 para erros da nossa regra de negócio (ex: token inválido)
        const mensagemErro = error.message || 'Erro ao redefinir senha.';
       return sendError(res, mensagemErro);
    }
}