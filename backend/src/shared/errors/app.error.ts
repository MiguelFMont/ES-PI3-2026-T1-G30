// Samuel Campovilla
// Este módulo define a classe AppError, 
// que é usada para representar erros específicos da aplicação.

export class AppError extends Error {
  readonly statusCode: number;
  readonly code?: string;

  // Permite anexar status HTTP e um código estável de erro ao objeto lançado.
  // Esse formato é consumido pelo errorMiddleware antes de responder ao cliente.
  constructor(message: string, statusCode = 400, code?: string) {
    super(message);
    this.name = "AppError";
    this.statusCode = statusCode;
    this.code = code;
  }
}

// Guard operator usado pelo errorMiddleware para distinguir erros conhecidos
// de erros genéricos disparados em qualquer camada da aplicação.
export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}
