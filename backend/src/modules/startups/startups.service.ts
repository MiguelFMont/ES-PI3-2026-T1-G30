import { StartupsRepo } from "./startups.repo";

const repo = new StartupsRepo();

export class StartupsService {
  async listarTodas(estagio?: string) {
    if (estagio) {
      return repo.findByEstagio(estagio);
    }
    return repo.findAllDeduplicated();
  }

  async buscarPorId(id: string) {
    const startup = await repo.findByIdMerged(id);
    if (!startup) {
      throw new Error("Startup não encontradas");
    }
    return startup;
  }
}
