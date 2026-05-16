/// Talent categories for agency host onboarding (client Req-3).
enum AgencyHostCategory {
  singing('Singing'),
  cooking('Cooking'),
  dancing('Dancing'),
  comedy('Comedy');

  const AgencyHostCategory(this.label);

  final String label;

  static AgencyHostCategory? fromLabel(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final item in AgencyHostCategory.values) {
      if (item.label.toLowerCase() == value.trim().toLowerCase()) {
        return item;
      }
    }
    return null;
  }
}
