/**
 * Samuel Campovilla
 * Auditoria de startups duplicadas no Firestore.
 *
 * Como executar:
 *   npm run audit:duplicate-startups
 *
 * O script apenas lista grupos duplicados e sugere um documento canônico.
 * Nenhum dado é alterado.
 */

import { Timestamp } from "firebase-admin/firestore";

import { getDb } from "../src/config/firebase";
import { resolvePreferredStartupCanonicalIdByName } from "../src/modules/startups/startup-canonical-id-policy";

type StartupDoc = Record<string, unknown> & { id: string };

function normalizeText(value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    return "";
  }

  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ");
}

function groupKey(doc: StartupDoc): string {
  const normalizedName = normalizeText(doc.nome);
  if (normalizedName.length > 0) {
    return normalizedName;
  }

  const normalizedDescription = normalizeText(doc.descricao);
  if (normalizedDescription.length > 0) {
    return normalizedDescription;
  }

  return `id:${doc.id}`;
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

function hasNonEmptyArray(value: unknown): value is unknown[] {
  return Array.isArray(value) && value.length > 0;
}

function timestampMillis(value: unknown): number {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }

  return 0;
}

function scoreCandidate(doc: StartupDoc): number {
  let score = 0;
  const totalTokens =
    isFiniteNumber(doc.totalTokens) && doc.totalTokens > 0
      ? doc.totalTokens
      : undefined;
  const tokensDisponiveis =
    isFiniteNumber(doc.tokensDisponiveis) && doc.tokensDisponiveis >= 0
      ? doc.tokensDisponiveis
      : undefined;
  const precoTokenInicialCentavos =
    isFiniteNumber(doc.precoTokenInicialCentavos) &&
    doc.precoTokenInicialCentavos > 0
      ? doc.precoTokenInicialCentavos
      : undefined;
  const precoTokenAtualCentavos =
    isFiniteNumber(doc.precoTokenAtualCentavos) &&
    doc.precoTokenAtualCentavos > 0
      ? doc.precoTokenAtualCentavos
      : undefined;

  if (normalizeText(doc.nome).length > 0) score += 100;
  if (normalizeText(doc.descricao).length > 0) score += 20;
  if (normalizeText(doc.estagio).length > 0) score += 15;
  if (normalizeText(doc.setor).length > 0) score += 10;
  if (normalizeText(doc.logo).length > 0) score += 10;
  if (normalizeText(doc.resumoExecutivo).length > 0) score += 15;
  if (Object.prototype.hasOwnProperty.call(doc, "capitalAportado")) score += 8;
  if (totalTokens !== undefined) score += 25;
  if (tokensDisponiveis !== undefined) score += 30;
  if (precoTokenInicialCentavos !== undefined) score += 20;
  if (precoTokenAtualCentavos !== undefined) score += 25;
  if (hasNonEmptyArray(doc.socios)) score += 10;
  if (hasNonEmptyArray(doc.conselho)) score += 6;
  if (hasNonEmptyArray(doc.mentores)) score += 6;
  if (hasNonEmptyArray(doc.videos)) score += 4;
  if (hasNonEmptyArray(doc.atualizacoes)) score += 4;
  if (timestampMillis(doc.updatedAt) > 0) score += 5;
  if (timestampMillis(doc.ultimaAtualizacaoPrecoAt) > 0) score += 8;

  if (
    totalTokens !== undefined &&
    tokensDisponiveis !== undefined &&
    tokensDisponiveis < totalTokens
  ) {
    score += 60;
  }

  if (
    precoTokenInicialCentavos !== undefined &&
    precoTokenAtualCentavos !== undefined &&
    precoTokenAtualCentavos !== precoTokenInicialCentavos
  ) {
    score += 20;
  }

  return score;
}

function compareCandidates(a: StartupDoc, b: StartupDoc): number {
  const scoreDifference = scoreCandidate(b) - scoreCandidate(a);
  if (scoreDifference !== 0) {
    return scoreDifference;
  }

  const updatedDifference =
    timestampMillis(b.updatedAt) - timestampMillis(a.updatedAt);
  if (updatedDifference !== 0) {
    return updatedDifference;
  }

  const createdDifference =
    timestampMillis(b.createdAt) - timestampMillis(a.createdAt);
  if (createdDifference !== 0) {
    return createdDifference;
  }

  return a.id.localeCompare(b.id);
}

function selectCanonicalDoc(group: StartupDoc[]): StartupDoc {
  const ordered = [...group].sort(compareCandidates);
  const preferredCanonicalId = resolvePreferredStartupCanonicalIdByName(
    typeof ordered[0]?.nome === "string" ? ordered[0].nome : "",
  );

  if (preferredCanonicalId) {
    const preferredDoc = ordered.find((doc) => doc.id === preferredCanonicalId);
    if (preferredDoc) {
      return preferredDoc;
    }
  }

  return ordered[0];
}

function formatTimestamp(value: unknown): string {
  if (!(value instanceof Timestamp)) {
    return "-";
  }

  return value.toDate().toISOString();
}

async function main(): Promise<void> {
  const db = getDb();
  const snapshot = await db.collection("startups").get();
  const docs = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Record<string, unknown>),
  }));

  const groups = new Map<string, StartupDoc[]>();
  for (const doc of docs) {
    const key = groupKey(doc);
    groups.set(key, [...(groups.get(key) ?? []), doc]);
  }

  const duplicateGroups = [...groups.values()]
    .filter((group) => group.length > 1);

  console.log(
    `[audit:duplicate-startups] startups encontradas: ${docs.length}`,
  );
  console.log(
    `[audit:duplicate-startups] grupos duplicados: ${duplicateGroups.length}`,
  );

  if (duplicateGroups.length === 0) {
    console.log("[audit:duplicate-startups] Nenhuma duplicata encontrada.");
    return;
  }

  for (const group of duplicateGroups) {
    const canonical = selectCanonicalDoc(group);
    const nome =
      typeof canonical.nome === "string" ? canonical.nome : canonical.id;

    console.log("");
    console.log(`[DUPLICADA] ${nome}`);
    console.log(`- documento canônico sugerido: ${canonical.id}`);

    for (const doc of [...group].sort(compareCandidates)) {
      console.log(
        `  - ${doc.id} | score=${scoreCandidate(doc)} | capital=${doc.capitalAportado ?? "-"} | total=${doc.totalTokens ?? "-"} | disponiveis=${doc.tokensDisponiveis ?? "-"} | precoAtual=${doc.precoTokenAtualCentavos ?? "-"} | updatedAt=${formatTimestamp(doc.updatedAt)}`,
      );
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error: unknown) => {
    console.error("[audit:duplicate-startups] Erro durante a execução:", error);
    process.exit(1);
  });
