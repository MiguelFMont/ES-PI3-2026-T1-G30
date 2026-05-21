import { Request, Response, NextFunction } from 'express';
import { getAuth } from '../../config/firebase';
import { AppError } from "../errors/app.error";

// Valida o token JWT do Firebase enviado pelo cliente no header Authorization.
// Este middleware é usado em wallet.routes.ts antes dos controllers do módulo.
export async function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  // Lê o header bruto para validar explicitamente o formato Bearer <token>.
  const authHeader = req.headers.authorization ?? "";

  // Se o prefixo Bearer não existir, o fluxo é interrompido com erro de autenticação.
  if (!authHeader.startsWith("Bearer ")) {
    next(new AppError("Token não fornecido", 401, "UNAUTHENTICATED"));
    return;
  }

  // Remove o prefixo "Bearer " e elimina espaços extras.
  const token = authHeader.slice(7).trim();

  // Também rejeita casos em que o header veio com Bearer mas sem token real.
  if (!token) {
    next(new AppError("Token não fornecido", 401, "UNAUTHENTICATED"));
    return;
  }

  try {
    // Verifica se o token é válido e não expirou no Firebase Auth.
    const decoded = await getAuth().verifyIdToken(token);

    // Injeta os dados do usuário no request para uso nos controllers e services.
    req.user = decoded;
    next();
  } catch {
    // Centraliza o erro no errorMiddleware para manter o formato JSON padronizado.
    next(new AppError("Token inválido ou expirado", 401, "UNAUTHENTICATED"));
  }
}
