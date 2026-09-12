import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryItem {
  final String productId;
  final String productName;
  final double remaining;
  final String unit;

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.remaining,
    required this.unit,
  });

  InventoryItem copyWith({double? remaining}) {
    return InventoryItem(
      productId: productId,
      productName: productName,
      remaining: remaining ?? this.remaining,
      unit: unit,
    );
  }
}

class InventoryState {
  final int step;
  final String? departmentId;
  final List<InventoryItem> items;
  final bool isGenerated;
  final List<String> selectedCategoryIds;

  const InventoryState({
    this.step = 0,
    this.departmentId,
    this.items = const [],
    this.isGenerated = false,
    this.selectedCategoryIds = const [],
  });

  InventoryState copyWith({
    int? step,
    String? departmentId,
    List<InventoryItem>? items,
    bool? isGenerated,
    List<String>? selectedCategoryIds,
  }) {
    return InventoryState(
      step: step ?? this.step,
      departmentId: departmentId ?? this.departmentId,
      items: items ?? this.items,
      isGenerated: isGenerated ?? this.isGenerated,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }
}

class InventoryStateNotifier extends StateNotifier<InventoryState> {
  InventoryStateNotifier() : super(const InventoryState());

  void selectDepartment(String deptId, List<String> allCategoryIds) {
    state = InventoryState(
      departmentId: deptId,
      step: 1,
      items: const [],
      isGenerated: false,
      selectedCategoryIds: allCategoryIds,
    );
  }

  void confirmCategories() {
    state = state.copyWith(step: 2);
  }

  void backToCategories() {
    state = state.copyWith(step: 1, isGenerated: false);
  }

  void setSelectedCategories(List<String> ids) {
    state = state.copyWith(selectedCategoryIds: ids);
  }

  /// Вставляет или обновляет позицию инвентаризации.
  /// Значение 0 сохраняется — «пересчитано, остаток нулевой» это тоже
  /// результат, поэтому позиция остаётся в отчёте.
  void updateItem(
    String productId,
    String productName,
    String unit,
    double value,
  ) {
    final safeValue = value < 0 ? 0.0 : value;
    final items = [...state.items];
    final index = items.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      items[index] = InventoryItem(
        productId: productId,
        productName: productName,
        remaining: safeValue,
        unit: unit,
      );
    } else {
      items.add(InventoryItem(
        productId: productId,
        productName: productName,
        remaining: safeValue,
        unit: unit,
      ));
    }
    state = state.copyWith(items: items);
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  void generateReport() {
    state = state.copyWith(isGenerated: true, step: 3);
  }

  void backToInput() {
    state = state.copyWith(isGenerated: false, step: 2);
  }

  void reset() {
    state = const InventoryState();
  }
}

final inventoryStateProvider =
    StateNotifierProvider<InventoryStateNotifier, InventoryState>((ref) {
  return InventoryStateNotifier();
});




