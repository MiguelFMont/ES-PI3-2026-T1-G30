String resolveStartupLogoSource({
  required String startupId,
  required String startupName,
  String? fallbackLogo,
}) {
  final normalizedId = _normalizeStartupKey(startupId);
  final normalizedName = _normalizeStartupKey(startupName);

  final assetPath =
      _startupLogoAssetsByKey[normalizedId] ??
      _startupLogoAssetsByKey[normalizedName];

  if (assetPath != null) {
    return assetPath;
  }

  return (fallbackLogo ?? '').trim();
}

bool isStartupLogoAsset(String source) {
  return source.trim().startsWith('assets/');
}

const Map<String, String> _startupLogoAssetsByKey = {
  'agroia': 'assets/images/startups/AgroIA.png',
  'medfacil': 'assets/images/startups/MedFacil.png',
  'edublocks': 'assets/images/startups/EduBlocks.png',
  'fintrack': 'assets/images/startups/FinTrack.png',
  'greenroute': 'assets/images/startups/GreenRoute.png',
};

String _normalizeStartupKey(String value) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  final buffer = StringBuffer();
  final normalized = value.trim().toLowerCase();

  for (final rune in normalized.runes) {
    final char = String.fromCharCode(rune);
    final replaced = replacements[char] ?? char;

    if (RegExp(r'[a-z0-9]').hasMatch(replaced)) {
      buffer.write(replaced);
    }
  }

  return buffer.toString();
}
