# Factory Method 패턴 요약 (Week 04)

## 10줄 요약
1. `AuditLogService`가 `createSink()` 팩토리 메서드로 로그 전송 객체 생성을 캡슐화한다.
2. `ConsoleAuditLogService`와 `BufferedAuditLogService`가 동일한 절차에 서로 다른 `LogSink`를 주입한다.
3. `LoggedEvent`는 JSON 직렬화를 담당해 싱크 구현이 문자열 포맷을 고민하지 않도록 분리한다.
4. Riverpod `auditLogServiceProvider`가 설정을 읽어 런타임에 팩토리 구현을 교체한다.
5. 타임스탬프 생성을 `logTimestampProvider`로 분리해 테스트에서 결정론적으로 제어한다.
6. 콘솔 모드는 `auditLogConsoleWriterProvider`를 통해 `stdout` 외 다른 채널로도 쉽게 전환된다.
7. 버퍼 모드는 `auditLogBufferProvider`를 이용해 테스트, UI 미리보기, 재전송 큐에 재사용된다.
8. `main()`은 동일 API로 콘솔/버퍼 컨테이너를 각각 구성해 전략 교체를 시연한다.
9. 실패 케이스는 필수 Provider 미등록 시 `StateError`를 던져 조기 감지한다.
10. 생성 책임을 서비스 내부에 모아 의존성 주입(Provider)과 패턴 학습을 동시에 체험한다.

## 생성 경로 표
| 설정 | 선택된 서비스 | 최종 LogSink |
| --- | --- | --- |
| `AuditLogTarget.console` + `stdout.writeln` | `ConsoleAuditLogService` | `ConsoleLogSink(writer: stdout.writeln)` |
| `AuditLogTarget.buffered` + `StringBuffer` | `BufferedAuditLogService` | `BufferedLogSink(buffer: StringBuffer)` |

## Riverpod Provider 관계
| Provider | 타입 | 역할 |
| --- | --- | --- |
| `auditLogConfigProvider` | `Provider<AuditLogConfig>` | 실행 환경(콘솔/버퍼)을 정의해 팩토리 분기를 결정한다. |
| `auditLogConsoleWriterProvider` | `Provider<void Function(String)>` | 콘솔 로그 출력 함수를 주입해 UI/CLI/원격 로깅을 교체한다. |
| `auditLogBufferProvider` | `Provider<StringBuffer>` | 메모리 싱크 버퍼를 제공해 비동기 재전송이나 테스트 어서션을 돕는다. |
| `logTimestampProvider` | `Provider<DateTime Function()>` | 타임스탬프 Clock을 분리해 재현 가능한 로그를 만든다. |
| `auditLogServiceProvider` | `Provider<AuditLogService>` | 위 설정을 조합해 팩토리 메서드 구현을 선택한다. |

## 생성 캐시 전략 설명
- 콘솔 모드는 매 호출 시 새로운 `ConsoleLogSink`를 생성하지만, 실제로는 writer가 무상태라 객체 풀 필요성이 낮다.
- 버퍼 모드는 싱크가 공유 버퍼를 포획하므로 Provider override를 통해 버퍼 수명 주기를 명확히 제어한다.
- 다수 컨테이너에서 동일 버퍼를 공유하면 레이스가 발생할 수 있어 테스트마다 `StringBuffer` 인스턴스를 주입한다.

## 안티패턴 비교 (5줄)
- `if/else` 분기로 로그 타겟을 직접 생성하면 테스트에서 시간/버퍼를 조작하기 어렵다.
- 글로벌 싱글턴 로그 싱크는 상태 공유로 인해 테스트 간 오염이 발생한다.
- 서브클래스가 직접 `LoggedEvent`를 조작하면 포맷이 흩어져 일관성이 깨진다.
- UI 코드에서 `ConsoleLogSink`를 직접 new 하면 주입 가능성이 사라진다.
- 다중 생성자를 두고 분기하면 팩토리 메서드 의도가 드러나지 않고 OCP가 무너진다.

## 연습 문제 (Hints 포함)
1. **파일 기반 싱크 추가** – `FileLogSink`를 구현해 `IOSink`와 비동기 flush 전략을 설계하라. *Hint: `auditLogConsoleWriterProvider`와 유사하게 `IOSink` Provider를 도입한다.*
2. **배치 전송 최적화** – 버퍼에 10건 쌓이면 배치 API로 전송하도록 `BufferedLogSink`를 확장하라. *Hint: `StringBuffer` 대신 커스텀 큐 객체를 주입한다.*
3. **민감 정보 마스킹** – `AuditLogService.record` 단계에서 규칙 기반 필터를 적용하라. *Hint: `LogSink` 이전에 `LoggedEvent`를 변환하는 데코레이터를 추가한다.*
