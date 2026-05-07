// Importa os tipos do Express para tipar os parâmetros da função
// Request      → representa a requisição recebida
// Response     → representa a resposta que será enviada
// NextFunction → função que passa o controle para o próximo middleware
import { Request, Response, NextFunction } from "express";
import { isAppError } from "./app.error";

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
  const statusCode = isAppError(error) ? error.statusCode : 500;

  // Loga o erro no terminal do servidor para facilitar o debug
  console.error(`[ERRO] ${statusCode} ${error.message}`);

  // Envia a resposta HTTP com status 500 (erro interno do servidor)
  // .json() serializa o objeto para JSON e envia para o Flutter
  // error.message || 'Erro interno do servidor' usa a mensagem do erro
  // se existir, senão usa a mensagem padrão
  res.status(statusCode).json({
    message: error.message || "Erro interno do servidor",
  });
}
