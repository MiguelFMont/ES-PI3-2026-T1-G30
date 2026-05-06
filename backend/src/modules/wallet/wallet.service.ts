import { WalletRepo } from "./wallet.repo";
import { AppError } from "../../shared/errors/app.error";

// Instância única do repositório usada por este módulo.
// O service chama o repo depois de validar a entrada recebida do controller.
const walletRepo = new WalletRepo();

function parseAmountToCents(amount: unknown): number {
  const normalizedAmount =
    typeof amount === "string" ? amount.trim().replace(",", ".") : amount;
  const parsedAmount = Number(normalizedAmount);

  if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
    throw new AppError(
      "O campo amount deve ser um valor monetário maior que zero",
      400,
    );
  }

  const amountInCents = Math.round(parsedAmount * 100);
  if (Math.abs(parsedAmount * 100 - amountInCents) > 1e-6) {
    throw new AppError(
      "O campo amount deve ter no máximo 2 casas decimais",
      400,
    );
  }

  return amountInCents;
}

// Service responsável pela regra de negócio do endpoint.
// Esta função é chamada por addBalanceController em wallet.controller.ts.
// Aqui ficam as validações antes de acessar o banco.
export async function addBalanceService(
  uid: string | undefined,
  amount: unknown,
) {
  // O uid vem do usuário autenticado no authMiddleware.
  // Sem ele não é possível identificar qual carteira deve ser atualizada.
  if (!uid) {
    throw new AppError("Usuário não autenticado", 401);
  }
  const amountInCents = parseAmountToCents(amount);

  // Depois da validação, a responsabilidade passa para a camada de persistência.
  return walletRepo.addBalance(uid, amountInCents);
}
