/**
 * Samuel Campovilla
 * Script para normalizar documentos da colecao wallets.
 *
 * Como executar:
 *   npm run fix:wallet-fields
 *   npm run fix:wallet-fields -- --apply
 *
 * Comportamento:
 * - por padrao roda em dry-run e apenas mostra o que seria alterado;
 * - com --apply persiste as correcoes no Firestore;
 * - corrige uid ausente/invalido usando o doc.id;
 * - corrige saldoCentavos ausente/invalido usando o campo legado saldo quando possivel;
 * - remove o campo legado saldo quando a carteira ja tem saldoCentavos valido;
 * - garante createdAt e updatedAt quando estiverem ausentes.
 *
 * Seguranca:
 * - se o script nao conseguir inferir um saldoCentavos valido, ele nao inventa saldo;
 * - nesses casos o documento fica marcado como "revisao manual".
 */

import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { getDb } from "../src/config/firebase";

type WalletDoc = {
  uid?: unknown;
  saldo?: unknown;
  saldoCentavos?: unknown;
  createdAt?: unknown;
  updatedAt?: unknown;
};

type PlannedUpdate = {
  docId: string;
  updateData: Record<string, unknown>;
  reasons: string[];
};

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function isValidTimestampLike(value: unknown): boolean {
  if (value instanceof Timestamp) {
    return true;
  }

  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return true;
  }

  if (typeof value !== "object" || value === null) {
    return false;
  }

  const maybeTimestamp = value as {
    toDate?: () => Date;
  };

  if (typeof maybeTimestamp.toDate !== "function") {
    return false;
  }

  const date = maybeTimestamp.toDate();
  return date instanceof Date && !Number.isNaN(date.getTime());
}

function parseNonNegativeInteger(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value) && value >= 0) {
    return value;
  }

  if (typeof value === "string" && /^[0-9]+$/.test(value.trim())) {
    const parsed = Number(value.trim());

    if (Number.isSafeInteger(parsed) && parsed >= 0) {
      return parsed;
    }
  }

  return null;
}

function formatWalletLabel(docId: string, data: WalletDoc): string {
  const uid = isNonEmptyString(data.uid) ? data.uid.trim() : "uid inválido";
  return `${docId} (uid salvo: ${uid})`;
}

function planWalletUpdate(docId: string, data: WalletDoc): PlannedUpdate | null {
  const updateData: Record<string, unknown> = {};
  const reasons: string[] = [];

  const normalizedUid = docId;
  if (!isNonEmptyString(data.uid) || data.uid.trim() !== normalizedUid) {
    updateData.uid = normalizedUid;
    reasons.push("uid normalizado para o id do documento");
  }

  const saldoCentavosAtual = parseNonNegativeInteger(data.saldoCentavos);
  const saldoLegado = parseNonNegativeInteger(data.saldo);

  if (saldoCentavosAtual === null) {
    if (saldoLegado !== null) {
      updateData.saldoCentavos = saldoLegado;
      reasons.push("saldoCentavos recuperado a partir do campo legado saldo");
    } else {
      return {
        docId,
        updateData: {},
        reasons: [
          "revisao manual: saldoCentavos ausente/invalido e saldo legado nao recuperavel",
        ],
      };
    }
  } else if (data.saldo !== undefined) {
    reasons.push("saldoCentavos ja estava valido");
  }

  if (data.saldo !== undefined) {
    updateData.saldo = FieldValue.delete();
    reasons.push("campo legado saldo removido");
  }

  if (!isValidTimestampLike(data.createdAt)) {
    if (isValidTimestampLike(data.updatedAt)) {
      updateData.createdAt = data.updatedAt;
      reasons.push("createdAt preenchido a partir de updatedAt existente");
    } else {
      updateData.createdAt = FieldValue.serverTimestamp();
      reasons.push("createdAt criado com serverTimestamp");
    }
  }

  if (!isValidTimestampLike(data.updatedAt)) {
    updateData.updatedAt = FieldValue.serverTimestamp();
    reasons.push("updatedAt criado com serverTimestamp");
  } else if (Object.keys(updateData).length > 0) {
    updateData.updatedAt = FieldValue.serverTimestamp();
    reasons.push("updatedAt renovado para registrar a normalizacao");
  }

  if (Object.keys(updateData).length === 0) {
    return null;
  }

  return {
    docId,
    updateData,
    reasons,
  };
}

async function fixWalletFields(): Promise<void> {
  const apply = process.argv.includes("--apply");
  const db = getDb();
  const snapshot = await db.collection("wallets").get();

  let updatedCount = 0;
  let cleanCount = 0;
  let manualReviewCount = 0;

  console.log(
    `[fix:wallet-fields] ${snapshot.size} wallet(s) encontrada(s). Modo: ${
      apply ? "apply" : "dry-run"
    }.`,
  );

  for (const doc of snapshot.docs) {
    const data = doc.data() as WalletDoc;
    const walletLabel = formatWalletLabel(doc.id, data);
    const plannedUpdate = planWalletUpdate(doc.id, data);

    if (!plannedUpdate) {
      cleanCount += 1;
      console.log(`[OK] ${walletLabel} ja esta consistente.`);
      continue;
    }

    if (plannedUpdate.reasons.length === 1 && plannedUpdate.updateData.saldo === undefined &&
        plannedUpdate.updateData.saldoCentavos === undefined &&
        plannedUpdate.reasons[0].startsWith("revisao manual:")) {
      manualReviewCount += 1;
      console.log(`[REVISAO MANUAL] ${walletLabel} -> ${plannedUpdate.reasons[0]}.`);
      continue;
    }

    const reasonText = plannedUpdate.reasons.join("; ");

    if (apply) {
      await doc.ref.set(plannedUpdate.updateData, { merge: true });
      updatedCount += 1;
      console.log(`[ATUALIZADA] ${walletLabel} -> ${reasonText}.`);
    } else {
      updatedCount += 1;
      console.log(`[DRY-RUN] ${walletLabel} -> ${reasonText}.`);
    }
  }

  console.log("");
  console.log("[fix:wallet-fields] Resumo final:");
  console.log(`- wallets encontradas: ${snapshot.size}`);
  console.log(`- wallets consistentes: ${cleanCount}`);
  console.log(`- wallets ${apply ? "atualizadas" : "que seriam atualizadas"}: ${updatedCount}`);
  console.log(`- wallets para revisao manual: ${manualReviewCount}`);
  console.log(
    `[fix:wallet-fields] ${apply ? "Correcao concluida." : "Dry-run concluido. Use --apply para persistir."}`,
  );
}

fixWalletFields()
  .then(() => process.exit(0))
  .catch((error: unknown) => {
    console.error("[fix:wallet-fields] Erro durante a execucao:", error);
    process.exit(1);
  });
