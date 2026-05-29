export type StartupTokenomicsTarget = {
  totalTokens: number;
  capitalAportado: number;
};

type StartupIdentity = {
  nome: string;
  estagio?: string;
};

// A politica abaixo reduz a valuacao implicita das startups para um patamar
// mais coerente com o contexto academico da incubadora.
const STAGE_DEFAULT_TARGETS: Record<string, StartupTokenomicsTarget> = {
  "em expansao": {
    totalTokens: 20000,
    capitalAportado: 180000,
  },
  "em operacao": {
    totalTokens: 20000,
    capitalAportado: 150000,
  },
  // Startups novas ficam no intervalo de 1k a 4k tokens.
  // O padrao da fase "Nova" fica em 1k e casos especificos sobem por override nominal.
  nova: {
    totalTokens: 1000,
    capitalAportado: 8000,
  },
};

// Overrides nominais mantem as startups seedadas com tamanhos diferentes,
// sem espalhar estes numeros por varios scripts.
const STARTUP_TARGETS_BY_NAME = new Map<string, StartupTokenomicsTarget>([
  [
    "agroia",
    {
      totalTokens: 20000,
      capitalAportado: 180000,
    },
  ],
  [
    "medfacil",
    {
      totalTokens: 20000,
      capitalAportado: 140000,
    },
  ],
  [
    "fintrack",
    {
      totalTokens: 20000,
      capitalAportado: 160000,
    },
  ],
  [
    "edublocks",
    {
      totalTokens: 2000,
      capitalAportado: 15000,
    },
  ],
  [
    "greenroute",
    {
      totalTokens: 4000,
      capitalAportado: 24000,
    },
  ],
]);

function normalizeText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toLowerCase();
}

export function resolveStartupTokenomicsTarget(
  startup: StartupIdentity,
): StartupTokenomicsTarget {
  const normalizedName = normalizeText(startup.nome);
  const namedTarget = STARTUP_TARGETS_BY_NAME.get(normalizedName);

  if (namedTarget) {
    return namedTarget;
  }

  const normalizedStage = normalizeText(startup.estagio ?? "");
  const stageTarget = STAGE_DEFAULT_TARGETS[normalizedStage];

  if (stageTarget) {
    return stageTarget;
  }

  // Fallback conservador para nao deixar uma startup fora da politica.
  return {
    totalTokens: 20000,
    capitalAportado: 120000,
  };
}
