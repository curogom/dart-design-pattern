import 'package:riverpod/riverpod.dart';

// 템플릿 메서드 패턴 소개:
// - 공통 알고리즘 흐름(`buildReport`)을 상위 클래스가 고정하고, 세부 단계(`sort`, `decorate`)만
//   하위 클래스가 재정의합니다.
// - 훅 메서드와 기본 구현을 제공해 서브클래스에서 필요한 최소한의 작업만 오버라이드하도록 유도합니다.
// - Riverpod Provider는 선택된 템플릿을 상태로 노출해 UI/테스트가 알고리즘 변형을 쉽게 실험하게 합니다.
// Dart/Flutter 적합성:
// - 리스트 가공·포맷팅처럼 순수 함수로 표현되는 파이프라인을 구조화하기 좋고, 테스트 시 각 단계만 검증하기 쉽습니다.
// - 반면 서브클래스가 늘어나면 상속 트리가 깊어질 위험이 있으며, 다형성보다 조합(컴포지션)이 편한 Dart 생태계에서는 과도하게 쓰지 않도록 주의해야 합니다.
// 대표 사례:
// - 로깅 포맷, PDF/CSV 등 문서 출력 파이프라인, UI 리스트 정렬/후처리 등 고정 절차 + 변형 포인트가 명확한 도메인에 적합합니다.

/// 템플릿 메서드 패턴으로 리스트 정렬과 후처리를 관리한다.
abstract class TaskReportTemplate {
  const TaskReportTemplate();

  List<String> buildReport(List<String> rawTasks) {
    final sanitized = preprocess(rawTasks);
    final sorted = sort(sanitized);
    return decorate(sorted);
  }

  List<String> preprocess(List<String> tasks) => tasks.map(_normalize).toList();

  List<String> sort(List<String> tasks);

  List<String> decorate(List<String> tasks) => [
        '--- ${title()} ---',
        ...tasks,
        '총 ${tasks.length}건',
      ];

  String title();

  String _normalize(String input) => input.trim();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;
}

class PriorityTaskReport extends TaskReportTemplate {
  const PriorityTaskReport();

  @override
  List<String> sort(List<String> tasks) {
    final copy = [...tasks];
    copy.sort((a, b) {
      final aScore = _priorityScore(a);
      final bScore = _priorityScore(b);
      return bScore.compareTo(aScore);
    });
    return copy;
  }

  @override
  String title() => '우선순위 기준 정렬';

  int _priorityScore(String task) {
    if (task.startsWith('[HIGH]')) return 3;
    if (task.startsWith('[MID]')) return 2;
    if (task.startsWith('[LOW]')) return 1;
    return 0;
  }
}

class DurationTaskReport extends TaskReportTemplate {
  const DurationTaskReport();

  @override
  List<String> sort(List<String> tasks) {
    final copy = [...tasks];
    copy.sort((a, b) {
      final aMinutes = _estimateMinutes(a);
      final bMinutes = _estimateMinutes(b);
      return aMinutes.compareTo(bMinutes);
    });
    return copy;
  }

  @override
  List<String> decorate(List<String> tasks) {
    final base = super.decorate(tasks);
    final totalMinutes =
        tasks.fold<int>(0, (sum, task) => sum + _estimateMinutes(task));
    return [
      ...base,
      '예상 소요 시간: $totalMinutes분',
    ];
  }

  @override
  String title() => '소요 시간 기준 정렬';

  int _estimateMinutes(String task) {
    final pattern = RegExp(r'\((\d+)m\)');
    final match = pattern.firstMatch(task);
    if (match == null) {
      return 60;
    }
    return int.parse(match.group(1)!);
  }
}

// 템플릿 메서드 패턴에서 선택된 템플릿을 Riverpod Notifier 상태로 노출해 UI 제어를 단순화합니다.
class TaskReportTemplateNotifier extends Notifier<TaskReportTemplate> {
  @override
  TaskReportTemplate build() => const PriorityTaskReport();

  void select(TaskReportTemplate template) {
    if (state == template) {
      return;
    }
    state = template;
  }
}

final taskReportTemplateProvider =
    NotifierProvider<TaskReportTemplateNotifier, TaskReportTemplate>(
  TaskReportTemplateNotifier.new,
);

final sortedTaskReportProvider = Provider<List<String>>((ref) {
  const sampleTasks = [
    '[MID] 위젯 트리 정리 (30m)',
    '[HIGH] 전략 패턴 작성 (50m)',
    '[LOW] README 다듬기 (15m)',
  ];
  return ref.watch(taskReportTemplateProvider).buildReport(sampleTasks);
});

void main() {
  const raw = [
    ' [LOW] README 다듬기 (15m) ',
    '[HIGH] 전략 패턴 작성 (50m)',
    '[MID] 위젯 트리 정리 (30m)',
  ];
  final template = PriorityTaskReport();
  final report = template.buildReport(raw);
  report.forEach(print);
}
