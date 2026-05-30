/// Talent categories for agency host onboarding (client Req-3).
enum AgencyHostCategory {
  audio('Audio', 'audio'),
  video('Video', 'video');

  const AgencyHostCategory(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static AgencyHostCategory? fromLabel(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final item in AgencyHostCategory.values) {
      final normalized = value.trim().toLowerCase();
      if (item.label.toLowerCase() == normalized ||
          item.apiValue.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }
}
