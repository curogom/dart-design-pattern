# Flutter에서 효율적인 디자인 패턴 & 주의해야 할 안티패턴

Flutter/Riverpod 실습에서 반복적으로 확인한 내용을 기반으로, 주니어 개발자도 바로 적용할 수 있도록 설명을 풀었다.  
각 패턴마다 “왜 쓰면 좋은지”, “어떤 코드 모습인지”, “어디서 더 배울 수 있는지”를 같은 순서로 정리했다.

## Flutter와 궁합이 좋은 패턴

### Strategy + Provider 조합
- UI 정책(테마, 정렬 옵션 등)을 틀로 만들어 두고 런타임에 교체할 때 유용하다.  
  Riverpod이 상태를 보관해 주기 때문에 버튼 한 번으로 전략을 교체할 수 있다 (`week01_patterns` 참고).
- Provider를 쓰면 위젯이 필요한 부분만 다시 그려져 성능도 지킬 수 있다.
- 참고: [Flutter 공식 상태관리 가이드](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)

```dart
final themeStrategyProvider =
    NotifierProvider<ThemeStrategyNotifier, ThemeStrategy>(
  ThemeStrategyNotifier.new,
);

final currentThemeProvider = Provider<AppTheme>(
  (ref) => ref.watch(themeStrategyProvider).buildTheme(),
);
```

### Template Method (리스트/파이프라인)
- “공통 흐름 + 조금씩 다른 세부 단계”를 표현한다.  
  예: 보고서 생성 시 전처리→정렬→후처리는 항상 같지만, 정렬 방식만 다를 때.
- 공통 단계는 부모 클래스에 두고, 자식 클래스는 필요한 메서드만 override한다.
- 참고: [Effective Dart - Design](https://dart.dev/guides/language/effective-dart/design)

```dart
abstract class TaskReportTemplate {
  const TaskReportTemplate();

  List<String> buildReport(List<String> rawTasks) {
    final sanitized = preprocess(rawTasks);
    final sorted = sort(sanitized);
    return decorate(sorted);
  }

  List<String> preprocess(List<String> tasks) =>
      tasks.map((task) => task.trim()).toList();

  List<String> sort(List<String> tasks);
  List<String> decorate(List<String> tasks) => ['--- ${title()} ---', ...tasks];
  String title();
}
```

### Decorator + Composite for UI Layering
- Decorator는 “레이어를 한 겹씩 감싸며 기능을 추가”한다. UI 스타일, 로깅, 성능 측정을 붙일 때 편하다.
- Composite은 “트리 형태로 구성된 UI/스타일”을 표현한다. 부모 노드가 자식 노드 결과를 모아 최종 스타일을 만든다.
- 둘 다 작은 객체를 조합하는 방식이라 Flutter의 위젯 철학과 잘 맞는다.
- 참고: [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples) – TodoMVC 파생 예제에서 Composite/Decorator와 유사한 패턴 사용.

```dart
WidgetFeature feature = BaseWidgetFeature();
feature = SpacingDecorator(feature, spacing: 12);
feature = SurfaceDecorator(feature, elevation: 6);
feature = ServiceHookDecorator(feature, hook: 'analytics');
feature = ProfilingDecorator(
  inner: feature,
  label: 'feed-card.pipeline',
  log: log,
);
```

### Adapter + Proxy (네트워크/데이터 계층)
- Adapter는 “낯선 API 결과”를 “내 앱에서 쓰기 편한 모델”로 바꿔 준다.  
  XML/JSON 필드 이름이 제각각일 때 특히 빛난다.
- Proxy는 실제 API 앞에 캐시/통계 레이어를 두는 패턴이다. 같은 slug를 반복 요청해도 빠르게 응답할 수 있다.
- 참고: [Flutter 공식 네트워킹 가이드](https://docs.flutter.dev/cookbook/networking/fetch-data) + [Clean Architecture in Flutter (Reso Coder)](https://resocoder.com/2020/03/09/flutter-clean-architecture-tdd/)

```dart
class SupportReviewFacade {
  Future<ReviewReport> buildReview(ReviewRequest request) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final ConversationThread thread = adapter.toThread(request.transcript);

    final articles = <Article>[];
    for (final slug in request.relatedArticles) {
      articles.add(await knowledgeBase.fetch(slug));
    }
    stopwatch.stop();
    return ReviewReport(thread: thread, articles: articles, totalLatency: stopwatch.elapsed);
  }
}
```

### Facade + Riverpod Family
- Facade는 여러 객체를 감춘 채 “한 줄짜리 API”로 묶어 준다.  
  여기에 `FutureProvider.family`를 얹으면 티켓별 비동기 작업을 독립적으로 추적할 수 있다.
- Stopwatch, Telemetry 등을 Facade 안에서 처리해 UI 단을 단순하게 만든다.
- 참고: [Riverpod FutureProvider.family](https://riverpod.dev/docs/providers/future_provider)

```dart
final reviewReportProvider =
    FutureProvider.autoDispose.family<ReviewReport, ReviewRequest>(
  (ref, request) {
    final facade = ref.watch(reviewFacadeProvider);
    return facade.buildReview(request);
  },
);
```

## Flutter에서 안티패턴이 되기 쉬운 패턴/관행

### Global Singleton God Object
- 앱 어디서나 접근 가능한 “거대 싱글턴”은 편해 보이지만 테스트·Hot reload 환경에서는 상태가 섞여버린다.
- Provider를 통해 “필요한 범위”에만 인스턴스를 주입하면 안전하게 재사용할 수 있다.
- 참고: [Flutter 공식 문서 – 단일 인스턴스 공유 주의](https://docs.flutter.dev/perf/faq#avoid-blocking-the-main-thread)

```dart
// ❌ 앱 전역에서 직접 접근하는 싱글턴
class GlobalTelemetry {
  static final GlobalTelemetry instance = GlobalTelemetry._();
  GlobalTelemetry._();
  int counter = 0;
}

// ✅ ProviderScope override로 주입
final telemetryProvider = Provider<TelemetryCenter>(
  (ref) => TelemetryCenter.instance,
);
```

### Deep Inheritance Chains (과도한 Template Method 변형)
- “부모 → 자식 → 손자…” 구조가 깊어질수록 어떤 기능이 어디서 오는지 추적하기 어렵다.
- 필요 이상으로 상속하지 말고, 조합(Composition) 또는 함수 주입으로 대체한다.
- 참고: [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#prefer-composition-over-inheritance)

### Event Bus / Raw Observer 남용
- “여기저기에서 이벤트만 쏜다” 방식은 누가 듣는지 추적하기 어렵고, 화면이 dispose돼도 구독이 남아 메모리 누수가 날 수 있다.
- UI는 가급적 `StateNotifier`/`ChangeNotifier`로 상태를 묶어 관리하고, Stream은 명확한 생명주기나 IO 경계에만 사용한다.
- 참고: [Flutter 공식 문서 – Streams vs ChangeNotifier](https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple)

### Service Locator (GetIt) 남용
- `GetIt` 같은 Service Locator를 아무 곳에서나 호출하면 “어떤 의존성이 필요한지” 코드만 봐서는 알 수 없다.
- 테스트에서 가짜 객체로 교체하기도 힘들다. 의존성은 Provider/InheritedWidget 등을 통해 명시적으로 전달하자.
- 참고: [Reso Coder – Why I don't use GetIt everywhere](https://resocoder.com/2020/11/06/flutter-dependency-injection/)

### Massive StatefulWidget (거대 Stateful 위젯)
- “setState 안에 모든 로직”을 몰아 넣으면 어느 부분이 바뀌어도 전체가 다시 그려진다.
- 상태는 별도 Controller/Notifier로, UI는 `ConsumerWidget`이나 `HookWidget`으로 나눠 관리하면 가독성과 성능을 동시에 챙길 수 있다.
- 참고: [Flutter Performance best practices](https://docs.flutter.dev/perf/rendering/best-practices)

```dart
class SupportStateMachinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        ticketConfigProvider.overrideWithValue(
          const TicketConfig(ticketId: 'ticket-ui', subject: '결제 실패'),
        ),
      ],
      child: const _SupportStateMachineView(),
    );
  }
}
```

## 참고 자료 & 레퍼런스
- Flutter 공식 문서: State management, Performance, Networking 섹션.
- Riverpod 공식 문서 & 코드랩 – Provider override, family 사용법.
- Head First Design Patterns (원서) + 본 스터디의 `week01`~`week06` 예제 코드.
- 커뮤니티 사례: Flutter Architecture Samples, Reso Coder Clean Architecture 시리즈, FilledStacks Stacked 아키텍처 글.

## 스터디 회고
- 매 주차마다 “코드 · 테스트 · 문서” 삼종 세트를 챙기다 보니 개념이 몸에 배었다. Riverpod override, ProviderObserver 같은 실전 도구도 자연스럽게 익혔다.
- 순수 Dart 콘솔 예제로 먼저 검증하고 Flutter UI로 확장하는 흐름이 빠르게 굳어졌다. 실패해도 원인을 좁히기 쉬웠다.
- 주차별 체크리스트(10줄 요약, 안티패턴 5줄, 과제 3개)를 지키는 과정이 힘들었지만, 마지막에 Extra 플레이북을 만들면서 전체 그림을 한눈에 볼 수 있었다.
- 앞으로는 CI에서 `dart analyze`/`dart test`를 자동 실행해 수동 실행 부담을 줄이고, Flutter 데모에는 golden/screenshot 테스트를 더해 품질을 높이고 싶다.
