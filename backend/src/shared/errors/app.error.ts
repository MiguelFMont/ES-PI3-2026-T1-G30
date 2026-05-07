// Samuel Campovilla
// Este módulo define a classe AppError, 
// que é usada para representar erros específicos da aplicação.

export class AppError extends Error {
  readonly statusCode: number;

  constructor(message: string, statusCode = 400) {
    super(message);
    this.name = "AppError";
    this.statusCode = statusCode;
  }
}
// Guard Operator para verificar se um erro é uma instância de AppError.
export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}
