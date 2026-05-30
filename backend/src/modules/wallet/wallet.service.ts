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
// Este arquivo concentra a regra de negócio da carteira.
// Os controllers chamam estas funções; elas validam entrada, estado e normalizam a resposta.

import {
  type TipoTransacao,
  VALID_TRANSACTION_TYPES,
  WalletRepo,
} from "./wallet.repo";
import { AppError } from "../../shared/errors/app.error";
import { Timestamp } from "firebase-admin/firestore";

interface TransactionFiltersInput {
  startupId?: unknown;
  tipo?: unknown;
}

interface TransactionFilters {
  startupId?: string;
  tipo?: TipoTransacao;
}

interface TransactionResponse {
  id: string;
  startupId?: string;
  offerId?: string;
  counterpartyUserId?: string;
  tipo: TipoTransacao;
  quantidade?: number;
  precoUnitarioCentavos?: number;
  valorTotalCentavos: number;
  saldoAnteriorCentavos?: number;
  saldoNovoCentavos?: number;
  createdAt: string;
}

interface TransactionsResponse {
  items: TransactionResponse[];
}

// retorna os dados agregados da wallet para o dashboard 
export async function getDadosDashboardService(uid: string | undefined) {
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
        (soma: number, holding: any) =>
          soma +
          (getHoldingOwnedQuantity(holding) * holding.precoMedioCentavos) / 100,
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

    const tiposCompra = ['COMPRA_DIRETA', 'COMPRA_BALCAO', 'DIRECT_BUY', 'MARKET_BUY'];
    const tiposVenda  = ['VENDA_DIRETA',  'VENDA_BALCAO',  'DIRECT_SELL', 'MARKET_SELL'];

    const transacoesOrdenadas = [...transacoes].sort((a: any, b: any) => {
        const toMs = (v: any) =>
            v && typeof v.toMillis === 'function' ? v.toMillis() : new Date(v).getTime();
        return toMs(a.createdAt) - toMs(b.createdAt);
    });

    let acumulado = 0;
    const pontosGrafico = transacoesOrdenadas.map((tx: any) => {
        const valor = tx.valorTotalCentavos / 100;
        if (tiposCompra.includes(tx.tipo)) {
            acumulado += valor;
        } else if (tiposVenda.includes(tx.tipo)) {
            acumulado -= valor;
        }
        return {
            data: tx.createdAt,
            valor: acumulado,
        };
    });

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
// Retorna apenas os campos públicos necessários depois da atualização.
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

// Valida strings não vazias.
// É usada para filtros do histórico e para validar campos textuais do DTO público.
function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
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

function getHoldingOwnedQuantity(holding: {
  quantidade: number;
  quantidadeBloqueada: number;
}): number {
  return holding.quantidade + holding.quantidadeBloqueada;
}

// Garante que o filtro "tipo" só aceite os nomes oficiais do contrato em português.
// O endpoint não expõe aliases em inglês para evitar ambiguidade com contratos antigos.
function isTransactionType(value: unknown): value is TipoTransacao {
  return (
    typeof value === "string" &&
    VALID_TRANSACTION_TYPES.includes(value as TipoTransacao)
  );
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
  code: "INVALID_WALLET_STATE" | "INVALID_HOLDING_STATE" | "INTERNAL_ERROR",
): string {
  if (!(value instanceof Timestamp)) {
    throw new AppError("Timestamp inválido nos dados retornados.", 500, code);
  }

  return value.toDate().toISOString();
}

// Normaliza os filtros opcionais aceitos pelo contrato do histórico.
// Campos ausentes são ignorados; campos presentes mas inválidos geram AppError explícito.
function parseTransactionFilters(input: TransactionFiltersInput): TransactionFilters {
  const filters: TransactionFilters = {};

  if (input.startupId !== undefined) {
    if (!isNonEmptyString(input.startupId)) {
      throw new AppError(
        "startupId deve ser uma string não vazia.",
        400,
        "INVALID_STARTUP_ID",
      );
    }

    filters.startupId = input.startupId.trim();
  }

  if (input.tipo !== undefined) {
    if (!isTransactionType(input.tipo)) {
      throw new AppError(
        "tipo de transação inválido.",
        400,
        "INVALID_TRANSACTION_TYPE",
      );
    }

    filters.tipo = input.tipo;
  }

  return filters;
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
// É chamada por addBalanceService para devolver apenas os campos públicos esperados após a atualização.
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

// Samuel Campovilla:
// O DTO público do histórico é montado aqui para não acoplar a API ao documento cru do Firestore.
// Campos opcionais são omitidos quando não existem, seguindo o padrão mais enxuto já usado no módulo wallet.
function toTransactionResponse(
  transaction: Awaited<ReturnType<WalletRepo["listTransactions"]>>[number],
): TransactionResponse {
  if (!isNonEmptyString(transaction.id)) {
    throw new AppError("Transação sem id válido.", 500, "INTERNAL_ERROR");
  }

  if (!isNonEmptyString(transaction.userId)) {
    throw new AppError("Transação sem userId válido.", 500, "INTERNAL_ERROR");
  }

  if (!isTransactionType(transaction.tipo)) {
    throw new AppError("Transação com tipo inválido.", 500, "INTERNAL_ERROR");
  }

  if (!isPositiveInteger(transaction.valorTotalCentavos)) {
    throw new AppError(
      "Transação com valor total inválido.",
      500,
      "INTERNAL_ERROR",
    );
  }

  const response: TransactionResponse = {
    id: transaction.id,
    tipo: transaction.tipo,
    valorTotalCentavos: transaction.valorTotalCentavos,
    createdAt: toIsoString(transaction.createdAt, "INTERNAL_ERROR"),
  };

  if (transaction.startupId !== undefined) {
    if (!isNonEmptyString(transaction.startupId)) {
      throw new AppError("Transação com startupId inválido.", 500, "INTERNAL_ERROR");
    }

    response.startupId = transaction.startupId.trim();
  }

  if (transaction.offerId !== undefined) {
    if (!isNonEmptyString(transaction.offerId)) {
      throw new AppError("Transação com offerId inválido.", 500, "INTERNAL_ERROR");
    }

    response.offerId = transaction.offerId.trim();
  }

  if (transaction.counterpartyUserId !== undefined) {
    if (!isNonEmptyString(transaction.counterpartyUserId)) {
      throw new AppError(
        "Transação com counterpartyUserId inválido.",
        500,
        "INTERNAL_ERROR",
      );
    }

    response.counterpartyUserId = transaction.counterpartyUserId.trim();
  }

  if (transaction.quantidade !== undefined) {
    if (!isPositiveInteger(transaction.quantidade)) {
      throw new AppError("Transação com quantidade inválida.", 500, "INTERNAL_ERROR");
    }

    response.quantidade = transaction.quantidade;
  }

  if (transaction.precoUnitarioCentavos !== undefined) {
    if (!isPositiveInteger(transaction.precoUnitarioCentavos)) {
      throw new AppError(
        "Transação com preço unitário inválido.",
        500,
        "INTERNAL_ERROR",
      );
    }

    response.precoUnitarioCentavos = transaction.precoUnitarioCentavos;
  }

  if (transaction.saldoAnteriorCentavos !== undefined) {
    if (!isNonNegativeInteger(transaction.saldoAnteriorCentavos)) {
      throw new AppError(
        "Transação com saldo anterior inválido.",
        500,
        "INTERNAL_ERROR",
      );
    }

    response.saldoAnteriorCentavos = transaction.saldoAnteriorCentavos;
  }

  if (transaction.saldoNovoCentavos !== undefined) {
    if (!isNonNegativeInteger(transaction.saldoNovoCentavos)) {
      throw new AppError(
        "Transação com saldo novo inválido.",
        500,
        "INTERNAL_ERROR",
      );
    }

    response.saldoNovoCentavos = transaction.saldoNovoCentavos;
  }

  return response;
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

// Samuel Campovilla:
// O histórico sempre deriva do UID autenticado e nunca de parâmetros externos.
// O DTO e os filtros ficam centralizados aqui para o endpoint atual /transactions não depender
// do formato cru do Firestore nem de contratos antigos.
export async function getTransactionsService(
  uid: string | undefined,
  filtersInput: TransactionFiltersInput = {},
): Promise<TransactionsResponse> {
  const authenticatedUid = assertAuthenticated(uid);
  const filters = parseTransactionFilters(filtersInput);
  const transactions = await walletRepo.listTransactions(authenticatedUid, filters);

  return {
    items: transactions.map(toTransactionResponse),
  };
}

// Alias de compatibilidade com o nome antigo do histórico de operações.
// O contrato atual do módulo usa getTransactionsService e o endpoint /wallet/transactions,
// mas este export evita erro em imports locais que ainda não foram atualizados.
export const getHistoricoOperacoesService = getTransactionsService;

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

// Regra de negócio do POST /wallet/withdraw.
// Reaproveita o contrato valorCentavos e garante que o saldo nunca fique negativo.
export async function withdrawService(
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

  const wallet = await walletRepo.withdraw(authenticatedUid, valorCentavos);
  return toWalletBalanceResponse(wallet);
}
