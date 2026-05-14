// Samuel Campovilla:
// Serviço reutilizável da Fase 5 para cálculo e persistência do preço dos tokens.
// Hoje ele é chamado por trades.repo.ts nos fluxos de compra e venda direta.
// A responsabilidade aqui é concentrar regras de valorização natural, impacto da negociação
// e escrita do histórico de preço dentro da mesma Firestore Transaction da operação.
import { getDb } from "../../config/firebase";
import { AppError } from "../../shared/errors/app.error";

// Regras-base da oscilação simulada.
// Mantemos tudo em inteiros para evitar decimal persistido e arredondamento inconsistente no Firestore.
export const PRECO_MINIMO_CENTAVOS = 1;
export const BASIS_POINTS = 10000;
export const MAX_VARIACAO_OPERACAO_BPS = 300;
export const MAX_VARIACAO_NATURAL_ACUMULADA_BPS = 3000;
// isso é usado para converter diferença de tempo em dias inteiros
const MILLIS_PER_DAY = 24 * 60 * 60 * 1000;

export type MotivoHistoricoPreco =
  | "PRECO_INICIAL"
  | "VALORIZACAO_NATURAL"
  | "COMPRA_DIRETA"
  | "VENDA_DIRETA"
  | "OFERTA_ACEITA";

export type PriceImpactReason = Exclude<
  MotivoHistoricoPreco,
  "PRECO_INICIAL" | "VALORIZACAO_NATURAL"
>;

type StartupPriceState = {
  startupId: string;
  precoTokenAtualCentavos: number;
  totalTokens: number;
  taxaVariacaoNaturalDiariaBps: number;
  referenciaNaturalAt: Date;
};

type NaturalPriceCalculation = {
  diasPassados: number;
  variacaoNaturalBps: number;
  precoAposNaturalCentavos: number;
};

type TradeImpactCalculation = {
  precoNovoCentavos: number;
  tradeImpactBps: number;
};

export type ApplyTradePriceImpactInput = {
  startupId: string;
  precoAtualCentavos: number;
  totalTokens: number;
  quantidade: number;
  motivo: PriceImpactReason;
  transactionId?: string;
  offerId?: string;
  precoNegociadoCentavos?: number;
};

export type ApplyTradePriceUpdateToTransactionInput = {
  transaction: FirebaseFirestore.Transaction;
  startupRef: FirebaseFirestore.DocumentReference;
  startupId: string;
  startupData: FirebaseFirestore.DocumentData | undefined;
  quantidade: number;
  motivo: PriceImpactReason;
  commonTimestamp: FirebaseFirestore.FieldValue;
  transactionId?: string;
  offerId?: string;
  precoNegociadoCentavos?: number;
  extraStartupUpdateData?: Record<string, unknown>;
};

export type PriceUpdateResult = {
  precoAnteriorCentavos: number;
  precoAposNaturalCentavos: number;
  precoNovoCentavos: number;
  naturalApplied: boolean;
  tradeImpactBps: number;
};

export class PriceService {
  private db = getDb();

  // Valida preço, totalTokens e quantidade quando o contrato exige inteiro positivo.
  private isPositiveInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value > 0;
  }

  // Valida campos que podem assumir zero, como taxa natural configurada para não variar.
  private isNonNegativeInteger(value: unknown): value is number {
    return typeof value === "number" && Number.isInteger(value) && value >= 0;
  }

  // Diferencia campo ausente de campo presente porém inválido para aplicar fallback com segurança.
  private hasOwnField(data: FirebaseFirestore.DocumentData | undefined, field: string) {
    return Boolean(data) && Object.prototype.hasOwnProperty.call(data, field);
  }

  // Normaliza textos de estagio para aceitar diferenças de caixa e acentuação já existentes no banco.
  private normalizeStage(value: string): string {
    return value
      .trim()
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "");
  }

  // Resolve a taxa diária natural quando a startup ainda não possui taxaVariacaoNaturalDiariaBps gravada.
  // Este fallback protege startups legadas e mantém a regra no backend.
  private resolveTaxaVariacaoNaturalDiariaBps(
    estagio: unknown,
  ): number {
    if (typeof estagio !== "string" || estagio.trim() === "") {
      return 5;
    }

    const normalized = this.normalizeStage(estagio);

    if (normalized === "nova") {
      return 20;
    }

    if (normalized === "em operacao") {
      return 10;
    }

    if (normalized === "em expansao") {
      return 5;
    }

    return 5;
  }

  // Converte Timestamp/Date em Date nativo para o cálculo de dias inteiros.
  private toDate(value: unknown): Date | null {
    if (value instanceof Date && !Number.isNaN(value.getTime())) {
      return value;
    }

    if (typeof value !== "object" || value === null) {
      return null;
    }

    const maybeTimestamp = value as {
      toDate?: () => Date;
      toMillis?: () => number;
    };

    if (typeof maybeTimestamp.toDate === "function") {
      const date = maybeTimestamp.toDate();

      if (date instanceof Date && !Number.isNaN(date.getTime())) {
        return date;
      }
    }

    if (typeof maybeTimestamp.toMillis === "function") {
      const millis = maybeTimestamp.toMillis();

      if (Number.isFinite(millis)) {
        const date = new Date(millis);

        if (!Number.isNaN(date.getTime())) {
          return date;
        }
      }
    }

    return null;
  }

  // Define de qual data parte a valorização natural.
  // A ordem do fallback evita aplicar retroativo sem base confiável:
  // ultimaAtualizacaoPrecoAt -> createdAt -> agora.
  private resolveReferenciaNaturalAt(
    startupData: FirebaseFirestore.DocumentData | undefined,
    now: Date,
  ): Date {
    if (this.hasOwnField(startupData, "ultimaAtualizacaoPrecoAt")) {
      const ultimaAtualizacaoPrecoAt = this.toDate(
        startupData?.ultimaAtualizacaoPrecoAt,
      );

      if (!ultimaAtualizacaoPrecoAt) {
        throw new AppError(
          "Startup com ultimaAtualizacaoPrecoAt inválido.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      return ultimaAtualizacaoPrecoAt;
    }

    if (this.hasOwnField(startupData, "createdAt")) {
      const createdAt = this.toDate(startupData?.createdAt);

      if (!createdAt) {
        throw new AppError(
          "Startup com createdAt inválido.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      return createdAt;
    }

    return now;
  }

  // Normaliza o documento startups/{startupId} para o formato interno do serviço.
  // Este método é chamado no início da atualização de preço para validar estado e resolver fallbacks.
  private toStartupPriceState(
    startupId: string,
    startupData: FirebaseFirestore.DocumentData | undefined,
    now: Date,
  ): StartupPriceState {
    if (!this.isPositiveInteger(startupData?.precoTokenAtualCentavos)) {
      throw new AppError(
        "Startup com precoTokenAtualCentavos inválido.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    if (!this.isPositiveInteger(startupData?.totalTokens)) {
      throw new AppError(
        "Startup com totalTokens inválido.",
        500,
        "INVALID_STARTUP_STATE",
      );
    }

    if (
      this.hasOwnField(startupData, "precoTokenInicialCentavos") &&
      startupData?.precoTokenInicialCentavos !== undefined &&
      !this.isPositiveInteger(startupData.precoTokenInicialCentavos)
    ) {
      throw new AppError(
        "Startup com precoTokenInicialCentavos inválido.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    let taxaVariacaoNaturalDiariaBps =
      this.resolveTaxaVariacaoNaturalDiariaBps(startupData?.estagio);

    if (this.hasOwnField(startupData, "taxaVariacaoNaturalDiariaBps")) {
      if (!this.isNonNegativeInteger(startupData?.taxaVariacaoNaturalDiariaBps)) {
        throw new AppError(
          "Startup com taxaVariacaoNaturalDiariaBps inválido.",
          500,
          "INVALID_STARTUP_STATE",
        );
      }

      taxaVariacaoNaturalDiariaBps = startupData.taxaVariacaoNaturalDiariaBps;
    }

    return {
      startupId,
      precoTokenAtualCentavos: startupData.precoTokenAtualCentavos,
      totalTokens: startupData.totalTokens,
      taxaVariacaoNaturalDiariaBps,
      referenciaNaturalAt: this.resolveReferenciaNaturalAt(startupData, now),
    };
  }

  // Aplica uma variação em basis points sobre um preço em centavos.
  // A mesma fórmula é usada pela valorização natural e pelo impacto de mercado da negociação.
  private applyPriceVariationInBps(
    precoAtualCentavos: number,
    variacaoBps: number,
  ): number {
    const fatorBps = BASIS_POINTS + variacaoBps;

    if (!this.isPositiveInteger(precoAtualCentavos) || fatorBps <= 0) {
      throw new AppError(
        "Não foi possível aplicar a variação do preço.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    // Basis points evitam decimal persistido no Firestore e deixam as regras
    // de valorização e impacto de negociação inteiras e previsíveis.
    const numerador = precoAtualCentavos * fatorBps;

    if (!Number.isSafeInteger(numerador) || numerador < 0) {
      throw new AppError(
        "Não foi possível calcular a variação do preço.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    return Math.max(
      PRECO_MINIMO_CENTAVOS,
      Math.floor(numerador / BASIS_POINTS),
    );
  }

  // Calcula a valorização natural acumulada sob demanda.
  // Hoje este cálculo é executado antes de cada compra/venda direta, sem depender de cron ou scheduler.
  private calculateNaturalPrice(
    startup: StartupPriceState,
    now: Date,
  ): NaturalPriceCalculation {
    const diffMillis = now.getTime() - startup.referenciaNaturalAt.getTime();
    const diasPassados = diffMillis > 0 ? Math.floor(diffMillis / MILLIS_PER_DAY) : 0;

    if (diasPassados <= 0 || startup.taxaVariacaoNaturalDiariaBps === 0) {
      return {
        diasPassados: 0,
        variacaoNaturalBps: 0,
        precoAposNaturalCentavos: startup.precoTokenAtualCentavos,
      };
    }

    const rawVariacaoNaturalBps =
      diasPassados * startup.taxaVariacaoNaturalDiariaBps;

    if (!Number.isSafeInteger(rawVariacaoNaturalBps) || rawVariacaoNaturalBps < 0) {
      throw new AppError(
        "Não foi possível calcular a valorização natural.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    const variacaoNaturalBps = Math.min(
      rawVariacaoNaturalBps,
      MAX_VARIACAO_NATURAL_ACUMULADA_BPS,
    );

    return {
      diasPassados,
      variacaoNaturalBps,
      precoAposNaturalCentavos: this.applyPriceVariationInBps(
        startup.precoTokenAtualCentavos,
        variacaoNaturalBps,
      ),
    };
  }

  // Converte o volume negociado em impacto percentual limitado por operação.
  // Isso evita que uma única compra/venda gere saltos exagerados no preço simulado.
  private calculateVolumeImpactBps(
    quantidade: number,
    totalTokens: number,
  ): number {
    if (!this.isPositiveInteger(quantidade)) {
      throw new AppError(
        "Quantidade inválida para cálculo de preço.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    if (!this.isPositiveInteger(totalTokens)) {
      throw new AppError(
        "totalTokens inválido para cálculo de preço.",
        500,
        "INVALID_STARTUP_STATE",
      );
    }

    const numerador = quantidade * BASIS_POINTS;

    if (!Number.isSafeInteger(numerador) || numerador <= 0) {
      throw new AppError(
        "Não foi possível calcular o impacto da negociação.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    return Math.min(
      Math.floor(numerador / totalTokens),
      MAX_VARIACAO_OPERACAO_BPS,
    );
  }

  // Regra futura para aceite de oferta.
  // Ainda não há endpoint nesta fase, mas a função já fica pronta para reutilização futura.
  private calculateAcceptedOfferImpact(
    precoAtualCentavos: number,
    precoNegociadoCentavos: number | undefined,
  ): TradeImpactCalculation {
    if (!this.isPositiveInteger(precoNegociadoCentavos)) {
      throw new AppError(
        "precoNegociadoCentavos inválido para OFERTA_ACEITA.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    if (precoNegociadoCentavos === precoAtualCentavos) {
      return {
        precoNovoCentavos: precoAtualCentavos,
        tradeImpactBps: 0,
      };
    }

    const diferencaCentavos = Math.abs(precoNegociadoCentavos - precoAtualCentavos);
    const impactoBrutoBps = Math.floor(
      (diferencaCentavos * BASIS_POINTS) / precoAtualCentavos,
    );
    const impactoBps = Math.min(impactoBrutoBps, MAX_VARIACAO_OPERACAO_BPS);
    const signedImpactBps =
      precoNegociadoCentavos > precoAtualCentavos ? impactoBps : -impactoBps;

    return {
      precoNovoCentavos: this.applyPriceVariationInBps(
        precoAtualCentavos,
        signedImpactBps,
      ),
      tradeImpactBps: signedImpactBps,
    };
  }

  // Calcula o impacto específico da negociação sobre o preço atual consolidado.
  // É chamado por applyTradePriceUpdateToTransaction depois de aplicar a valorização natural pendente.
  applyTradePriceImpact(
    input: ApplyTradePriceImpactInput,
  ): TradeImpactCalculation {
    if (!this.isPositiveInteger(input.precoAtualCentavos)) {
      throw new AppError(
        "precoAtualCentavos inválido para cálculo de impacto.",
        500,
        "INVALID_PRICE_STATE",
      );
    }

    switch (input.motivo) {
      // Compra direta representa pressão de demanda e empurra o preço para cima
      // apenas para o estado futuro da startup.
      case "COMPRA_DIRETA": {
        const impactoBps = this.calculateVolumeImpactBps(
          input.quantidade,
          input.totalTokens,
        );

        return {
          precoNovoCentavos: this.applyPriceVariationInBps(
            input.precoAtualCentavos,
            impactoBps,
          ),
          tradeImpactBps: impactoBps,
        };
      }

      // Venda direta representa pressão de oferta e reduz o preço futuro,
      // sem alterar o preço já usado para pagar a venda em andamento.
      case "VENDA_DIRETA": {
        const impactoBps = this.calculateVolumeImpactBps(
          input.quantidade,
          input.totalTokens,
        );

        // A venda direta é liquidada pelo preço capturado antes da recompra,
        // e só depois pressiona o preço futuro para baixo como oscilação simulada.
        return {
          precoNovoCentavos: this.applyPriceVariationInBps(
            input.precoAtualCentavos,
            -impactoBps,
          ),
          tradeImpactBps: -impactoBps,
        };
      }

      case "OFERTA_ACEITA":
        return this.calculateAcceptedOfferImpact(
          input.precoAtualCentavos,
          input.precoNegociadoCentavos,
        );

      default:
        throw new AppError(
          "Motivo de impacto de preço inválido.",
          500,
          "INVALID_PRICE_IMPACT_REASON",
        );
    }
  }

  // Gera a referência do próximo ponto histórico em priceHistory/{startupId}/points.
  // O dashboard poderá ler essa subcoleção como série temporal no futuro.
  private getPriceHistoryPointRef(startupId: string) {
    return this.db
      .collection("priceHistory")
      .doc(startupId)
      .collection("points")
      .doc();
  }

  // Grava um ponto de histórico dentro da mesma transaction da negociação.
  // Isso garante consistência entre preço atual da startup e trilha histórica.
  private writePriceHistoryPoint(
    transaction: FirebaseFirestore.Transaction,
    startupId: string,
    precoCentavos: number,
    motivo: Exclude<MotivoHistoricoPreco, "PRECO_INICIAL">,
    commonTimestamp: FirebaseFirestore.FieldValue,
    transactionId?: string,
    offerId?: string,
  ): void {
    const pointRef = this.getPriceHistoryPointRef(startupId);
    const pointData: Record<string, unknown> = {
      startupId,
      precoCentavos,
      motivo,
      createdAt: commonTimestamp,
    };

    if (typeof transactionId === "string" && transactionId.trim() !== "") {
      pointData.transactionId = transactionId;
    }

    if (typeof offerId === "string" && offerId.trim() !== "") {
      pointData.offerId = offerId;
    }

    transaction.set(pointRef, pointData);
  }

  // Método principal chamado por trades.repo.ts ao final da compra/venda direta.
  // Sequência executada:
  // 1) valida e normaliza a startup;
  // 2) aplica valorização natural pendente;
  // 3) aplica o impacto da negociação atual;
  // 4) atualiza startups/{startupId};
  // 5) registra pontos em priceHistory quando o preço realmente muda.
  applyTradePriceUpdateToTransaction(
    input: ApplyTradePriceUpdateToTransactionInput,
  ): PriceUpdateResult {
    const now = new Date();
    const startup = this.toStartupPriceState(input.startupId, input.startupData, now);
    const naturalPrice = this.calculateNaturalPrice(startup, now);
    const tradeImpact = this.applyTradePriceImpact({
      startupId: input.startupId,
      precoAtualCentavos: naturalPrice.precoAposNaturalCentavos,
      totalTokens: startup.totalTokens,
      quantidade: input.quantidade,
      motivo: input.motivo,
      transactionId: input.transactionId,
      offerId: input.offerId,
      precoNegociadoCentavos: input.precoNegociadoCentavos,
    });

    const result: PriceUpdateResult = {
      precoAnteriorCentavos: startup.precoTokenAtualCentavos,
      precoAposNaturalCentavos: naturalPrice.precoAposNaturalCentavos,
      precoNovoCentavos: tradeImpact.precoNovoCentavos,
      naturalApplied:
        naturalPrice.precoAposNaturalCentavos !== startup.precoTokenAtualCentavos,
      tradeImpactBps: tradeImpact.tradeImpactBps,
    };

    // O preço consolidado e os pontos do histórico precisam nascer na mesma
    // transaction da compra/venda para não haver carteira liquidada com preço antigo
    // e startup gravada com preço novo sem o histórico correspondente.
    input.transaction.update(input.startupRef, {
      ...input.extraStartupUpdateData,
      precoTokenAtualCentavos: result.precoNovoCentavos,
      ultimaAtualizacaoPrecoAt: input.commonTimestamp,
      taxaVariacaoNaturalDiariaBps: startup.taxaVariacaoNaturalDiariaBps,
      updatedAt: input.commonTimestamp,
    });

    // O ponto de valorização natural vem primeiro para refletir a ordem cronológica da regra:
    // primeiro o tempo passa, depois a negociação atual move o preço.
    if (result.naturalApplied) {
      this.writePriceHistoryPoint(
        input.transaction,
        startup.startupId,
        result.precoAposNaturalCentavos,
        "VALORIZACAO_NATURAL",
        input.commonTimestamp,
      );
    }

    // O ponto da negociação só é gravado quando há mudança real após arredondamento.
    // Isso evita ruído em priceHistory com operações cujo impacto líquido foi zero centavos.
    if (result.precoNovoCentavos !== result.precoAposNaturalCentavos) {
      this.writePriceHistoryPoint(
        input.transaction,
        startup.startupId,
        result.precoNovoCentavos,
        input.motivo,
        input.commonTimestamp,
        input.transactionId,
        input.offerId,
      );
    }

    return result;
  }
}
