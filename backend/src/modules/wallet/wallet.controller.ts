/*
significado do arquivo:

recebe a requisição http da busca 
pega o uid do usuário pelos parametros da rota (/historico/:uid)
chama o service 
retorna o resultado com status 200
*/

import  {Request, Response } from 'express';
import { getHistoricoOperacoesService } from './wallet.service';

// controller histórico de operações 
export async function getHistoricoOperacoesController (req: Request, res: Response) {
    // pega o uid do usuário pelos parametros da rota 
    const {uid} = req.params;

    // chama o service 
    const result = await getHistoricoOperacoesService(uid);

    // retorna o resultado 
    res.status(200).json(result);
}

// controller dos dados do dashboard 
export async function getDadosDashboardController (req: Request, res: Response) {
    // pega o uid do usuário pelos parametros da rota 
    const {uid} = req.params;

    // chama o service 
    const result = await getDadosDashboardController(uid);

    // retorna o resultado
    res.status(200).json(result);
}