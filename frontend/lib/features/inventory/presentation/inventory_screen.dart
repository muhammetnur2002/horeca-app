import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/inventory/presentation/steps/select_department_step.dart';
import 'package:horeca_app/features/inventory/presentation/steps/input_remaining_step.dart';
import 'package:horeca_app/features/inventory/presentation/steps/report_step.dart';
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Инвентаризация'), leading: state.departmentId != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { if (state.isGenerated) ref.read(inventoryStateProvider.notifier).backToInput(); else ref.read(inventoryStateProvider.notifier).reset(); }) : null),
      body: SafeArea(child: IndexedStack(index: state.departmentId == null ? 0 : state.isGenerated ? 2 : 1, children: const [SelectDepartmentStep(), InputRemainingStep(), ReportStep()])),
    );
  }
}
