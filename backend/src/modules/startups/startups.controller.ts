import { Request, Response } from 'express';
import { StartupsService } from './startups.service';

const service = new StartupsService();

export class StartupsController {
    async listar(req: Request, res: Response) {
        try {
            const { estagio } = req.query;
            const startups = await service.listarTodas(estagio as string);
            res.json({ data: startups }); 
        } catch (err: any) {
            res.status(500).json({ error: err.message});
        }
    }

    async buscarPorId(req: Request, res: Response) {
        try {
            const startup = await service.buscarPorId(req.params.id);
            res.json({ data: startup });
        } catch (err: any) {
            res.status(404).json({ error: err.message });
        }
    }
}