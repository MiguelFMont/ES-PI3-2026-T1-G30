import { Request, Response } from "express";
import { Resend } from "resend";
import {
  iniciarCadastroService,
  concluirCadastroService,
  loginService,
  enviarTokenRecuperacaoService,
  novaSenhaService,
  validarTokenService,
  reenviarTokenCadastroService,
} from "./auth.service";
import { sendError, sendSuccess } from "../../shared/utils/response.utils";

function getResendClient() {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new Error("RESEND_API_KEY não configurada");
  }

  return new Resend(apiKey);
}

export async function iniciarCadastroController(req: Request, res: Response) {
  try {
    const { dataNascimento, nomeCompleto, email, cpf, telefone, senha } =
      req.body;

    if (
      !dataNascimento ||
      !nomeCompleto ||
      !email ||
      !cpf ||
      !telefone ||
      !senha
    ) {
      return sendError(res, "Todos os campos são obrigatórios.", 400);
    }

    const { token } = await iniciarCadastroService({
      dataNascimento,
      nomeCompleto,
      email,
      cpf,
      telefone,
      senha,
    });

    console.log("Tentando enviar email para:", email);

    const emailResult = await getResendClient().emails.send({
      from: "MesclaInvest <noreply@mesclainvest.online>",
      to: email,
      subject: "Confirme seu cadastro no MesclaInvest",
      html: `
                <div style="font-family: sans-serif; text-align: center; padding: 20px;">
                    <h2>Bem-vindo ao MesclaInvest!</h2>
                    <p>Use o código abaixo para confirmar seu cadastro:</p>
                    <h1 style="background: #f4f4f4; padding: 15px; letter-spacing: 8px; border-radius: 8px; display: inline-block;">
                        ${token}
                    </h1>
                    <p style="color: #888; font-size: 12px;">Este código expira em 2 minutos.</p>
                </div>
            `,
    });

    console.log("Resultado do Resend:", emailResult);

    return sendSuccess(res, { message: "Código enviado com sucesso!" }, 201);
  } catch (error: any) {
    console.error("Erro ao iniciar cadastro:", error);
    return sendError(res, error.message || "Erro ao iniciar cadastro.", 400);
  }
}

export async function concluirCadastroController(req: Request, res: Response) {
  try {
    const { email, token, senha } = req.body;

    if (!email || !token) {
      return sendError(res, "E-mail e token são obrigatórios.", 400);
    }

    const result = await concluirCadastroService(email, token, senha);

    return sendSuccess(res, result, 201);
  } catch (error: any) {
    console.error("Erro ao concluir cadastro:", error);
    return sendError(res, error.message || "Erro ao concluir cadastro.", 400);
  }
}

export async function loginController(req: Request, res: Response) {
  try {
    const { email, senha } = req.body;

    if (!email || !senha) {
      return sendError(res, "E-mail e senha são obrigatórios.", 400);
    }

    const result = await loginService(email, senha);

    return sendSuccess(res, result, 200);
  } catch (error: any) {
    console.error("Erro no login:", error);
    return sendError(res, "E-mail ou senha incorretos.", 401);
  }
}

export async function solicitarRecuperacaoSenhaController(
  req: Request,
  res: Response,
) {
  try {
    const { email } = req.body;
    if (!email) return sendError(res, "E-mail é obrigatório");

    const { token } = await enviarTokenRecuperacaoService(email);

    await getResendClient().emails.send({
      from: "MesclaInvest <noreply@mesclainvest.online>",
      to: email,
      subject: "Seu código de recuperação de senha",
      html: `
                <div style="font-family: sans-serif; text-align: center; padding: 20px;">
                    <h2>Recuperação de Senha</h2>
                    <p>Você solicitou a redefinição de senha.</p>
                    <p>Use o código abaixo no aplicativo:</p>
                    <h1 style="background: #f4f4f4; padding: 15px; letter-spacing: 8px; border-radius: 8px; display: inline-block;">
                        ${token}
                    </h1>
                    <p style="color: #888; font-size: 12px;">Este código expira em 2 minutos.</p>
                </div>
            `,
    });

    return sendSuccess(res, { message: "código enviado com sucesso!" });
  } catch (error: any) {
    console.error("Erro ao solicitar recuperação:", error);
    if (error.code === "auth/user-not-found") {
      return sendSuccess(res, {
        message: "Se o e-mail existir, o código foi enviado.",
      });
    }
    return sendError(res, error.message || "Erro interno do servidor.");
  }
}

// _______________   REDEFINIR SENHA   _______________ //

export async function redefinirSenhaController(req: Request, res: Response) {
  try {
    const { email, token, novaSenha } = req.body;

    if (!email || !token || !novaSenha) {
      return sendError(res, "E-mail, token e nova senha são obrigatórios.");
    }

    await novaSenhaService(email, token, novaSenha);

    return sendSuccess(res, { message: "Senha alterada com sucesso!" });
  } catch (error: any) {
    const mensagemErro = error.message || "Erro ao redefinir senha.";
    return sendError(res, mensagemErro);
  }
}

export async function validarTokenController(req: Request, res: Response) {
  try {
    const { email, token } = req.body;

    if (!email || !token) {
      return sendError(res, "E-mail e token são obrigatórios.", 400);
    }

    await validarTokenService(email, token);

    return sendSuccess(res, { message: "Código validado com sucesso!" }, 200);
  } catch (error: any) {
    return sendError(res, error.message || "Erro ao validar código.", 400);
  }
}

export async function reenviarTokenCadastroController(
  req: Request,
  res: Response,
) {
  try {
    const { email } = req.body;

    if (!email) return sendError(res, "E-mail é obrigatório.", 400);

    const { token } = await reenviarTokenCadastroService(email);

    await getResendClient().emails.send({
      from: "MesclaInvest <noreply@mesclainvest.online>",
      to: email,
      subject: "Novo código de confirmação - MesclaInvest",
      html: `
                <div style="font-family: sans-serif; text-align: center; padding: 20px;">
                    <h2>Novo código de confirmação</h2>
                    <p>Use o código abaixo para confirmar seu cadastro:</p>
                    <h1 style="background: #f4f4f4; padding: 15px; letter-spacing: 8px; border-radius: 8px; display: inline-block;">
                        ${token}
                    </h1>
                    <p style="color: #888; font-size: 12px;">Este código expira em 2 minutos.</p>
                </div>
            `,
    });

    return sendSuccess(res, { message: "Novo código enviado!" }, 200);
  } catch (error: any) {
    console.error("Erro ao reenviar token:", error);
    return sendError(res, error.message || "Erro ao reenviar código.", 400);
  }
}
