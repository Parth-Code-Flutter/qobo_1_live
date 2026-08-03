/// Maps ISO / dial-style country values to a flag emoji + short label.
class CountryFlagUtils {
  const CountryFlagUtils._();

  /// Returns (emoji, label) for a room/host country field, or null if unknown.
  static ({String emoji, String label})? resolve(String? raw) {
    final code = _normalizeToIso2(raw);
    if (code == null) return null;
    final emoji = _emojiForIso2(code);
    if (emoji == null) return null;
    return (emoji: emoji, label: code);
  }

  static String? _normalizeToIso2(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    if (value.toLowerCase() == 'global' || value.toLowerCase() == 'worldwide') {
      return null;
    }

    // Already ISO-2.
    if (RegExp(r'^[A-Za-z]{2}$').hasMatch(value)) {
      return value.toUpperCase();
    }

    // Dial code → ISO-2 (common set used in this app).
    final dial = value.startsWith('+') ? value : '+$value';
    const dialToIso = <String, String>{
      '+91': 'IN',
      '+1': 'US',
      '+44': 'GB',
      '+61': 'AU',
      '+81': 'JP',
      '+82': 'KR',
      '+86': 'CN',
      '+971': 'AE',
      '+966': 'SA',
      '+92': 'PK',
      '+880': 'BD',
      '+977': 'NP',
      '+94': 'LK',
      '+65': 'SG',
      '+60': 'MY',
      '+62': 'ID',
      '+66': 'TH',
      '+84': 'VN',
      '+63': 'PH',
      '+49': 'DE',
      '+33': 'FR',
      '+39': 'IT',
      '+34': 'ES',
      '+7': 'RU',
      '+55': 'BR',
      '+52': 'MX',
      '+27': 'ZA',
      '+234': 'NG',
      '+20': 'EG',
    };
    final fromDial = dialToIso[dial];
    if (fromDial != null) return fromDial;

    // Country name snippets (best-effort).
    final lower = value.toLowerCase();
    const nameToIso = <String, String>{
      'india': 'IN',
      'united states': 'US',
      'usa': 'US',
      'uk': 'GB',
      'united kingdom': 'GB',
      'bangladesh': 'BD',
      'pakistan': 'PK',
      'nepal': 'NP',
      'sri lanka': 'LK',
      'uae': 'AE',
      'united arab emirates': 'AE',
      'saudi': 'SA',
      'singapore': 'SG',
      'australia': 'AU',
      'japan': 'JP',
      'korea': 'KR',
      'china': 'CN',
    };
    for (final entry in nameToIso.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// ISO-3166 alpha-2 → regional-indicator flag emoji.
  static String? _emojiForIso2(String iso2) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(iso2)) return null;
    const base = 0x1F1E6; // Regional Indicator Symbol Letter A
    final a = base + (iso2.codeUnitAt(0) - 0x41);
    final b = base + (iso2.codeUnitAt(1) - 0x41);
    return String.fromCharCodes([a, b]);
  }
}
