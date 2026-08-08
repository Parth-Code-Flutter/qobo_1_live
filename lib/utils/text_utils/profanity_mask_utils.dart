/// Masks abusive / profane words in free-form chat text with '*'.
///
/// Client requirement: users must not send abuse words in chat. Any word from
/// the block list is replaced by a run of '*' of the same length, e.g.
/// "you idiot" -> "you *****". Matching is case-insensitive, on word
/// boundaries (so "assassin" or "class" are not affected), and tolerates
/// repeated letters used to evade filters (e.g. "fuuuck").
class ProfanityMaskUtils {
  ProfanityMaskUtils._();

  /// Base block list (lowercase). Extend as the client requests.
  static const List<String> _words = [
    'abuse',
    'arse',
    'ass',
    'asshole',
    'bastard',
    'bitch',
    'bloody',
    'bollocks',
    'boob',
    'bullshit',
    'chutiya',
    'crap',
    'cock',
    'cunt',
    'damn',
    'dick',
    'dickhead',
    'dumbass',
    'fag',
    'faggot',
    'fuck',
    'fucker',
    'fucking',
    'gandu',
    'gaand',
    'harami',
    'hell',
    'horny',
    'idiot',
    'jerk',
    'kutta',
    'kutti',
    'lund',
    'madarchod',
    'motherfucker',
    'nigga',
    'nigger',
    'penis',
    'prick',
    'pussy',
    'randi',
    'retard',
    'scumbag',
    'sex',
    'shit',
    'slut',
    'suar',
    'twat',
    'vagina',
    'wanker',
    'whore',
  ];

  /// One case-insensitive pattern that matches any block-listed word, allowing
  /// each letter to repeat (evasion like "shiiit") and requiring word
  /// boundaries so substrings inside clean words are left alone.
  static final RegExp _pattern = _buildPattern();

  static RegExp _buildPattern() {
    final alternatives = _words.map((word) {
      final buffer = StringBuffer();
      for (final char in word.split('')) {
        buffer.write(RegExp.escape(char));
        buffer.write('+');
      }
      return buffer.toString();
    }).join('|');
    return RegExp(r'\b(?:' + alternatives + r')\b', caseSensitive: false);
  }

  static String mask(String input) {
    if (input.isEmpty) return input;
    return input.replaceAllMapped(_pattern, (match) {
      return '*' * match.group(0)!.length;
    });
  }
}
