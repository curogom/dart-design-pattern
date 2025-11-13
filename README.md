# Head First Design Patterns 스터디 (Dart/Flutter)

## 소개
- “Head First Design Patterns”를 Flutter/Dart 환경에서 실습하며 학습하는 프로젝트입니다.
- 모든 예제는 Dart 3.x, Flutter 3.35+, Riverpod 3을 기준으로 작성합니다.
- 예제 → 테스트 → 설명 순으로 산출물을 구성하고, 한국어 설명과 영어 식별자를 병행합니다.

## 프로젝트 구조
- `week01`~`week06` : 주차별 `Overview.md`, 순수 Dart 패키지(`weekXX/dart`), 문서(`weekXX/docs`)
- `apps/flutter_client` : 주차별 Flutter 데모를 모은 멀티 페이지 앱

## 주차별 로드맵
| 주차 | 주제 | 학습 패턴 | Flutter/Dart 예제 |
| --- | --- | --- | --- |
| 1주차 | 객체지향 기본 | 전략, 템플릿 메서드 | 테마/스타일 교체 전략, 리스트 정렬 |
| 2주차 | 객체 협력 | 옵저버 | `Stream` 기반 이벤트 브로드캐스트 |
| 3주차 | 객체 조합 | 데코레이터, 컴포지트 | 위젯 트리 데코레이션, 다단계 스타일링 |
| 4주차 | 객체 생성 | 팩토리 메서드, 추상 팩토리 | 서비스/위젯 팩토리 작성 |
| 5주차 | 상태 관리 | 싱글턴, 상태 | Provider/Riverpod 상태 전환 위젯 |
| 6주차 | 종합 응용 | 어댑터, 프록시, 복습 | 외부 API ↔ 모델 변환, HTTP 프록시 모킹 |

## 로컬 실행 & 검증
```bash
# 1주차 순수 Dart 패키지
cd week01/dart
dart pub get
dart analyze
dart test --coverage=coverage

# Flutter 클라이언트
cd ../../apps/flutter_client
flutter pub get
flutter run        # iOS/Android/Web 중 하나 선택
flutter test       # 위젯 및 통합 테스트 추가 시
```

## 기여 가이드 요약
- 커밋은 Conventional Commits(`feat`, `fix`, `docs`, `test`, `refactor` 등)를 사용합니다.
- PR에는 실행한 명령, 스크린샷/로그, 성능 변화 등을 한글로 정리하고 관련 이슈를 연결합니다.
- 패턴 산출물은 코드, 테스트, 문서 세트를 반드시 포함하며 `Overview.md` 체크리스트를 충족해야 합니다.

## 라이선스
- 루트 LICENSE 파일을 기준으로 하며, 외부 배포 전 반드시 검토하십시오.
