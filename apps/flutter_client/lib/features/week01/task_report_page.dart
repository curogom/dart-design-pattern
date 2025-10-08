import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week01_patterns/template_method/task_report.dart';

// 템플릿 메서드 데모 페이지:
// - Dropdown으로 템플릿 구현을 바꾸면 Riverpod Notifier가 보고서 재생성 과정을 즉시 반영합니다.
// - Flutter에서 고정된 데이터 파이프라인(전처리 → 정렬 → 후처리)을 관리할 때 템플릿 메서드로 단계별 확장을 분리할 수 있습니다.
// - 대표 사례: 보고서 생성, 테이블/차트용 데이터 포맷 교체, 여러 백엔드 응답을 공통 UI에 맞추는 어댑터 흐름 등.

class TaskReportPage extends ConsumerWidget {
  const TaskReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportLines = ref.watch(sortedTaskReportProvider);
    final currentTemplate = ref.watch(taskReportTemplateProvider);

    // 템플릿 메서드 패턴에서 선택된 템플릿을 ProviderScope로 구독해 보고서 구성 단계를 실시간으로 확인합니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text('템플릿 메서드 · 업무 보고서'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정렬 기준을 선택하면 보고서가 자동으로 재생성됩니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButton<TaskReportTemplate>(
              value: currentTemplate,
              items: const [
                DropdownMenuItem(
                  value: PriorityTaskReport(),
                  child: Text('우선순위'),
                ),
                DropdownMenuItem(
                  value: DurationTaskReport(),
                  child: Text('예상 소요 시간'),
                ),
              ],
              onChanged: (template) {
                if (template != null) {
                  ref.read(taskReportTemplateProvider.notifier).select(
                        template,
                      );
                }
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: reportLines.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(reportLines[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
