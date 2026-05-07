/**
 * Samuel Campovilla
 * Seed idempotente para criar o ponto inicial de historico de preco.
 *
 * Como executar:
 *   npm run seed:price-history
 *
 * Requisitos:
 * - credenciais validas para o Firebase Admin SDK;
 * - acesso de escrita na colecao "priceHistory";
 * - acesso de leitura na colecao "startups".
 */

import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../src/config/firebase';

type StartupDoc = {
  nome?: unknown;
  precoTokenAtualCentavos?: unknown;
};

const PRECO_INICIAL_MOTIVO = 'PRECO_INICIAL';

function formatStartupLabel(docId: string, data: StartupDoc): string {
  const nome =
    typeof data.nome === 'string' && data.nome.trim().length > 0
      ? data.nome.trim()
      : 'Startup sem nome';

  return `${nome} (${docId})`;
}

async function seedPriceHistory(): Promise<void> {
  const db = getDb();
  const startupsSnapshot = await db.collection('startups').get();

  let createdCount = 0;
  let skippedExistingInitialPointCount = 0;
  let skippedInvalidPriceCount = 0;

  console.log(
    `[seed:price-history] ${startupsSnapshot.size} startup(s) encontrada(s).`
  );

  for (const startupDoc of startupsSnapshot.docs) {
    const startupData = startupDoc.data() as StartupDoc;
    const startupLabel = formatStartupLabel(startupDoc.id, startupData);
    const precoTokenAtualCentavos = startupData.precoTokenAtualCentavos;

    if (
      typeof precoTokenAtualCentavos !== 'number' ||
      !Number.isFinite(precoTokenAtualCentavos) ||
      !Number.isInteger(precoTokenAtualCentavos) ||
      precoTokenAtualCentavos <= 0
    ) {
      skippedInvalidPriceCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} sem precoTokenAtualCentavos inteiro positivo valido.`
      );
      continue;
    }

    const pointsRef = db
      .collection('priceHistory')
      .doc(startupDoc.id)
      .collection('points');
    const initialPointRef = pointsRef.doc('initial');
    const initialPointSnapshot = await initialPointRef.get();

    if (initialPointSnapshot.exists) {
      skippedExistingInitialPointCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} ja possui ponto inicial de historico.`
      );
      continue;
    }

    // Compatibilidade com seeds antigas que criaram PRECO_INICIAL com ID aleatorio.
    const existingInitialPoint = await pointsRef
      .where('motivo', '==', PRECO_INICIAL_MOTIVO)
      .limit(1)
      .get();

    if (!existingInitialPoint.empty) {
      skippedExistingInitialPointCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} ja possui ponto inicial de historico.`
      );
      continue;
    }

    await initialPointRef.set({
      startupId: startupDoc.id,
      precoCentavos: precoTokenAtualCentavos,
      motivo: PRECO_INICIAL_MOTIVO,
      createdAt: FieldValue.serverTimestamp(),
    });

    createdCount += 1;
    console.log(`[CRIADO] ${startupLabel} recebeu ponto PRECO_INICIAL.`);
  }

  console.log('');
  console.log('[seed:price-history] Resumo final:');
  console.log(`- startups encontradas: ${startupsSnapshot.size}`);
  console.log(`- pontos iniciais criados: ${createdCount}`);
  console.log(
    `- startups ignoradas (ja tinham ponto inicial): ${skippedExistingInitialPointCount}`
  );
  console.log(
    `- startups ignoradas (preco invalido): ${skippedInvalidPriceCount}`
  );
  console.log('[seed:price-history] Seed concluido com sucesso.');
}

seedPriceHistory()
  .then(() => process.exit(0))
  .catch((error: unknown) => {
    console.error('[seed:price-history] Erro durante a execucao:', error);
    process.exit(1);
  });
