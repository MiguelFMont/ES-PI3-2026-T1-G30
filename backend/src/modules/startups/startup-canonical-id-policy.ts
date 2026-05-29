function normalizeText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toLowerCase();
}

// Overrides explícitos para casos em que o documento operacional real da startup
// não coincide com o slug gerado pela seed ou com outra duplicata legada.
const CANONICAL_STARTUP_IDS_BY_NAME = new Map<string, string>([
  ["agroia", "86BYDnK0eSN8KO4ZcUwo"],
  ["edublocks", "2uVWBr6xRSj14C9EzZeV"],
  ["greenroute", "yQztokqGuBicJXs2qLTh"],
  ["medfacil", "eu4VpNl8QoydlZchVgAK"],
  ["fintrack", "IVRNjoNeSXLwc5MUqYlG"],
]);

export function resolvePreferredStartupCanonicalIdByName(
  startupName: string,
): string | null {
  const normalizedName = normalizeText(startupName);
  if (normalizedName.length === 0) {
    return null;
  }

  return CANONICAL_STARTUP_IDS_BY_NAME.get(normalizedName) ?? null;
}
