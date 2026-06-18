import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/presentation/steps/department_step.dart';
import 'package:horeca_app/features/request/presentation/steps/category_step.dart';
import 'package:horeca_app/features/request/presentation/steps/product_list_step.dart';
import 'package:horeca_app/features/request/presentation/steps/generate_step.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
class RequestScreen extends ConsumerWidget {
  const RequestScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Заявка'), leading: state.step > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => ref.read(requestStateProvider.notifier).goBack()) : null),
      body: SafeArea(child: IndexedStack(index: state.step, children: const [DepartmentStep(), CategoryStep(), ProductListStep(), GenerateStep()])),
    );
  }
}
