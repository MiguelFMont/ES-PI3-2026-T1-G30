import { Timestamp } from "firebase-admin/firestore";

import { FirestoreBaseRepo } from "../../infra/repositories/firestore.base.repo";
import { getDb } from "../../config/firebase";
import { Startup } from "./startups.modal";

type StartupDoc = Record<string, unknown> & { id: string };

export class StartupsRepo extends FirestoreBaseRepo {
  constructor() {
    super("startups");
  }

  async findAllDeduplicated(): Promise<Startup[]> {
    return this.deduplicate(await this.listStartupDocs());
  }

  async findByEstagio(estagio: string): Promise<Startup[]> {
    return (await this.findAllDeduplicated()).filter(
      (startup) => startup.estagio === estagio,
    );
  }

  async findByIdMerged(id: string): Promise<Startup | null> {
    const docs = await this.listStartupDocs();
    if (!docs.some((doc) => doc.id === id)) {
      return null;
    }

    for (const group of this.groupStartupDocs(docs).values()) {
      if (group.some((doc) => doc.id === id)) {
        return this.mergeStartupGroup(group);
      }
    }

    return null;
  }

  private async listStartupDocs(): Promise<StartupDoc[]> {
    const snapshot = await getDb().collection("startups").get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as Record<string, unknown>),
    }));
  }

  private deduplicate(docs: StartupDoc[]): Startup[] {
    return [...this.groupStartupDocs(docs).values()].map((group) =>
      this.mergeStartupGroup(group),
    );
  }

  private groupStartupDocs(docs: StartupDoc[]) {
    const groups = new Map<string, StartupDoc[]>();

    for (const doc of docs) {
      const key = this.getGroupKey(doc);
      groups.set(key, [...(groups.get(key) ?? []), doc]);
    }

    return groups;
  }

  private getGroupKey(doc: StartupDoc): string {
    const normalizedName = this.normalizeText(doc.nome);
    if (normalizedName.length > 0) {
      return normalizedName;
    }

    const normalizedDescription = this.normalizeText(doc.descricao);
    if (normalizedDescription.length > 0) {
      return normalizedDescription;
    }

    return `id:${doc.id}`;
  }

  private mergeStartupGroup(group: StartupDoc[]): Startup {
    const ordered = [...group].sort((a, b) => this.compareCandidates(a, b));
    const base = ordered[0];
    const totalTokens =
      this.pickNumber(ordered, "totalTokens", { positiveOnly: true }) ??
      this.pickNumber(ordered, "totalTokens") ??
      0;
    const tokensDisponiveisRaw =
      this.pickNumber(ordered, "tokensDisponiveis") ?? totalTokens;
    const tokensDisponiveis =
      totalTokens > 0
        ? Math.min(tokensDisponiveisRaw, totalTokens)
        : tokensDisponiveisRaw;
    const precoTokenInicialCentavos =
      this.pickNumber(ordered, "precoTokenInicialCentavos", {
        positiveOnly: true,
      }) ?? 0;
    const precoTokenAtualCentavos =
      this.pickNumber(ordered, "precoTokenAtualCentavos", {
        positiveOnly: true,
      }) ?? precoTokenInicialCentavos;
    const createdAt =
      this.pickTimestamp(
        [...ordered].sort(
          (a, b) =>
            this.timestampMillis(a.createdAt) -
            this.timestampMillis(b.createdAt),
        ),
        "createdAt",
      ) ?? Timestamp.now();

    return {
      id: base.id,
      aliasIds: ordered.map((startup) => startup.id),
      nome: this.pickText(ordered, ["nome"]),
      logo: this.pickText(ordered, ["logo"]),
      descricao: this.pickText(ordered, ["descricao"]),
      estagio: this.pickStage(ordered),
      setor: this.pickText(ordered, ["setor"]),
      capitalAportado:
        this.pickNumber(ordered, "capitalAportado", {
          requireOwnField: true,
        }) ?? 0,
      totalTokens,
      tokensDisponiveis,
      precoTokenInicialCentavos,
      precoTokenAtualCentavos,
      resumoExecutivo: this.pickText(ordered, [
        "resumoExecutivo",
        "resumoExecutive",
      ]),
      socios: this.pickArray(ordered, "socios") as Startup["socios"],
      conselho: this.pickArray(ordered, "conselho") as Startup["conselho"],
      mentores: this.pickArray(ordered, "mentores") as Startup["mentores"],
      videos: this.pickArray(ordered, "videos") as Startup["videos"],
      atualizacoes: this.pickArray(
        ordered,
        "atualizacoes",
      ) as Startup["atualizacoes"],
      createdAt,
      updatedAt: this.pickTimestamp(ordered, "updatedAt"),
    };
  }

  private compareCandidates(a: StartupDoc, b: StartupDoc): number {
    const scoreDifference = this.scoreCandidate(b) - this.scoreCandidate(a);
    if (scoreDifference !== 0) {
      return scoreDifference;
    }

    const updatedDifference =
      this.timestampMillis(b.updatedAt) - this.timestampMillis(a.updatedAt);
    if (updatedDifference !== 0) {
      return updatedDifference;
    }

    const createdDifference =
      this.timestampMillis(b.createdAt) - this.timestampMillis(a.createdAt);
    if (createdDifference !== 0) {
      return createdDifference;
    }

    return a.id.localeCompare(b.id);
  }

  private scoreCandidate(doc: StartupDoc): number {
    let score = 0;

    if (this.isNonEmptyString(doc.nome)) score += 100;
    if (this.isNonEmptyString(doc.descricao)) score += 20;
    if (this.normalizeStage(doc.estagio) != null) score += 20;
    if (this.isNonEmptyString(doc.setor)) score += 10;
    if (this.isNonEmptyString(doc.logo)) score += 10;
    if (
      this.isNonEmptyString(doc.resumoExecutivo) ||
      this.isNonEmptyString(doc.resumoExecutive)
    ) {
      score += 18;
    }

    if (this.hasOwnField(doc, "capitalAportado")) score += 8;
    if (this.isPositiveNumber(doc.totalTokens)) score += 25;
    if (this.isNonNegativeNumber(doc.tokensDisponiveis)) score += 30;
    if (this.isPositiveNumber(doc.precoTokenInicialCentavos)) score += 20;
    if (this.isPositiveNumber(doc.precoTokenAtualCentavos)) score += 25;
    if (this.hasNonEmptyArray(doc.socios)) score += 10;
    if (this.hasNonEmptyArray(doc.conselho)) score += 6;
    if (this.hasNonEmptyArray(doc.mentores)) score += 6;
    if (this.hasNonEmptyArray(doc.videos)) score += 4;
    if (this.hasNonEmptyArray(doc.atualizacoes)) score += 4;
    if (this.timestampMillis(doc.updatedAt) > 0) score += 5;

    return score;
  }

  private pickText(candidates: StartupDoc[], fields: string[]): string {
    for (const field of fields) {
      for (const candidate of candidates) {
        const value = candidate[field];
        if (this.isNonEmptyString(value)) {
          return value.trim();
        }
      }
    }

    return "";
  }

  private pickNumber(
    candidates: StartupDoc[],
    field: string,
    options: { positiveOnly?: boolean; requireOwnField?: boolean } = {},
  ): number | undefined {
    const { positiveOnly = false, requireOwnField = false } = options;

    for (const candidate of candidates) {
      if (requireOwnField && !this.hasOwnField(candidate, field)) {
        continue;
      }

      const value = candidate[field];
      if (!this.isFiniteNumber(value)) {
        continue;
      }

      if (positiveOnly && value <= 0) {
        continue;
      }

      if (!positiveOnly && value < 0) {
        continue;
      }

      return value;
    }

    return undefined;
  }

  private pickArray(candidates: StartupDoc[], field: string): unknown[] {
    for (const candidate of candidates) {
      const value = candidate[field];
      if (Array.isArray(value) && value.length > 0) {
        return value;
      }
    }

    return [];
  }

  private pickStage(candidates: StartupDoc[]): Startup["estagio"] {
    for (const candidate of candidates) {
      const stage = this.normalizeStage(candidate.estagio);
      if (stage != null) {
        return stage;
      }
    }

    return "Nova";
  }

  private pickTimestamp(
    candidates: StartupDoc[],
    field: string,
  ): Timestamp | undefined {
    for (const candidate of candidates) {
      const value = candidate[field];
      if (value instanceof Timestamp) {
        return value;
      }
    }

    return undefined;
  }

  private normalizeStage(value: unknown): Startup["estagio"] | undefined {
    if (value === "Nova") return "Nova";
    if (value === "Em Operação" || value === "Em Operacao") {
      return "Em Operação";
    }
    if (value === "Em Expansão" || value === "Em Expansao") {
      return "Em Expansão";
    }

    return undefined;
  }

  private timestampMillis(value: unknown): number {
    if (value instanceof Timestamp) {
      return value.toMillis();
    }

    return 0;
  }

  private normalizeText(value: unknown): string {
    if (!this.isNonEmptyString(value)) {
      return "";
    }

    return value.trim().toLowerCase().replace(/\s+/g, " ");
  }

  private hasOwnField(data: Record<string, unknown>, field: string): boolean {
    return Object.prototype.hasOwnProperty.call(data, field);
  }

  private hasNonEmptyArray(value: unknown): value is unknown[] {
    return Array.isArray(value) && value.length > 0;
  }

  private isFiniteNumber(value: unknown): value is number {
    return typeof value === "number" && Number.isFinite(value);
  }

  private isPositiveNumber(value: unknown): value is number {
    return this.isFiniteNumber(value) && value > 0;
  }

  private isNonNegativeNumber(value: unknown): value is number {
    return this.isFiniteNumber(value) && value >= 0;
  }

  private isNonEmptyString(value: unknown): value is string {
    return typeof value === "string" && value.trim().length > 0;
  }
}
