// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { UsersRepo } from "./users.repo";

export class UsersService {
  private repo = new UsersRepo();

  // Converte a leitura da wallet em um saldo consistente para o perfil.
  // É usada apenas por getPerfil e agora considera apenas saldoCentavos.
  private getSaldoInCents(
    wallet: Awaited<ReturnType<UsersRepo["findWalletByUid"]>>,
  ) {
    return wallet?.saldoCentavos ?? 0;
  }

  // Monta o payload do endpoint de perfil do usuário.
  // É chamada por users.controller.ts e consulta usuário + wallet em paralelo.
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

    // O perfil usa o saldo da wallet já no padrão novo da Fase 1.
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
