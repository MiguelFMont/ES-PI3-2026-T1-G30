import { Request, Response } from 'express';
import { StartupsService } from './startups.service';

const service = new StartupsService();

export class StartupsController {
    async listar(req: Request, res: Response){
        try{
            const startups = await service.listarTodas(
                req.query.estagio as string | undefined
            );
            res.status(200).json({data: startups });
        } catch (err:any) {
            res.status(500).json({ error: err.message });
        }
    }

    async buscarPorId(req: Request, res: Response) {
        try{
            const id = req.params.id as string;
            const startup = await service.buscarPorId(id);
            res.status(200).json({ data: startup });
        } catch(err: any) {
            res.status(404).json({ error: err.message });
        }
    }
}