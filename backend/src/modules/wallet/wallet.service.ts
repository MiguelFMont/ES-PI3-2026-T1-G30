/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:

importa a wallet (repositório)
recebe o uid do usuário
valida se o uid foi informado 
chama o repo para buscar os dados 
retorna uma mensagem e a lista de operações 

verifica se o usuário tem wallet cadastrada
se tem, retorna os dados (wallet, holdings e transações)
tranforma esses dados em variáveis 
faz os calculos de: valor total da carteira, total investido, lucro, retorno
faz os pontos do gráfico com data e valor 
retorna os dados pro dashboard 
*/

// Autor: Samuel Campovilla
// Este arquivo concentra a regra de negócio da Fase 1 da carteira.
// Os controllers chamam estas funções; elas validam entrada, estado e normalizam a resposta.

import { WalletRepo } from "./wallet.repo";
import { AppError } from "../../shared/errors/app.error";
import { Timestamp } from "firebase-admin/firestore";

// retorna o histórico de operações do usuário
export async function getHistoricoOperacoesService(uid: string) {
    // valida se o uid foi informado 
    if (!uid) {
        throw new AppError('UID do usuário é obrigatório', 400, 'INVALID_UID');
    }

    // busca o histórico no repositório e guarda na const 
    const historico = await walletRepo.getHistoricoOperacoes(uid);

    // valida se encontrou as operações 
    if (!historico || historico.length === 0){
        return {
            message: 'Nenhuma operação encontrada',
            operacoes: [],
        };
    }

    // retorna o histórico de operações
    return {
        message: 'Histórico retornado com sucesso',
        operacoes: historico,
    };
}

// retorna os dados agregados da wallet para o dashboard 
export async function getDadosDashboardService(uid: string) {
    // valida se o uid foi informado 
    if (!uid){
        throw new AppError('UID do usuário é obrigatório', 400, 'INVALID_UID');
    }

    // busca os dados no repo
    // retorna a coleção de dados 
    const dados = await walletRepo.getDadosDashboard(uid);

    // valida se encontrou a wallet
    if(!dados) {
        throw new AppError('Wallet não encontrada', 404, 'WALLET_NOT_FOUND');
    }

    // torna a coleção de objetos recebida em tres variáveis separadas 
    const { wallet, holdings, transacoes } = dados;

    // converte o saldo de centavos para reais 
    const saldoDisponivel = (wallet?.saldoCentavos ?? 0) / 100;

    // calcula valor total atual de todos os holdings 
    // .reduce percorre o array e soma os valores 
    const valorTotalCarteira = holdings.reduce(
        (soma: number, holding: any) => soma + (holding.quantidade * holding.precoMedioCentavos) / 100,
        0);
    
    // calcula o total investido somando todas as compras de tokens (holdings)
    // filtra as transações do tipo 'DIRECT_BUY' ou 'MARKET_BUY' e soma os valores
    const totalInvestido = transacoes 
        .filter((tx: any) => 
          tx.tipo === 'DIRECT_BUY' || 
          tx.tipo === 'MARKET_BUY' ||
          tx.tipo === 'COMPRA_DIRETA' ||
          tx.tipo === 'COMPRA_MERCADO'
        )
        .reduce(
            (soma: number, tx: any) => soma + (tx.valorTotalCentavos / 100),
            0
        );
        
    // calcula o lucro 
    const lucro = valorTotalCarteira - totalInvestido;

    // calcula o retorno em porcentagem 
    // se não houver investimento retorna '0.00'
    const retorno = totalInvestido > 0 
        ? ((lucro / totalInvestido) * 100).toFixed(2) // limita duas casas decimais 
        : '0.00';

    // monta os pontos do gráfico a partir das transações 
    // cada ponto tem data e valor 
    const pontosGrafico = transacoes.map((tx: any) => ({
        data: tx.createdAt, // eixo x 
        valor: tx.valorTotalCentavos / 100, // eixo y
    }));

    // retorna todos os dados calculados 
    return {
        message: 'Dados do dashboard retornados com sucesso',
        dashboard: {
            saldoDisponivel,
            valorTotalCarteira,
            totalInvestido,
            lucro,
            retorno: `${retorno}%`,
            pontosGrafico,
        },
    };
}



// Instância única do repositório usada pelo módulo.
// O service depende dela para ler e escrever no Firestore sem misturar HTTP com persistência.
const walletRepo = new WalletRepo();

// Contrato devolvido pelo GET /wallet após normalização dos dados do Firestore.
interface WalletResponse {
  uid: string;
  saldoCentavos: number;
  createdAt: string;
  updatedAt: string;
}

// Contrato devolvido pelo POST /wallet/add-balance.
// Retorna apenas o que a Fase 1 precisa expor depois da atualização.
interface WalletBalanceResponse {
  uid: string;
  saldoCentavos: number;
  updatedAt: string;
}

// Contrato devolvido para cada item do GET /wallet/holdings.
interface HoldingResponse {
  startupId: string;
  quantidade: number;
  quantidadeBloqueada: number;
  precoMedioCentavos: number;
  createdAt: string;
  updatedAt: string;
}

// Valida inteiros maiores ou iguais a zero.
// É usada para checar saldo e campos de holding já lidos do banco.
function isNonNegativeInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0;
}

// Valida inteiros estritamente positivos.
// É usada no POST /wallet/add-balance para aceitar apenas valorCentavos válido.
function isPositiveInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value > 0;
}

// Garante que o uid foi preenchido pelo authMiddleware.
// Todas as funções públicas deste service passam por aqui antes de acessar o repositório.
function assertAuthenticated(uid: string | undefined): string {
  if (!uid) {
    throw new AppError("Usuário não autenticado", 401, "UNAUTHENTICATED");
  }

  return uid;
}

// Converte Timestamp do Firestore para string ISO.
// É usada na serialização de wallet e holdings antes da resposta HTTP.
function toIsoString(
  value: unknown,
  code: "INVALID_WALLET_STATE" | "INVALID_HOLDING_STATE",
): string {
  if (!(value instanceof Timestamp)) {
    throw new AppError("Timestamp inválido na carteira.", 500, code);
  }

  return value.toDate().toISOString();
}

// Normaliza o documento de wallet retornado pelo repo.
// É chamada por getWalletService para validar estado e montar o JSON final do endpoint.
function toWalletResponse(
  wallet: Awaited<ReturnType<WalletRepo["getOrCreateWallet"]>>,
): WalletResponse {
  if (typeof wallet.uid !== "string" || wallet.uid.trim() === "") {
    throw new AppError("Carteira sem uid válido.", 500, "INVALID_WALLET_STATE");
  }

  if (!isNonNegativeInteger(wallet.saldoCentavos)) {
    throw new AppError(
      "Carteira com saldo inválido.",
      500,
      "INVALID_WALLET_STATE",
    );
  }

  return {
    // O uid vem do documento wallets/{uid} ou do próprio contexto autenticado.
    uid: wallet.uid,
    // saldoCentavos sempre trafega como inteiro para evitar ambiguidade monetária.
    saldoCentavos: wallet.saldoCentavos,
    createdAt: toIsoString(wallet.createdAt, "INVALID_WALLET_STATE"),
    updatedAt: toIsoString(wallet.updatedAt, "INVALID_WALLET_STATE"),
  };
}

// Normaliza a wallet atualizada depois do add-balance.
// É chamada por addBalanceService para devolver apenas os campos esperados na Fase 1.
function toWalletBalanceResponse(
  wallet: Awaited<ReturnType<WalletRepo["addBalance"]>>,
): WalletBalanceResponse {
  if (typeof wallet.uid !== "string" || wallet.uid.trim() === "") {
    throw new AppError("Carteira sem uid válido.", 500, "INVALID_WALLET_STATE");
  }

  if (!isNonNegativeInteger(wallet.saldoCentavos)) {
    throw new AppError(
      "Carteira com saldo inválido.",
      500,
      "INVALID_WALLET_STATE",
    );
  }

  return {
    uid: wallet.uid,
    saldoCentavos: wallet.saldoCentavos,
    updatedAt: toIsoString(wallet.updatedAt, "INVALID_WALLET_STATE"),
  };
}

// Normaliza cada documento da subcoleção holdings.
// É chamada por listHoldingsService para garantir que nenhum campo negativo saia na resposta.
function toHoldingResponse(
  holding: Awaited<ReturnType<WalletRepo["listHoldings"]>>[number],
): HoldingResponse {
  if (typeof holding.startupId !== "string" || holding.startupId.trim() === "") {
    throw new AppError(
      "Holding sem startupId válido.",
      500,
      "INVALID_HOLDING_STATE",
    );
  }

  if (!isNonNegativeInteger(holding.quantidade)) {
    throw new AppError(
      "Holding com quantidade inválida.",
      500,
      "INVALID_HOLDING_STATE",
    );
  }

  if (!isNonNegativeInteger(holding.quantidadeBloqueada)) {
    throw new AppError(
      "Holding com quantidade bloqueada inválida.",
      500,
      "INVALID_HOLDING_STATE",
    );
  }

  if (!isNonNegativeInteger(holding.precoMedioCentavos)) {
    throw new AppError(
      "Holding com preço médio inválido.",
      500,
      "INVALID_HOLDING_STATE",
    );
  }

  return {
    startupId: holding.startupId,
    quantidade: holding.quantidade,
    quantidadeBloqueada: holding.quantidadeBloqueada,
    precoMedioCentavos: holding.precoMedioCentavos,
    createdAt: toIsoString(holding.createdAt, "INVALID_HOLDING_STATE"),
    updatedAt: toIsoString(holding.updatedAt, "INVALID_HOLDING_STATE"),
  };
}

// Regra de negócio do GET /wallet.
// É chamada pelo getWalletController e cria a carteira automaticamente se ela não existir.
export async function getWalletService(
  uid: string | undefined,
): Promise<WalletResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const wallet = await walletRepo.getOrCreateWallet(authenticatedUid);
  return toWalletResponse(wallet);
}

// Regra de negócio do GET /wallet/holdings.
// É chamada pelo listHoldingsController e retorna lista vazia quando a subcoleção não existe.
export async function listHoldingsService(
  uid: string | undefined,
): Promise<{ items: HoldingResponse[] }> {
  const authenticatedUid = assertAuthenticated(uid);
  const holdings = await walletRepo.listHoldings(authenticatedUid);

  return {
    items: holdings.map(toHoldingResponse),
  };
}

// Regra de negócio do POST /wallet/add-balance.
// É chamada pelo addBalanceController e valida valorCentavos antes de atualizar a wallet.
export async function addBalanceService(
  uid: string | undefined,
  valorCentavos: unknown,
): Promise<WalletBalanceResponse> {
  const authenticatedUid = assertAuthenticated(uid);

  if (!isPositiveInteger(valorCentavos)) {
    throw new AppError(
      "O valor deve ser um inteiro positivo em centavos.",
      400,
      "INVALID_AMOUNT",
    );
  }

  const wallet = await walletRepo.addBalance(authenticatedUid, valorCentavos);
  return toWalletBalanceResponse(wallet);
}
