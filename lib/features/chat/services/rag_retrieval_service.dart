import 'dart:math' as math;

import '../data/clinical_knowledge_base.dart';

class RetrievalHit {
  final KnowledgeChunk chunk;
  final double score;

  /// 0..1 monotone transform of [score]. Calibrated with the evaluation set
  /// (see test/rag_retrieval_test.dart); used only for gating, never as an
  /// answer.
  final double confidence;

  const RetrievalHit(this.chunk, this.score, this.confidence);
}

class RagRetrievalResult {
  final List<RetrievalHit> hits;
  const RagRetrievalResult(this.hits);

  static const empty = RagRetrievalResult([]);

  bool get hasEvidence => hits.isNotEmpty;
  KnowledgeChunk? get top => hits.isEmpty ? null : hits.first.chunk;
  double get confidence => hits.isEmpty ? 0.0 : hits.first.confidence;
}

/// Hybrid on-device retrieval over [ClinicalKnowledgeBase].
///
/// Pipeline: normalise and stem the query -> BM25 over weighted fields
/// (title/tags/keywords/body) + concept-lexicon overlap (a lightweight
/// synonym layer so differently worded questions still match) + exact phrase
/// matches -> relevance threshold -> top results. If nothing is relevant, it
/// returns no evidence rather than a forced match.
///
/// This is deliberately NOT a neural-embedding retriever: that would need a
/// network call or a bundled model. See docs/nova_rag_and_security.md.
class RagRetrievalService {
  static const double minScore = 4.0;
  static const double secondaryRatio = 0.65;

  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'be', 'been', 'am',
    'to', 'in', 'on', 'at', 'by', 'for', 'with', 'about', 'from', 'up', 'down', 'of', 'off',
    'over', 'under', 'again', 'then', 'here', 'there', 'when', 'where', 'why', 'how', 'what',
    'which', 'who', 'whom', 'this', 'that', 'these', 'those', 'all', 'any', 'both', 'each',
    'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same',
    'so', 'than', 'too', 'very', 'can', 'will', 'just', 'should', 'now', 'i', 'me', 'my',
    'myself', 'we', 'our', 'you', 'your', 'he', 'she', 'it', 'its', 'they', 'them', 'their',
    'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'would', 'could', 'tell',
    'feel', 'feeling', 'feels', 'felt', 'really', 'much', 'lot', 'get', 'got', 'know', 'want',
    'need', 'like', 'make', 'go', 'going', 'thing', 'things', 'something', 'anything', 'one',
    'day', 'today', 'time', 'please', 'hi', 'hello', 'hey', 'nova', 'im', 'ive',
    'dont', 'cant', 'cannot', 'wont', 'if', 'as', 'while', 'also', 'keep', 'actually',
    'every', 'always', 'good', 'well', 'think', 'give', 'let', 'come', 'tomorrow', 'try',
    'help', 'tips', 'tip', 'lately', 'right', 'out', 'into', 'work',
  };

  /// Concept lexicon: surface forms that mean the same thing. Applied to both
  /// the query and to each chunk's title/tags/keywords.
  static const Map<String, List<String>> _concepts = {
    'anxiety': [
      'anxious', 'anxiety', 'panic', 'panicking', 'nervous', 'worried', 'worry', 'scared',
      'afraid', 'fear', 'freaking', 'stressed', 'stress', 'tense', 'edge', 'pounding',
      'racing', 'overwhelmed', 'overwhelm', 'jittery', 'dread', 'shaking', 'tight',
    ],
    'calming': ['calm', 'relax', 'relaxed', 'relaxing', 'soothe', 'settle', 'unwind', 'calming'],
    'breathing': ['breath', 'breathe', 'breathing', 'inhale', 'exhale', 'sigh', 'breathwork'],
    'grounding': [
      'ground', 'grounding', 'spiral', 'spiralling', 'spiraling', 'ruminate', 'rumination',
      'overthinking', 'intrusive', 'thoughts', 'thought', 'head', 'mind',
    ],
    'hrv': ['hrv', 'rmssd', 'variability', 'vagal', 'vagus', 'parasympathetic'],
    'heart': ['heart', 'pulse', 'bpm', 'heartbeat'],
    'eeg': ['eeg', 'brainwave', 'brainwaves', 'alpha', 'beta', 'theta', 'delta', 'gamma', 'frequency', 'frequencies', 'wave', 'waves'],
    'artifact': ['blink', 'blinking', 'artifact', 'artefact', 'clench', 'muscle', 'jaw', 'inaccurate', 'drift', 'highest', 'dominant'],
    'lowmood': [
      'sad', 'unmotivated', 'depressed', 'depression', 'blue', 'hopeless', 'empty', 'lonely',
      'flat', 'numb', 'energy', 'motivation', 'activation', 'gloomy', 'low', 'unhappy',
    ],
    'sleep': ['sleep', 'asleep', 'insomnia', 'bed', 'bedtime', 'night', 'waking', 'awake', 'tired', 'nap', 'drowsy'],
    'audio': [
      'rain', 'sound', 'sounds', 'noise', 'binaural', 'beats', 'music', 'soundscape',
      'ambient', 'listening', 'isochronic', 'lofi', 'piano',
    ],
    'focus': [
      'focus', 'concentrate', 'concentration', 'distracted', 'distraction', 'study', 'studying',
      'attention', 'adhd', 'procrastinate', 'procrastinating', 'productive',
    ],
    'professional': [
      'therapist', 'therapy', 'doctor', 'professional', 'counsellor', 'counselor', 'psychiatrist',
      'psychologist', 'treatment', 'diagnose', 'diagnosis', 'gp',
    ],
    'privacy': [
      'privacy', 'private', 'data', 'save', 'saved', 'store', 'stored', 'storage', 'delete',
      'deleted', 'recording', 'recordings', 'chats', 'history', 'share', 'shared', 'see', 'gdpr',
    ],
    'app': ['app', 'neuroshift', 'feature', 'features', 'connect', 'pair', 'bluetooth', 'headband', 'muse', 'session', 'sessions'],
    'identity': ['real', 'human', 'robot', 'bot', 'ai', 'trust'],
    'state': ['classify', 'classification', 'decide', 'neutral', 'active', 'state'],
  };

  // ------------------------------------------------------------------ index
  static _Index? _index;
  static _Index get _idx => _index ??= _Index.build();

  /// Retrieve at most [maxResults] relevant chunks. [categories] optionally
  /// restricts results (for example only 'app' chunks).
  static RagRetrievalResult retrieve(
    String query, {
    int maxResults = 2,
    Set<String>? categories,
    double? minScoreOverride,
  }) {
    final qTokens = tokenize(query);
    if (qTokens.isEmpty) return RagRetrievalResult.empty;
    final qNorm = ' ${normalize(query)} ';
    final qConcepts = _conceptsOf(qTokens);

    final idx = _idx;
    final scored = <MapEntry<_Doc, double>>[];

    for (final doc in idx.docs) {
      if (categories != null && !categories.contains(doc.chunk.category)) continue;

      double bm25 = 0;
      bool strong = false;
      for (final t in qTokens.toSet()) {
        final tf = doc.tf[t] ?? 0;
        if (tf == 0) continue;
        final idf = idx.idf(t);
        final norm = tf * (_k1 + 1) / (tf + _k1 * (1 - _b + _b * doc.length / idx.avgLen));
        bm25 += idf * norm;
        if (doc.strongTokens.contains(t) && idf >= 0.9) strong = true;
      }

      int phraseHits = 0;
      for (final p in doc.phrases) {
        if (qNorm.contains(' $p ')) phraseHits += p.contains(' ') ? 2 : 1;
      }
      final overlap = qConcepts.intersection(doc.concepts).length;
      if (phraseHits > 0 || overlap > 0) strong = true;

      final score = bm25 + 2.5 * math.min(overlap, 3) + 4.0 * math.min(phraseHits, 3);
      if (strong) scored.add(MapEntry(doc, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final threshold = minScoreOverride ?? minScore;
    if (scored.isEmpty || scored.first.value < threshold) return RagRetrievalResult.empty;

    final top = scored.first.value;
    final hits = <RetrievalHit>[];
    for (final e in scored) {
      if (hits.length >= maxResults) break;
      if (e.value < threshold || e.value < top * secondaryRatio) break;
      hits.add(RetrievalHit(e.key.chunk, e.value, e.value / (e.value + 6.0)));
    }
    return RagRetrievalResult(hits);
  }

  // ------------------------------------------------------------ text utils
  static const double _k1 = 1.4;
  static const double _b = 0.6;

  static String normalize(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll('\u2019', '').replaceAll("'", '').replaceAll('\u2018', '');
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> tokenize(String s) {
    final out = <String>[];
    for (final w in normalize(s).split(' ')) {
      if (w.isEmpty) continue;
      if (_stopWords.contains(w)) continue;
      if (w.length == 1 && !RegExp(r'\d').hasMatch(w)) continue;
      out.add(stem(w));
    }
    return out;
  }

  static String stem(String w) {
    if (w.length <= 3) return w;
    if (w.endsWith('ies') && w.length > 4) return '${w.substring(0, w.length - 3)}y';
    if (w.endsWith('sses')) return w.substring(0, w.length - 2);
    if (w.endsWith('ing') && w.length > 5) {
      final base = w.substring(0, w.length - 3);
      return _dedupeTail(base);
    }
    if (w.endsWith('ed') && w.length > 4) return _dedupeTail(w.substring(0, w.length - 2));
    if (w.endsWith('es') && w.length > 4) return w.substring(0, w.length - 2);
    if (w.endsWith('s') && !w.endsWith('ss') && !w.endsWith('us') && w.length > 3) {
      return w.substring(0, w.length - 1);
    }
    if (w.endsWith('e') && w.length > 4) return w.substring(0, w.length - 1);
    return w;
  }

  static String _dedupeTail(String b) {
    if (b.length > 3 && b[b.length - 1] == b[b.length - 2] && !'lsz'.contains(b[b.length - 1])) {
      return b.substring(0, b.length - 1);
    }
    return b;
  }

  static Set<String> _conceptsOf(Iterable<String> stemmedTokens) {
    final set = stemmedTokens.toSet();
    final out = <String>{};
    _conceptStems.forEach((concept, stems) {
      if (stems.any(set.contains)) out.add(concept);
    });
    return out;
  }

  static final Map<String, Set<String>> _conceptStems = {
    for (final e in _concepts.entries) e.key: e.value.map((w) => stem(normalize(w))).toSet(),
  };
}

class _Doc {
  final KnowledgeChunk chunk;
  final Map<String, double> tf;
  final double length;
  final Set<String> strongTokens;
  final List<String> phrases;
  final Set<String> concepts;
  _Doc(this.chunk, this.tf, this.length, this.strongTokens, this.phrases, this.concepts);
}

class _Index {
  final List<_Doc> docs;
  final double avgLen;
  final Map<String, int> df;
  _Index(this.docs, this.avgLen, this.df);

  double idf(String t) {
    final n = docs.length;
    final d = df[t] ?? 0;
    return math.log(1 + (n - d + 0.5) / (d + 0.5));
  }

  static _Index build() {
    final docs = <_Doc>[];
    final df = <String, int>{};
    double total = 0;
    for (final c in ClinicalKnowledgeBase.chunks) {
      if (c.category == 'crisis') continue;
      final tf = <String, double>{};
      void add(Iterable<String> tokens, double w) {
        for (final t in tokens) {
          tf[t] = (tf[t] ?? 0) + w;
        }
      }

      final titleT = RagRetrievalService.tokenize(c.title);
      final tagT = c.tags.expand(RagRetrievalService.tokenize).toList();
      final kwT = c.keywords.expand(RagRetrievalService.tokenize).toList();
      final bodyT = RagRetrievalService.tokenize('${c.summary} ${c.keyPoints.join(' ')}');
      add(titleT, 3);
      add(tagT, 3);
      add(kwT, 2);
      add(bodyT, 1);

      final strong = <String>{...titleT, ...tagT, ...kwT};
      final len = tf.values.fold<double>(0, (a, b) => a + b);
      total += len;
      for (final t in tf.keys) {
        df[t] = (df[t] ?? 0) + 1;
      }
      final phrases = [
        for (final k in c.keywords) RagRetrievalService.normalize(k),
        for (final t in c.tags) RagRetrievalService.normalize(t),
      ].where((p) => p.isNotEmpty).toSet().toList();
      final concepts = RagRetrievalService._conceptsOf(strong);
      docs.add(_Doc(c, tf, len, strong, phrases, concepts));
    }
    return _Index(docs, docs.isEmpty ? 1 : total / docs.length, df);
  }
}
