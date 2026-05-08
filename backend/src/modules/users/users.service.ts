// Autor: Miguel Fernandes Monteiro — RA: 25014808

import { UsersRepo } from "./users.repo";

// Converte uma string de data (ISO, timestamp ou DD/MM/AAAA) para DD/MM/AAAA.
// Retorna '—' se o valor for inválido ou ausente.
function _formatarData(valor: string | null | undefined): string {
  if (!valor) return '—';

  // Já está no formato esperado
  if (/^\d{2}\/\d{2}\/\d{4}$/.test(valor)) return valor;

  const data = new Date(valor);
  if (isNaN(data.getTime())) return '—';

  return data.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

const CAMPOS_PERMITIDOS = ['nome', 'email', 'telefone'] as const;
type CampoPermitido = typeof CAMPOS_PERMITIDOS[number];

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

    const saldo = wallet?.saldo ?? 0;
    const patrimonio = saldo * 1.05;

    return {
      uid: user.uid,
      nome: user.nomeCompleto?.trim() ?? "Usuário",
      email: user.email,
      telefone: user.telefone ?? null,
      dataNascimento: _formatarData(user.dataNascimento),
      cpf: user.cpf,
      saldo,
      patrimonio,
      desde,
    };
  }

  async updatePerfil(uid: string, body: Record<string, unknown>) {
    const user = await this.repo.findByUid(uid);
    if (!user) throw new Error('Usuário não encontrado');

    const payload: Partial<Record<CampoPermitido, string>> = {};
    for (const campo of CAMPOS_PERMITIDOS) {
      if (campo in body && typeof body[campo] === 'string') {
        payload[campo] = (body[campo] as string).trim();
      }
    }

    if (Object.keys(payload).length === 0) {
      throw new Error('Nenhum campo válido para atualizar.');
    }

    // Mapeia os nomes da API para os campos do Firestore
    const dadosFirestore: Record<string, string> = {};
    if (payload.nome)     dadosFirestore['nomeCompleto'] = payload.nome;
    if (payload.email)    dadosFirestore['email']        = payload.email;
    if (payload.telefone) dadosFirestore['telefone']     = payload.telefone;

    // update() vem do FirestoreBaseRepo e já adiciona updatedAt automaticamente
    await this.repo.update(user.id, dadosFirestore);
  }
}
