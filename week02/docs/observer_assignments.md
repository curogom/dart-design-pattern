# Observer 패턴 과제 모범답안

1. **지연 배송 알림 스로틀링 구현**  
   - `StreamTransformer.fromHandlers`로 동일 주문 ID가 일정 시간 내 반복되면 최신 이벤트만 통과시키도록 한다.  
   - 또는 RxDart의 `debounceTime`에 해당하는 로직을 직접 구현해 SnackBar 알림 빈도를 줄인다.  
   - 테스트에서는 `FakeAsync`로 가상 시간을 이동해 스로틀링이 작동하는지 검증한다.

2. **에러 발생 시 재연결 처리**  
   - `reportError` 이후 `Timer.periodic`를 시작해 외부 데이터 소스에 재연결을 시도하고, 성공 시 타이머를 취소한다.  
   - Riverpod Notifier에서는 `state = state.appendError(error)`로 UI에 알리고, `ref.onDispose`에서 타이머를 정리한다.

3. **구독자별 관심 주문 필터**  
   - `DeliveryObserver` 구현체에 관심 주문 ID 리스트를 주입하고, `onStatus`에서 `if (!allowedIds.contains(event.orderId)) return;`으로 필터링한다.  
   - 필터를 주제 쪽에서 처리하려면 구독 등록 시 콜백 앞에 `StreamTransformer.where`를 연결해 불필요한 이벤트를 차단한다.
