/// Result of analysing a piece of text.
class SentimentResult {
  /// A number from -1.0 (very negative) to +1.0 (very positive).
  final double score;

  /// "positive", "neutral" or "negative".
  final String label;

  const SentimentResult(this.score, this.label);
}

/// A small, offline sentiment analyser (no internet, no extra packages).
///
/// How it works:
/// 1. Split the text into lowercase words.
/// 2. Look each word up in a list of words with scores (good = +2, terrible = -3).
/// 3. If "not", "never", "didn't" and similar come in the two words before,
///    flip the score ("not happy" becomes negative).
/// 4. If "very", "really" and similar come before, make the score stronger.
/// 5. Add everything up and squash the total into the range -1 to +1.
class SentimentService {
  static const Map<String, int> _words = {
    "good": 2,
    "great": 3,
    "amazing": 4,
    "awesome": 4,
    "excellent": 3,
    "fantastic": 4,
    "wonderful": 4,
    "happy": 3,
    "glad": 3,
    "joy": 3,
    "joyful": 3,
    "excited": 3,
    "proud": 3,
    "productive": 2,
    "successful": 3,
    "success": 3,
    "love": 3,
    "loved": 3,
    "enjoy": 2,
    "enjoyed": 2,
    "fun": 2,
    "calm": 2,
    "peaceful": 2,
    "relaxed": 2,
    "grateful": 3,
    "thankful": 3,
    "blessed": 3,
    "motivated": 2,
    "energetic": 2,
    "confident": 2,
    "hopeful": 2,
    "optimistic": 2,
    "better": 2,
    "best": 3,
    "nice": 2,
    "fine": 1,
    "smooth": 2,
    "easy": 1,
    "win": 3,
    "won": 3,
    "achieved": 3,
    "accomplished": 3,
    "finished": 2,
    "completed": 2,
    "progress": 2,
    "improved": 2,
    "satisfied": 2,
    "content": 2,
    "delighted": 3,
    "thrilled": 4,
    "refreshed": 2,
    "rested": 2,
    "comfortable": 2,
    "lucky": 2,
    "inspired": 3,
    "focused": 2,
    "strong": 2,
    "healthy": 2,
    "beautiful": 3,
    "perfect": 3,
    "smile": 2,
    "smiled": 2,
    "laughed": 2,
    "cheerful": 3,
    "positive": 2,
    "relieved": 2,
    "welcome": 1,
    "helpful": 2,
    "kind": 2,
    "learned": 2,
    "fulfilled": 3,
    "organized": 2,
    "calmer": 2,
    "bad": -2,
    "terrible": -3,
    "awful": -3,
    "horrible": -3,
    "sad": -2,
    "unhappy": -2,
    "depressed": -3,
    "angry": -3,
    "upset": -2,
    "frustrated": -2,
    "frustrating": -2,
    "annoyed": -2,
    "annoying": -2,
    "stressed": -2,
    "stressful": -2,
    "anxious": -2,
    "worried": -2,
    "worry": -2,
    "nervous": -1,
    "afraid": -2,
    "scared": -2,
    "tired": -1,
    "exhausted": -2,
    "drained": -2,
    "sick": -2,
    "ill": -2,
    "pain": -2,
    "hurt": -2,
    "lonely": -2,
    "bored": -1,
    "boring": -1,
    "stuck": -1,
    "lazy": -1,
    "unproductive": -2,
    "failed": -3,
    "fail": -2,
    "failure": -3,
    "lost": -2,
    "lose": -2,
    "hate": -3,
    "hated": -3,
    "difficult": -1,
    "tough": -1,
    "struggle": -2,
    "struggled": -2,
    "struggling": -2,
    "overwhelmed": -2,
    "overwhelming": -2,
    "miserable": -3,
    "disappointed": -2,
    "disappointing": -2,
    "regret": -2,
    "guilty": -2,
    "ashamed": -2,
    "mess": -2,
    "problem": -1,
    "problems": -1,
    "waste": -2,
    "wasted": -2,
    "late": -1,
    "worst": -3,
    "worse": -2,
    "poor": -2,
    "rough": -1,
    "cry": -2,
    "cried": -2,
    "crying": -2,
    "conflict": -2,
    "argument": -2,
    "fight": -2,
    "fought": -2,
    "confused": -1,
    "unmotivated": -2,
    "helpless": -2,
    "hopeless": -3,
    "useless": -2,
    "panic": -3,
    "fear": -2,
    "burnout": -3,
    "burnt": -2,
    "headache": -2,
    "distracted": -1,
    "procrastinated": -2,
  };

  static const Set<String> _negations = {
    "not",
    "no",
    "never",
    "don't",
    "dont",
    "didn't",
    "didnt",
    "doesn't",
    "doesnt",
    "wasn't",
    "wasnt",
    "isn't",
    "isnt",
    "can't",
    "cant",
    "couldn't",
    "couldnt",
    "won't",
    "wont",
    "wouldn't",
    "wouldnt",
    "aren't",
    "arent",
    "weren't",
    "werent",
    "haven't",
    "havent",
    "hadn't",
    "hadnt",
    "hardly",
    "barely",
    "without",
    "nothing",
  };

  static const Map<String, double> _boosters = {
    "very": 1.5,
    "really": 1.5,
    "extremely": 2.0,
    "so": 1.3,
    "super": 1.5,
    "totally": 1.5,
    "absolutely": 1.8,
    "quite": 1.2,
    "incredibly": 1.8,
    "pretty": 1.2,
    "slightly": 0.5,
    "bit": 0.7,
    "somewhat": 0.7,
  };

  static SentimentResult analyze(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll('\u2019', "'")
        .replaceAll(RegExp(r"[^a-z' ]"), ' ');
    final tokens =
        cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    double sum = 0;
    for (int i = 0; i < tokens.length; i++) {
      final base = _words[tokens[i]];
      if (base == null) continue;

      double value = base.toDouble();
      bool negated = false;
      double boost = 1.0;

      // Look at up to two words before this one.
      for (int j = i - 1; j >= 0 && j >= i - 2; j--) {
        final previous = tokens[j];
        if (_negations.contains(previous)) {
          negated = !negated;
        } else if (_boosters.containsKey(previous)) {
          boost *= _boosters[previous]!;
        }
      }

      value *= boost;
      if (negated) value = -value * 0.75;
      sum += value;
    }

    final score = sum / (sum.abs() + 4);
    String label = 'neutral';
    if (score > 0.2) label = 'positive';
    if (score < -0.2) label = 'negative';
    return SentimentResult(score, label);
  }
}
