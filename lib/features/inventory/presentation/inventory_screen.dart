import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/inventory/presentation/steps/select_department_step.dart';
import 'package:horeca_app/features/inventory/presentation/steps/category_filter_step.dart';
import 'package:horeca_app/features/inventory/presentation/steps/input_remaining_step.dart';
import 'package:horeca_app/features/inventory/presentation/steps/report_step.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентаризация'),
        leading: state.step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (state.step == 1) {
                    ref.read(inventoryStateProvider.notifier).reset();
                  } else if (state.step == 2) {
                    ref.read(inventoryStateProvider.notifier).reset(); // вернуться к выбору категорий
                  } else if (state.step == 3) {
                    ref.read(inventoryStateProvider.notifier).backToInput();
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: state.step,
          children: const [
            SelectDepartmentStep(),
            CategoryFilterStep(),
            InputRemainingStep(),
            ReportStep(),
          ],
        ),
      ),
    );
  }
}
