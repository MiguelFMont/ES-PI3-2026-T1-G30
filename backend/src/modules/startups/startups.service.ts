import { StartupsRepo } from './startups.repo';

const repo = new StartupsRepo();

export class StartupsService {
    async listarTodas(estagio?: string) {
        if (estagio) {
            return repo.findByEstagio(estagio);
        }
        return repo.findAll();
    }

    async buscarPorId(id: string) {
        const startup = await repo.findById(id);
        if (!startup) {
            throw new Error('Startups não encontradas');
        }
        return startup;
    }
}