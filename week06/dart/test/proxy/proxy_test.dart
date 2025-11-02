import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:week06_patterns/proxy.dart';
import 'package:week06_patterns/src/proxy/proxy_example.dart';

void main() {
  group('CachedKnowledgeBaseClient', () {
    test('caches responses within TTL', () async {
      final CachedKnowledgeBaseClient proxy = CachedKnowledgeBaseClient(
        RemoteKnowledgeBaseClient(latency: Duration.zero),
        ttl: const Duration(minutes: 1),
      );

      final Article first = await proxy.fetch('faq');
      final Article second = await proxy.fetch('faq');

      expect(first.slug, 'faq');
      expect(second.fetchedAt, first.fetchedAt);
      expect(proxy.stats.hits, 1);
      expect(proxy.stats.misses, 1);
    });

    test('expires cache after TTL', () async {
      final CachedKnowledgeBaseClient proxy = CachedKnowledgeBaseClient(
        RemoteKnowledgeBaseClient(latency: Duration.zero),
        ttl: const Duration(milliseconds: 1),
      );

      final Article first = await proxy.fetch('faq');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final Article second = await proxy.fetch('faq');

      expect(second.fetchedAt.isAfter(first.fetchedAt), isTrue);
      expect(proxy.stats.hits, 0);
      expect(proxy.stats.misses, 2);
    });
  });

  group('knowledgeBase providers', () {
    test('fetches article via FutureProvider', () async {
      final ProviderContainer container = ProviderContainer(overrides: <Override>[
        knowledgeBaseConfigProvider.overrideWithValue(
          const KnowledgeBaseConfig(
            ttl: Duration(minutes: 1),
            latency: Duration.zero,
          ),
        ),
      ]);

      final Article article =
          await container.read(articleProvider('proxy-demo').future);
      expect(article.slug, 'proxy-demo');

      container.dispose();
    });
  });
}
