/**
 * Samuel Campovilla
 * Seed idempotente para adicionar campos de negociacao nas startups.
 *
 * Como executar:
 *   npm run seed:trading-fields
 *
 * Requisitos:
 * - credenciais validas para o Firebase Admin SDK;
 * - acesso de escrita na colecao "startups".
 */

import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../src/config/firebase';
// O tipo StartupDoc representa a estrutura dos documentos na coleção "startups".
type StartupDoc = {
  nome?: unknown;
  totalTokens?: unknown;
  tokensDisponiveis?: unknown;
  precoTokenInicialCentavos?: unknown;
  precoTokenAtualCentavos?: unknown;
  descontoVendaDiretaBps?: unknown;
};
// Valores padrao para os campos de negociacao, caso estejam ausentes.
const DEFAULT_PRECO_TOKEN_CENTAVOS = 1000;
const DEFAULT_DESCONTO_VENDA_DIRETA_BPS = 1000;
// Esta função verifica se um objeto possui um campo específico como propriedade direta (não herdada).
// isso é importante para distinguir entre campos que realmente existem no documento 
// e aqueles que podem estar ausentes ou herdados da cadeia de protótipos.
function hasOwnField<T extends object>(data: T, field: keyof any): boolean {
  return Object.prototype.hasOwnProperty.call(data, field);
}
// Esta função formata um rótulo legível para uma startup, usando seu nome e ID do documento.
function formatStartupLabel(docId: string, data: StartupDoc): string {
  const nome =
    typeof data.nome === 'string' && data.nome.trim().length > 0
      ? data.nome.trim()
      : 'Startup sem nome';

  return `${nome} (${docId})`;
}
// A função principal que executa o processo de seed.
async function seedTradingFields(): Promise<void> {
  const db = getDb();
  const snapshot = await db.collection('startups').get();
  // Variáveis para manter contagem de quantas startups foram atualizadas ou ignoradas.
  // Isso ajuda a fornecer um resumo claro no final do processo de seed.
  // No projeto serve para monitorar o resultado da execução do seed - é opcinal, mas boas práticas de  desenvolvimento recomendam fornecer feedback claro sobre o que o script fez.
  let updatedCount = 0;
  let skippedAlreadyCompleteCount = 0;
  let skippedMissingTotalTokensCount = 0;

  console.log(
    `[seed:trading-fields] ${snapshot.size} startup(s) encontrada(s).`
  );

  for (const doc of snapshot.docs) {
    const data = doc.data() as StartupDoc;
    const startupLabel = formatStartupLabel(doc.id, data);
    const totalTokens = data.totalTokens;

    if (typeof totalTokens !== 'number' || !Number.isFinite(totalTokens)) {
      skippedMissingTotalTokensCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} sem totalTokens numerico valido.`
      );
      continue;
    }

    const updateData: Record<string, unknown> = {};
    const addedFields: string[] = [];

    if (!hasOwnField(data, 'tokensDisponiveis')) {
      updateData.tokensDisponiveis = totalTokens;
      addedFields.push('tokensDisponiveis');
    }

    if (!hasOwnField(data, 'precoTokenInicialCentavos')) {
      updateData.precoTokenInicialCentavos = DEFAULT_PRECO_TOKEN_CENTAVOS;
      addedFields.push('precoTokenInicialCentavos');
    }

    if (!hasOwnField(data, 'precoTokenAtualCentavos')) {
      updateData.precoTokenAtualCentavos = DEFAULT_PRECO_TOKEN_CENTAVOS;
      addedFields.push('precoTokenAtualCentavos');
    }

    if (!hasOwnField(data, 'descontoVendaDiretaBps')) {
      updateData.descontoVendaDiretaBps = DEFAULT_DESCONTO_VENDA_DIRETA_BPS;
      addedFields.push('descontoVendaDiretaBps');
    }

    if (addedFields.length === 0) {
      skippedAlreadyCompleteCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} ja possui todos os campos de negociacao.`
      );
      continue;
    }

    updateData.updatedAt = FieldValue.serverTimestamp();

    await doc.ref.update(updateData);

    updatedCount += 1;
    console.log(
      `[ATUALIZADA] ${startupLabel} -> ${addedFields.join(', ')}.`
    );
  }

  console.log('');
  console.log('[seed:trading-fields] Resumo final:');
  console.log(`- startups encontradas: ${snapshot.size}`);
  console.log(`- startups atualizadas: ${updatedCount}`);
  console.log(
    `- startups ignoradas (ja completas): ${skippedAlreadyCompleteCount}`
  );
  console.log(
    `- startups ignoradas (sem totalTokens valido): ${skippedMissingTotalTokensCount}`
  );
  console.log('[seed:trading-fields] Seed concluido com sucesso.');
}
// Executa a função de seed e lida com erros de forma adequada.
seedTradingFields()
  .then(() => process.exit(0))
  .catch((error: unknown) => {
    console.error('[seed:trading-fields] Erro durante a execucao:', error);
    process.exit(1);
  });
