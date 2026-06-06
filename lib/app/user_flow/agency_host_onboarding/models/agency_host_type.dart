/// Host stream type for agency onboarding (audio vs video).
enum AgencyHostType {
  audio('Audio', 'audio'),
  video('Video', 'video');

  const AgencyHostType(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static AgencyHostType? fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in AgencyHostType.values) {
      if (item.apiValue == normalized || item.label.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }
}
