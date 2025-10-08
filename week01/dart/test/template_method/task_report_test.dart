import 'package:test/test.dart';
import 'package:week01_patterns/template_method/task_report.dart';

void main() {
  group('TaskReportTemplate', () {
    test('Priority report sorts by priority tag', () {
      const template = PriorityTaskReport();
      final report = template.buildReport([
        '[MID] B',
        '[HIGH] A',
        '[LOW] C',
      ]);
      expect(report[1], contains('HIGH'));
      expect(report[2], contains('MID'));
      expect(report[3], contains('LOW'));
    });

    test('Duration report appends total minutes summary', () {
      const template = DurationTaskReport();
      final report = template.buildReport([
        '[TASK] Write docs (10m)',
        '[TASK] Refactor (20m)',
      ]);
      expect(report.last, '예상 소요 시간: 30분');
    });
  });
}
