import 'dart:async';

import 'package:riverpod/riverpod.dart';

class Article {
  const Article({
    required this.slug,
    required this.title,
    required this.body,
    required this.tags,
    required this.fetchedAt,
  });

  final String slug;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime fetchedAt;
}

abstract class KnowledgeBaseClient {
  Future<Article> fetch(String slug);
}

class RemoteKnowledgeBaseClient implements KnowledgeBaseClient {
  RemoteKnowledgeBaseClient({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;

  @override
  Future<Article> fetch(String slug) async {
    await Future<void>.delayed(latency);
    return Article(
      slug: slug,
      title: 'How to address $slug',
      body: 'Simulated remote content for $slug.',
      tags: <String>['guide', slug],
      fetchedAt: DateTime.now(),
    );
  }
}

class CacheStats {
  const CacheStats({
    required this.requests,
    required this.hits,
    required this.misses,
  });

  final int requests;
  final int hits;
  final int misses;

  double get hitRate =>
      requests == 0 ? 0 : hits / requests;
}

class CachedKnowledgeBaseClient implements KnowledgeBaseClient {
  CachedKnowledgeBaseClient(this.delegate, {this.ttl = const Duration(minutes: 10)});

  final KnowledgeBaseClient delegate;
  final Duration ttl;

  final Map<String, Article> _cache = <String, Article>{};
  final Map<String, DateTime> _expiry = <String, DateTime>{};

  int _requests = 0;
  int _hits = 0;
  int _misses = 0;

  CacheStats get stats =>
      CacheStats(requests: _requests, hits: _hits, misses: _misses);

  @override
  Future<Article> fetch(String slug) async {
    _requests += 1;
    final DateTime now = DateTime.now();

    if (_cache.containsKey(slug) &&
        _expiry[slug] != null &&
        _expiry[slug]!.isAfter(now)) {
      _hits += 1;
      return _cache[slug]!;
    }

    _misses += 1;
    final Article article = await delegate.fetch(slug);
    _cache[slug] = article;
    _expiry[slug] = now.add(ttl);
    return article;
  }

  void pruneExpired() {
    final DateTime now = DateTime.now();
    final List<String> expired = _expiry.entries
        .where((MapEntry<String, DateTime> entry) => entry.value.isBefore(now))
        .map((MapEntry<String, DateTime> entry) => entry.key)
        .toList(growable: false);
    for (final String slug in expired) {
      _cache.remove(slug);
      _expiry.remove(slug);
    }
  }

  void reset() {
    _cache.clear();
    _expiry.clear();
    _requests = 0;
    _hits = 0;
    _misses = 0;
  }
}

class KnowledgeBaseConfig {
  const KnowledgeBaseConfig({
    required this.ttl,
    required this.latency,
  });

  final Duration ttl;
  final Duration latency;
}

/// KB 프록시 TTL/지연을 주입하고 실험 조건을 공유한다.
final knowledgeBaseConfigProvider = Provider<KnowledgeBaseConfig>(
  (ref) => const KnowledgeBaseConfig(
    ttl: Duration(minutes: 5),
    latency: Duration(milliseconds: 120),
  ),
);

/// 리모트 클라이언트를 프록시로 감싸 캐시/통계를 노출한다.
final knowledgeBaseClientProvider =
    Provider<KnowledgeBaseClient>((ref) {
  final KnowledgeBaseConfig config = ref.watch(knowledgeBaseConfigProvider);
  final KnowledgeBaseClient remote =
      RemoteKnowledgeBaseClient(latency: config.latency);
  return CachedKnowledgeBaseClient(remote, ttl: config.ttl);
});

final articleProvider = FutureProvider.autoDispose
    .family<Article, String>((ref, slug) async {
  final KnowledgeBaseClient client = ref.watch(knowledgeBaseClientProvider);
  return client.fetch(slug);
});

Future<void> main() async {
  final ProviderContainer container = ProviderContainer(overrides: <Override>[
    knowledgeBaseConfigProvider.overrideWithValue(
      const KnowledgeBaseConfig(
        ttl: Duration(seconds: 2),
        latency: Duration(milliseconds: 50),
      ),
    ),
  ]);

  final Article first =
      await container.read(articleProvider('cache').future);
  final Article second =
      await container.read(articleProvider('cache').future);

  final CachedKnowledgeBaseClient proxy = container
      .read(knowledgeBaseClientProvider) as CachedKnowledgeBaseClient;
  print('First fetched at: ${first.fetchedAt}');
  print('Second fetched at: ${second.fetchedAt}');
  print('Cache stats: requests=${proxy.stats.requests} '
      'hits=${proxy.stats.hits} misses=${proxy.stats.misses} '
      'hitRate=${proxy.stats.hitRate.toStringAsFixed(2)}');

  container.dispose();
}
