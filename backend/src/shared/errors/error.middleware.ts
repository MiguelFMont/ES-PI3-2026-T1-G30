// Importa os tipos do Express para tipar os parâmetros da função
// Request      → representa a requisição recebida
// Response     → representa a resposta que será enviada
// NextFunction → função que passa o controle para o próximo middleware
import { Request, Response, NextFunction } from "express";
import { isAppError } from "./app.error";

// Define um código padrão quando um AppError não informa code explicitamente.
// É usada apenas neste middleware central de tratamento de erros.
function getDefaultErrorCode(statusCode: number): string {
  if (statusCode === 401) {
    return "UNAUTHENTICATED";
  }

  if (statusCode >= 400 && statusCode < 500) {
    return "BAD_REQUEST";
  }

  return "INTERNAL_ERROR";
}

// Exporta a função como middleware de erro
// O Express identifica um middleware de erro pelos 4 parâmetros — não pode remover nenhum
export function errorMiddleware(
  // O erro que foi lançado em alguma rota ou service
  error: Error,

  // _ no início indica que o parâmetro é intencionalmente ignorado
  // é obrigatório estar na assinatura mas não é usado nessa função
  _req: Request,

  // Objeto de resposta — usado para enviar a resposta ao Flutter
  res: Response,

  // T'a'mbém obrigatório na assinatura mas não utilizado
  _next: NextFunction,

  // ): void significa que a função não retorna nenhum valor
): void {
  // Se o erro for AppError, preserva o status lançado pela regra de negócio.
  // Caso contrário, trata como falha interna.
  const statusCode = isAppError(error) ? error.statusCode : 500;
  const message = error.message || "Erro interno do servidor";

  // Mantém um código de erro estável para o frontend mesmo quando a mensagem variar.
  const code = isAppError(error)
    ? error.code ?? getDefaultErrorCode(statusCode)
    : "INTERNAL_ERROR";

  // Loga o erro no terminal do servidor para facilitar o debug
  console.error(`[ERRO] ${statusCode} ${code} ${message}`);

  // Envia a resposta HTTP com status 500 (erro interno do servidor)
  // .json() serializa o objeto para JSON e envia para o Flutter
  // error.message || 'Erro interno do servidor' usa a mensagem do erro
  // se existir, senão usa a mensagem padrão
  res.status(statusCode).json({
    // O objeto error segue o padrão novo usado no módulo wallet.
    error: {
      code,
      message,
    },
    // O campo message é mantido por compatibilidade com respostas antigas do projeto.
    message,
  });
}
