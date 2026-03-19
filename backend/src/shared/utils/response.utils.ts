import { Response } from 'express';

// Padroniza respostas de sucesso
export function sendSuccess(res: Response, data: object, status = 200): void {
  res.status(status).json({ data });
}

// Padroniza respostas de erro
export function sendError(res: Response, message: string, status = 400): void {
  res.status(status).json({ message });
}