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
  final int step; // 0-отдел, 1-категории, 2-ввод остатков, 3-отчёт
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
    state = state.copyWith(
      departmentId: deptId,
      step: 1,
      items: [],
      isGenerated: false,
      selectedCategoryIds: allCategoryIds,
    );
  }

  void confirmCategories() {
    state = state.copyWith(step: 2);
  }

  void setSelectedCategories(List<String> ids) {
    state = state.copyWith(selectedCategoryIds: ids);
  }

  void initItems(List<InventoryItem> items) {
    state = state.copyWith(items: items);
  }

  void updateRemaining(String productId, double newValue) {
    final newItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(remaining: newValue);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
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