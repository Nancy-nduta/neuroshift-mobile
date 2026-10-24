import 'dart:math' as math;
import '../data/clinical_knowledge_base.dart';
import '../../resources/models/resource_item.dart';

class RagRetrievalResult {
  final KnowledgeChunk topChunk;
  final List<KnowledgeChunk> secondaryChunks;
  final ResourceItem? recommendedResource;
  final List<String> suggestedChips;
  final double confidenceScore;
  final bool isCrisisQuery;

  const RagRetrievalResult({
    required this.topChunk,
    this.secondaryChunks = const [],
    this.recommendedResource,
    required this.suggestedChips,
    required this.confidenceScore,
    this.isCrisisQuery = false,
  });
}

class RagRetrievalService {
  /// Stop words that do not carry semantic weight in mental health queries
  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'to',
    'in', 'on', 'at', 'by', 'for', 'with', 'about', 'against', 'between',
    'into', 'through', 'during', 'before', 'after', 'above', 'below', 'from',
    'up', 'down', 'of', 'off', 'over', 'under', 'again', 'further', 'then',
    'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any',
    'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no',
    'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'can',
    'will', 'just', 'should', 'now', 'i', 'me', 'my', 'myself', 'we', 'our',
    'you', 'your', 'he', 'she', 'it', 'they', 'what', 'which', 'who', 'this',
    'that', 'these', 'those', 'am', 'been', 'being', 'have', 'has', 'had',
    'having', 'do', 'does', 'did', 'doing', 'would', 'could', 'tell'
  };

  /// Query the Clinical Knowledge Base and retrieve the most relevant neuro-clinical chunks
  static RagRetrievalResult retrieve(String query) {
    final lower = query.toLowerCase().trim();

    // 1. Immediate Crisis Detection Check (Highest Priority)
    final crisisChunk = ClinicalKnowledgeBase.chunks.firstWhere(
      (c) => c.id == 'rag_crisis_protocol',
      orElse: () => ClinicalKnowledgeBase.chunks.last,
    );
    for (final kw in crisisChunk.keywords) {
      if (lower.contains(kw)) {
        return RagRetrievalResult(
          topChunk: crisisChunk,
          suggestedChips: crisisChunk.followUpQuestions,
          confidenceScore: 1.0,
          isCrisisQuery: true,
        );
      }
    }

    // 2. Tokenize query into clean stems
    final rawTokens = lower.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').split(RegExp(r'\s+'));
    final tokens = rawTokens.where((t) => t.length > 1 && !_stopWords.contains(t)).toList();

    // 3. Score all chunks
    final scoredChunks = <MapEntry<KnowledgeChunk, double>>[];

    for (final chunk in ClinicalKnowledgeBase.chunks) {
      // Don't match crisis chunk for ordinary queries
      if (chunk.id == 'rag_crisis_protocol') continue;

      double score = 0.0;

      // Exact substring match in full query (high signal)
      for (final kw in chunk.keywords) {
        if (lower.contains(kw)) {
          score += 4.5;
        }
      }

      // Tag matches
      for (final tag in chunk.tags) {
        if (lower.contains(tag)) {
          score += 3.0;
        }
      }

      // Token-level scoring against title, summary, and keywords
      for (final token in tokens) {
        if (chunk.title.toLowerCase().contains(token)) {
          score += 2.0;
        }
        if (chunk.keywords.any((kw) => kw.contains(token))) {
          score += 1.5;
        }
        if (chunk.clinicalSummary.toLowerCase().contains(token)) {
          score += 0.5;
        }
      }

      if (score > 0) {
        scoredChunks.add(MapEntry(chunk, score));
      }
    }

    // Sort descending by score
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    // Fallback if no relevant chunk scored above threshold
    final topChunk = scoredChunks.isNotEmpty && scoredChunks.first.value >= 1.5
        ? scoredChunks.first.key
        : _getDefaultGreetingChunk();

    final secondary = scoredChunks.length > 1
        ? [scoredChunks[1].key]
        : <KnowledgeChunk>[];

    // Find recommended resource in active catalog
    ResourceItem? matchedResource;
    if (topChunk.recommendedResourceId != null) {
      for (final item in ResourceItem.catalog) {
        if (item.id == topChunk.recommendedResourceId) {
          matchedResource = item;
          break;
        }
      }
    }

    final confidence = scoredChunks.isNotEmpty ? math.min(1.0, scoredChunks.first.value / 10.0) : 0.0;

    return RagRetrievalResult(
      topChunk: topChunk,
      secondaryChunks: secondary,
      recommendedResource: matchedResource,
      suggestedChips: topChunk.followUpQuestions,
      confidenceScore: confidence,
      isCrisisQuery: false,
    );
  }

  static KnowledgeChunk _getDefaultGreetingChunk() {
    return const KnowledgeChunk(
      id: 'rag_default_welcome',
      category: 'welcome',
      title: 'Nova AI Neuro-Wellness Orientation',
      tags: ['welcome', 'help', 'guide', 'brainwaves', 'mindfulness'],
      keywords: ['hello', 'hi', 'hey', 'start', 'help me'],
      clinicalSummary:
          'Nova is an evidence-based clinical guide integrating cognitive psychology, polyvagal somatic resets, '
          'and real-time neurofeedback telemetry from the Muse 2 headband.',
      actionableProtocols: [
        'Explore your live brainwave frequencies (Alpha, Beta, Theta, Delta, Gamma).',
        'Learn physiological techniques to quickly lower heart rate and reduce panic.',
        'Launch guided audio-visual meditations tailored to your autonomic state.',
      ],
      recommendedResourceId: 'med_01', // 5-Min Morning Meditation
      followUpQuestions: [
        'Calm Anxiety Now',
        'Explain My Brainwaves',
        'What is HRV & Vagal Tone?',
        'Help Me Sleep',
      ],
    );
  }
}
