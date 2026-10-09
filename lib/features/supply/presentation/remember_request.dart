import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/supply_models.dart';

final openSupplySignatureProvider = StateProvider<String?>((ref) => null);

/// Запоминает заявку строками, чтобы на следующий день сверить её с накладной.
/// Повторный заход с теми же строками не создаёт вторую заявку.
void rememberSupplyRequest(WidgetRef ref, RequestState state, String departmentLabel) {
  final lines = [
    for (final item in state.items)
      if (item.quantity > 0)
        SupplyLine(
          productId: item.productId,
          name: item.productName,
          quantity: item.quantity,
          unit: item.unit,
        ),
  ];
  if (lines.isEmpty) return;
  final signature = [
    departmentLabel,
    for (final line in lines) '${line.productId}:${line.quantity}:${line.unit}:${line.name}',
  ].join('|');
  final previousSignature = ref.read(openSupplySignatureProvider);
  final previousId = ref.read(openSupplyRequestIdProvider);
  if (previousId != null && previousSignature == signature) return;

  final id = previousId ?? DateTime.now().millisecondsSinceEpoch.toString();
  final existing = ref.read(supplyRepositoryProvider).requests.where((r) => r.id == id);
  ref.read(openSupplyRequestIdProvider.notifier).state = id;
  ref.read(openSupplySignatureProvider.notifier).state = signature;
  ref.read(supplyRepositoryProvider.notifier).upsertRequest(SupplyRequest(
        id: id,
        createdAt: existing.isEmpty ? DateTime.now() : existing.first.createdAt,
        departmentLabel: departmentLabel,
        lines: lines,
      ));
}

void clearOpenSupplyRequest(WidgetRef ref) {
  ref.read(openSupplyRequestIdProvider.notifier).state = null;
  ref.read(openSupplySignatureProvider.notifier).state = null;
}
