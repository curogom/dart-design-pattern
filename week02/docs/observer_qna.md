# Observer 패턴 Q&A 답변

1. **옵저버가 많을 때 순서를 보장하려면?**  
   `StreamController.broadcast(sync: true)`로 이벤트가 추가된 순서 그대로 동기 전달되도록 만든다. 또한 각 옵저버에서 비동기 로직을 수행해야 한다면 `scheduleMicrotask`나 별도 큐를 사용해 주제의 이벤트 루프를 막지 않는다.

2. **에러 이벤트만 별도 로깅하려면?**  
   옵저버의 `onError`에서 로깅 로직을 실행하고, 필요하면 `reportError` 호출 전 `DeliveryException`에 카테고리를 부여한다. UI 측에서는 `deliveryTimelineProvider`처럼 에러 내역을 별도 상태로 분리해 SnackBar, Dialog에 연결한다.

3. **스트림을 재시작(restart)해야 할 때는?**  
   기존 `DeliveryTracker`를 닫고 새 인스턴스를 생성한 뒤 `ProviderScope` override로 교체한다. Riverpod에서는 `ref.invalidate(deliveryTrackerProvider)`를 활용해 구독을 재구성하면 된다.

4. **Flutter 위젯 테스트에서 스트림을 주입하려면?**  
   `ProviderScope(overrides: [...])`를 사용해 `deliveryTrackerProvider`를 테스트 전용 목 객체로 교체한다. `FakeDeliveryTracker`에서 `StreamController`를 직접 조작하면 기대 이벤트 타이밍을 정밀하게 통제할 수 있다.

5. **백오프·재시도 로직은 어디에 둬야 하나?**  
   주제에서 직접 지연을 관리하기보다는 `StreamTransformer`나 별도 서비스 레이어에 배치해 재시도 정책을 재활용한다. 예를 들어, API 호출 결과를 옵저버에 전달하기 전에 `retryWhen`과 비슷한 래퍼를 두면 주제 코드를 간결하게 유지할 수 있다.
