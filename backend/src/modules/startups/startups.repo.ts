import { Timestamp } from "firebase-admin/firestore";

import { FirestoreBaseRepo } from "../../infra/repositories/firestore.base.repo";
import { getDb } from "../../config/firebase";
import { resolvePreferredStartupCanonicalIdByName } from "./startup-canonical-id-policy";
import { Startup } from "./startups.modal";

type StartupDoc = Record<string, unknown> & { id: string };

export interface StartupPriceHistoryPoint {
  id: string;
  startupId: string;
  precoCentavos: number;
  motivo: string;
  createdAt: unknown;
}

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
    const group = this.findGroupByAnyId(docs, id);
    if (!group) {
      return null;
    }

    return this.mergeStartupGroup(group);
  }

  async resolveCanonicalId(id: string): Promise<string | null> {
    const docs = await this.listStartupDocs();
    const group = this.findGroupByAnyId(docs, id);
    if (!group) {
      return null;
    }

    return this.selectCanonicalDoc(group).id;
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

  private findGroupByAnyId(docs: StartupDoc[], id: string): StartupDoc[] | null {
    const normalizedId = this.normalizeId(id);
    if (normalizedId.length === 0) {
      return null;
    }

    for (const group of this.groupStartupDocs(docs).values()) {
      if (
        group.some((doc) => this.normalizeId(doc.id) === normalizedId)
      ) {
        return group;
      }
    }

    return null;
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
    const canonical = this.selectCanonicalDoc(group, ordered);
    const totalTokens =
      this.pickNumber(ordered, "totalTokens", { positiveOnly: true }) ??
      this.pickNumber(ordered, "totalTokens") ??
      0;
    const tokensDisponiveis = this.resolveTokensDisponiveis(ordered, totalTokens);
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
      id: canonical.id,
      aliasIds: this.buildAliasIds(canonical.id, ordered),
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

  private selectCanonicalDoc(
    group: StartupDoc[],
    orderedGroup?: StartupDoc[],
  ): StartupDoc {
    const ordered =
      orderedGroup ?? [...group].sort((a, b) => this.compareCandidates(a, b));
    const preferredCanonicalId = resolvePreferredStartupCanonicalIdByName(
      this.pickText(ordered, ["nome"]),
    );

    if (preferredCanonicalId) {
      const preferredDoc = ordered.find((doc) => doc.id === preferredCanonicalId);
      if (preferredDoc) {
        return preferredDoc;
      }
    }

    return ordered[0];
  }

  private buildAliasIds(canonicalId: string, group: StartupDoc[]): string[] {
    const aliases = new Set<string>();
    const normalizedCanonicalId = this.normalizeId(canonicalId);

    if (normalizedCanonicalId.length > 0) {
      aliases.add(canonicalId);
    }

    for (const doc of group) {
      const normalizedId = this.normalizeId(doc.id);
      if (normalizedId.length === 0) {
        continue;
      }

      if (normalizedId === normalizedCanonicalId) {
        continue;
      }

      aliases.add(doc.id);
    }

    return [...aliases];
  }

  private resolveTokensDisponiveis(
    candidates: StartupDoc[],
    totalTokens: number,
  ): number {
    const values = candidates
      .map((candidate) => candidate.tokensDisponiveis)
      .filter((value): value is number => this.isFiniteNumber(value))
      .filter((value) => value >= 0)
      .map((value) => (totalTokens > 0 ? Math.min(value, totalTokens) : value));

    if (values.length === 0) {
      return totalTokens;
    }

    return Math.min(...values);
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
    const totalTokens = this.isPositiveNumber(doc.totalTokens)
      ? doc.totalTokens
      : undefined;
    const tokensDisponiveis = this.isNonNegativeNumber(doc.tokensDisponiveis)
      ? doc.tokensDisponiveis
      : undefined;
    const precoTokenInicialCentavos = this.isPositiveNumber(
      doc.precoTokenInicialCentavos,
    )
      ? doc.precoTokenInicialCentavos
      : undefined;
    const precoTokenAtualCentavos = this.isPositiveNumber(
      doc.precoTokenAtualCentavos,
    )
      ? doc.precoTokenAtualCentavos
      : undefined;

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
    if (totalTokens !== undefined) score += 25;
    if (tokensDisponiveis !== undefined) score += 30;
    if (precoTokenInicialCentavos !== undefined) score += 20;
    if (precoTokenAtualCentavos !== undefined) score += 25;
    if (this.hasNonEmptyArray(doc.socios)) score += 10;
    if (this.hasNonEmptyArray(doc.conselho)) score += 6;
    if (this.hasNonEmptyArray(doc.mentores)) score += 6;
    if (this.hasNonEmptyArray(doc.videos)) score += 4;
    if (this.hasNonEmptyArray(doc.atualizacoes)) score += 4;
    if (this.timestampMillis(doc.updatedAt) > 0) score += 5;
    if (this.timestampMillis(doc.ultimaAtualizacaoPrecoAt) > 0) score += 8;

    // Um documento que já reflete emissão/recompra real de tokens deve ganhar
    // prioridade sobre uma duplicata seedada ainda "pristina".
    if (
      totalTokens !== undefined &&
      tokensDisponiveis !== undefined &&
      tokensDisponiveis < totalTokens
    ) {
      score += 60;
    }

    // Variação de preço também indica que este documento está participando do
    // fluxo real de negociação, não apenas armazenando a seed inicial.
    if (
      precoTokenInicialCentavos !== undefined &&
      precoTokenAtualCentavos !== undefined &&
      precoTokenAtualCentavos !== precoTokenInicialCentavos
    ) {
      score += 20;
    }

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

    return value
      .trim()
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/\s+/g, " ");
  }

  private normalizeId(value: unknown): string {
    if (!this.isNonEmptyString(value)) {
      return "";
    }

    return value.trim();
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

  async findPriceHistory(
    startupId: string,
    limit = 365,
  ): Promise<StartupPriceHistoryPoint[]> {
    const docs = await this.listStartupDocs();
    const group = this.findGroupByAnyId(docs, startupId);
    const startupIds = group
      ? this.buildAliasIds(this.selectCanonicalDoc(group).id, group)
      : [startupId.trim()].filter((id) => id.length > 0);
    const db = getDb();
    const snapshots = await Promise.all(
      startupIds.map((id) =>
        db
          .collection("priceHistory")
          .doc(id)
          .collection("points")
          .orderBy("createdAt", "asc")
          .limit(limit)
          .get(),
      ),
    );

    return snapshots
      .flatMap((snapshot) =>
        snapshot.docs.map((doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            startupId:
              typeof data.startupId === "string" && data.startupId.trim() !== ""
                ? data.startupId
                : startupId,
            precoCentavos:
              typeof data.precoCentavos === "number" ? data.precoCentavos : 0,
            motivo: typeof data.motivo === "string" ? data.motivo : "",
            createdAt: data.createdAt,
          };
        }),
      )
      .sort((a, b) => {
        const createdAtDifference =
          this.timestampMillis(a.createdAt) - this.timestampMillis(b.createdAt);
        if (createdAtDifference !== 0) {
          return createdAtDifference;
        }

        const startupIdDifference = a.startupId.localeCompare(b.startupId);
        if (startupIdDifference !== 0) {
          return startupIdDifference;
        }

        return a.id.localeCompare(b.id);
      })
      .slice(0, limit);
  }
}
