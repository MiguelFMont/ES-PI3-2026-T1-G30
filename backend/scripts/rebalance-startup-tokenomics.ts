/**
 * Samuel Campovilla
 * Rebalanceia totalTokens e capitalAportado das startups existentes.
 *
 * Como executar:
 *   npm run rebalance:startup-tokenomics
 *
 * Requisitos:
 * - credenciais validas para o Firebase Admin SDK;
 * - acesso de escrita na colecao "startups".
 */

import { FieldValue } from "firebase-admin/firestore";
import { getDb } from "../src/config/firebase";
import { resolveStartupTokenomicsTarget } from "./lib/startup-tokenomics-policy";

type StartupDoc = {
  nome?: unknown;
  estagio?: unknown;
  totalTokens?: unknown;
  tokensDisponiveis?: unknown;
  capitalAportado?: unknown;
};

function asNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }

  return value.trim();
}

function asSafeInteger(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isSafeInteger(value)) {
    return null;
  }

  return value;
}

function formatStartupLabel(docId: string, data: StartupDoc): string {
  const nome = asNonEmptyString(data.nome) ?? "Startup sem nome";
  return `${nome} (${docId})`;
}

async function rebalanceStartupTokenomics(): Promise<void> {
  const db = getDb();
  const snapshot = await db.collection("startups").get();

  let updatedCount = 0;
  let skippedWithoutNameCount = 0;
  let skippedInvalidStateCount = 0;
  let skippedIssuedOverflowCount = 0;
  let skippedAlreadyBalancedCount = 0;

  console.log(
    `[rebalance:startup-tokenomics] ${snapshot.size} startup(s) encontrada(s).`,
  );

  for (const doc of snapshot.docs) {
    const data = doc.data() as StartupDoc;
    const startupLabel = formatStartupLabel(doc.id, data);
    const nome = asNonEmptyString(data.nome);

    if (!nome) {
      skippedWithoutNameCount += 1;
      console.log(`[IGNORADA] ${startupLabel} sem nome valido.`);
      continue;
    }

    const totalTokensAtual = asSafeInteger(data.totalTokens);
    const tokensDisponiveisAtuais = asSafeInteger(data.tokensDisponiveis);

    // O script preserva a quantidade ja emitida para nao apagar holdings reais.
    // Se o estado atual estiver corrompido, ele nao tenta "adivinhar" um novo saldo.
    if (
      totalTokensAtual === null ||
      tokensDisponiveisAtuais === null ||
      totalTokensAtual <= 0 ||
      tokensDisponiveisAtuais < 0 ||
      tokensDisponiveisAtuais > totalTokensAtual
    ) {
      skippedInvalidStateCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} com totalTokens/tokensDisponiveis invalidos.`,
      );
      continue;
    }

    const tokensJaEmitidos = totalTokensAtual - tokensDisponiveisAtuais;
    const target = resolveStartupTokenomicsTarget({
      nome,
      estagio: asNonEmptyString(data.estagio) ?? undefined,
    });

    // Se o banco ja tiver mais tokens emitidos do que o novo teto permite,
    // a atualizacao e bloqueada para nao deixar holdings acima de totalTokens.
    if (tokensJaEmitidos > target.totalTokens) {
      skippedIssuedOverflowCount += 1;
      console.log(
        `[IGNORADA] ${startupLabel} possui ${tokensJaEmitidos} token(s) emitido(s), acima do novo teto ${target.totalTokens}.`,
      );
      continue;
    }

    const tokensDisponiveisAtualizados = target.totalTokens - tokensJaEmitidos;
    const capitalAtual = asSafeInteger(data.capitalAportado);
    const needsUpdate =
      totalTokensAtual !== target.totalTokens ||
      tokensDisponiveisAtuais !== tokensDisponiveisAtualizados ||
      capitalAtual !== target.capitalAportado;

    if (!needsUpdate) {
      skippedAlreadyBalancedCount += 1;
      console.log(`[IGNORADA] ${startupLabel} ja segue a nova politica.`);
      continue;
    }

    await doc.ref.update({
      totalTokens: target.totalTokens,
      tokensDisponiveis: tokensDisponiveisAtualizados,
      capitalAportado: target.capitalAportado,
      updatedAt: FieldValue.serverTimestamp(),
    });

    updatedCount += 1;
    console.log(
      `[ATUALIZADA] ${startupLabel} -> totalTokens=${target.totalTokens}, tokensDisponiveis=${tokensDisponiveisAtualizados}, capitalAportado=${target.capitalAportado}.`,
    );
  }

  console.log("");
  console.log("[rebalance:startup-tokenomics] Resumo final:");
  console.log(`- startups encontradas: ${snapshot.size}`);
  console.log(`- startups atualizadas: ${updatedCount}`);
  console.log(`- startups ignoradas (sem nome): ${skippedWithoutNameCount}`);
  console.log(
    `- startups ignoradas (estado invalido): ${skippedInvalidStateCount}`,
  );
  console.log(
    `- startups ignoradas (tokens emitidos acima do novo teto): ${skippedIssuedOverflowCount}`,
  );
  console.log(
    `- startups ignoradas (ja balanceadas): ${skippedAlreadyBalancedCount}`,
  );
  console.log("[rebalance:startup-tokenomics] Script concluido com sucesso.");
}

rebalanceStartupTokenomics()
  .then(() => process.exit(0))
  .catch((error: unknown) => {
    console.error(
      "[rebalance:startup-tokenomics] Erro durante a execucao:",
      error,
    );
    process.exit(1);
  });
