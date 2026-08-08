/// Masks phone / mobile numbers inside free-form chat text with '*'.
///
/// Client requirement: users must not share mobile numbers in chat. Any run of
/// digits that looks like a phone number (optionally with a country code and
/// common separators like space, dash, dot or parentheses) has every digit
/// replaced by '*', while non-digit separators are preserved so the text still
/// reads naturally, e.g. "call 7070607060" -> "call **********".
class PhoneMaskUtils {
  PhoneMaskUtils._();

  /// Candidate phone-like runs: starts and ends with a digit, may contain the
  /// usual separators in between, optionally prefixed with '+'.
  static final RegExp _candidate = RegExp(r'\+?\d[\d\s\-().]{5,}\d');

  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _nonDigit = RegExp(r'\D');

  /// Minimum digits to treat a run as a phone number (avoids masking short
  /// numbers, prices, etc.). Maximum guards against masking unrelated long ids.
  static const int _minDigits = 7;
  static const int _maxDigits = 15;

  static String mask(String input) {
    if (input.isEmpty) return input;
    return input.replaceAllMapped(_candidate, (match) {
      final run = match.group(0)!;
      final digitCount = run.replaceAll(_nonDigit, '').length;
      if (digitCount < _minDigits || digitCount > _maxDigits) return run;
      return run.replaceAll(_digit, '*');
    });
  }
}
