import { WalletRepo } from './wallet.repo';

// Instância única do repositório usada por este módulo.
// O service chama o repo depois de validar a entrada recebida do controller.
const walletRepo = new WalletRepo();

// Service responsável pela regra de negócio do endpoint.
// Esta função é chamada por addBalanceController em wallet.controller.ts.
// Aqui ficam as validações antes de acessar o banco.
export async function addBalanceService(
  uid: string | undefined,
  amount: unknown
) {
  // O uid vem do usuário autenticado no authMiddleware.
  // Sem ele não é possível identificar qual carteira deve ser atualizada.
  if (!uid) {
    throw new Error('Usuário não autenticado');
  }

  // Converte o valor recebido para number antes de validar.
  // Isso permite tratar valores vindos do body como número real de cálculo.
  const parsedAmount = Number(amount);

  // A regra do endpoint exige um valor numérico maior que zero.
  // Valores inválidos, vazios, não numéricos ou negativos são rejeitados.
  if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
    throw new Error('O campo amount deve ser um número maior que zero');
  }

  // Depois da validação, a responsabilidade passa para a camada de persistência.
  return walletRepo.addBalance(uid, parsedAmount);
}
