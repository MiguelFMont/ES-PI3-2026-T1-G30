import { Request, Response } from 'express';
import { cadastroService, loginService, recoverPasswordService } from './auth.service';

export async function cadastroController(req: Request, res: Response){

    const { nomeCompleto, email, cpf, telefone, senha } = req.body;

    const result = await cadastroService(nomeCompleto, email, cpf, telefone, senha);

    res.status(201).json(result);
}

export async function loginController(req: Request, res: Response){

    const { idToken } = req.body;

    const result = await loginService(idToken);
    
    res.status(200).json(result)
}

export async function recoverPasswordController(req: Request, res: Response){

    const { email } = req.body;

    const result = await recoverPasswordService(email);

    res.status(200).json(result)
}