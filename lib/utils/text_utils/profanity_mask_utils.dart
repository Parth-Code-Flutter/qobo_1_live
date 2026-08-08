import 'package:qobo_one_live/utils/text_utils/profanity_words.g.dart';

/// Masks abusive / profane words in free-form chat text with '*'.
///
/// Client requirement: users must not send abuse words in chat, in any
/// language. Any block-listed word is replaced by a run of '*' of the same
/// length, e.g. "you idiot" -> "you *****".
///
/// Coverage comes from a bundled multilingual dataset (see
/// `profanity_words.g.dart`, ~23 languages). Matching strategy:
/// - Latin-script words are matched on word boundaries (so "class" or
///   "assassin" are not affected) and tolerate simple letter-repeat evasion
///   for the common English set (e.g. "fuuuck").
/// - Non-Latin scripts (Hindi, Arabic, Chinese, Japanese, Korean, Thai,
///   Cyrillic, etc.) have no usable word boundaries, so they are matched as
///   substrings.
class ProfanityMaskUtils {
  ProfanityMaskUtils._();

  /// Common English set kept for letter-repeat (elongation) tolerance.
  static const List<String> _elongationWords = [
    'ass',
    'asshole',
    'bastard',
    'bitch',
    'bullshit',
    'cock',
    'cunt',
    'damn',
    'dick',
    'fuck',
    'fucker',
    'fucking',
    'motherfucker',
    'nigga',
    'nigger',
    'prick',
    'pussy',
    'shit',
    'slut',
    'whore',
  ];

  /// Curated supplement for common abuse/insults that the obscene-focused
  /// dataset misses, across languages. Latin entries are matched on word
  /// boundaries; non-Latin (e.g. Devanagari) as substrings.
  static const List<String> _supplementWords = [
    // English insults
    'idiot', 'idiots', 'stupid', 'moron', 'dumb', 'dumbass', 'jerk',
    'loser', 'scum', 'scumbag', 'imbecile', 'jackass', 'retard', 'retarded',
    'douche', 'douchebag', 'skank', 'bimbo', 'creep', 'freak', 'ugly',
    // Hindi / Hinglish (romanized)
    'gandu', 'gaandu', 'chutiya', 'chutiye', 'chutia', 'madarchod', 'madarchod',
    'behenchod', 'bhenchod', 'bhosdike', 'bhosadike', 'bhosda', 'harami',
    'haramzada', 'kamina', 'kamine', 'kutta', 'kutte', 'kutti', 'randi',
    'saala', 'saali', 'lund', 'lauda', 'gaand', 'gand', 'bsdk', 'mc', 'bc',
    'chodu', 'lavde', 'lawde', 'jhaant', 'tatti',
    // Hindi (Devanagari) - matched as substrings
    'गांडू', 'गाँडू', 'चूतिया', 'चुतिया', 'चूतिये', 'मादरचोद', 'भेनचोद',
    'बहनचोद', 'भोसडी', 'भोसड़ी', 'भोसडीके', 'रंडी', 'हरामी', 'कुत्ता',
    'कमीने', 'कमीना', 'लंड', 'लौड़ा', 'गांड', 'गाँड', 'साला', 'साली',
  ];

  /// Words that the dataset over-blocks but are acceptable in this app's
  /// context (e.g. a dating app). Removed from the block set. Tune as needed.
  static const Set<String> _allowWords = {
    'sexy',
    'hot',
    'kiss',
    'kisses',
    'kissing',
  };

  static final RegExp _elongationPattern = _buildElongationPattern();
  static final RegExp _latinPattern = _buildLatinPattern();
  static final List<String> _nonLatinWords = _buildNonLatinWords();

  static final RegExp _latinToken = RegExp(r"^[a-z0-9][a-z0-9 .'\-]*[a-z0-9]$");
  static final RegExp _asciiLetter = RegExp(r'[A-Za-z]');

  static RegExp _buildElongationPattern() {
    final alternatives = _elongationWords.map((word) {
      final buffer = StringBuffer();
      for (final char in word.split('')) {
        buffer.write(RegExp.escape(char));
        buffer.write('+');
      }
      return buffer.toString();
    }).join('|');
    return RegExp(r'\b(?:' + alternatives + r')\b', caseSensitive: false);
  }

  static Iterable<String> _allWords() =>
      [...kProfanityWordsMultilingual, ..._supplementWords]
          .where((w) => !_allowWords.contains(w.toLowerCase()));

  static RegExp _buildLatinPattern() {
    final latin = _allWords()
        .where((w) => _latinToken.hasMatch(w))
        .toSet()
        .map(RegExp.escape)
        .toList();
    if (latin.isEmpty) {
      // Fallback so the pattern never matches everything.
      return RegExp(r'(?!x)x');
    }
    return RegExp(r'\b(?:' + latin.join('|') + r')\b', caseSensitive: false);
  }

  static List<String> _buildNonLatinWords() {
    // Anything that is not a clean latin token (other scripts or symbolic
    // entries) is matched as a substring.
    return _allWords()
        .where((w) => !_latinToken.hasMatch(w) && !_asciiLetter.hasMatch(w))
        .toSet()
        .toList();
  }

  static String mask(String input) {
    if (input.isEmpty) return input;
    var result = input;
    result = result.replaceAllMapped(
      _elongationPattern,
      (m) => '*' * m.group(0)!.length,
    );
    result = result.replaceAllMapped(
      _latinPattern,
      (m) => '*' * m.group(0)!.length,
    );
    result = _maskSubstrings(result, _nonLatinWords);
    return result;
  }

  /// Masks substring matches (used for non-Latin scripts that lack word
  /// boundaries). Case-insensitive; masks by UTF-16 code unit length.
  static String _maskSubstrings(String input, List<String> words) {
    if (words.isEmpty) return input;
    final lower = input.toLowerCase();
    final masked = List<String>.from(input.split(''));
    var touched = false;
    for (final word in words) {
      if (word.isEmpty) continue;
      var from = 0;
      while (true) {
        final idx = lower.indexOf(word, from);
        if (idx < 0) break;
        for (var i = idx; i < idx + word.length && i < masked.length; i++) {
          masked[i] = '*';
        }
        touched = true;
        from = idx + word.length;
      }
    }
    return touched ? masked.join('') : input;
  }
}
