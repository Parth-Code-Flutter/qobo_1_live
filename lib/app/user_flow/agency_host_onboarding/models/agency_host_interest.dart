/// Host interest / talent category for agency onboarding.
enum AgencyHostInterest {
  singing('Singing', 'singing'),
  dancing('Dancing', 'dancing'),
  gaming('Gaming', 'gaming'),
  chatting('Chatting', 'chatting');

  const AgencyHostInterest(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static AgencyHostInterest? fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in AgencyHostInterest.values) {
      if (item.apiValue == normalized || item.label.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }
}
