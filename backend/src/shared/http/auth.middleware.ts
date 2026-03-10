import { Request, Response, NextFunction } from 'express';
import { getAuth } from '../../config/firebase';

// Valida o token JWT do Firebase enviado pelo Flutter no header Authorization
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const token = req.headers.authorization?.split('Bearer ')[1];

  // Se não vier token, bloqueia a requisição
  if (!token) {
    res.status(401).json({ message: 'Token não fornecido' });
    return;
  }

  try {
    // Verifica se o token é válido e não expirou
    const decoded = await getAuth().verifyIdToken(token);

    // Injeta os dados do usuário no request para uso nos controllers
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({ message: 'Token inválido ou expirado' });
  }
}   