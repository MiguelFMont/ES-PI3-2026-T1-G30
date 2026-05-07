// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { UsersRepo } from "./users.repo";

export class UsersService {
  private repo = new UsersRepo();

  private getSaldoInCents(
    wallet: Awaited<ReturnType<UsersRepo["findWalletByUid"]>>,
  ) {
    if (wallet?.saldoCentavos !== undefined) {
      return wallet.saldoCentavos;
    }

    if (wallet?.saldo !== undefined) {
      return Math.round(wallet.saldo * 100);
    }

    return 0;
  }

  async getPerfil(uid: string) {
    const [user, wallet] = await Promise.all([
      this.repo.findByUid(uid),
      this.repo.findWalletByUid(uid),
    ]);

    if (!user) throw new Error("Usuário não encontrado");

    let desde = "—";
    if (user.createdAt) {
      desde = user.createdAt.toDate().toLocaleDateString("pt-BR", {
        month: "short",
        year: "numeric",
      });
    }

    const saldoCentavos = this.getSaldoInCents(wallet);
    const totalStartups = wallet?.startupIds?.length ?? 0;
    const patrimonioCentavos = Math.round(saldoCentavos * 1.05);

    return {
      uid: user.uid,
      nome: user.nomeCompleto?.trim() ?? "Usuário",
      email: user.email,
      telefone: user.telefone ?? null,
      saldoCentavos,
      patrimonioCentavos,
      totalStartups,
      desde,
    };
  }
}
