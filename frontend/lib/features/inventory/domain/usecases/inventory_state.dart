import 'package:flutter_riverpod/flutter_riverpod.dart';
class InventoryItem {
  final String productId; final String productName; final double remaining; final String unit;
  InventoryItem({required this.productId, required this.productName, required this.remaining, required this.unit});
  InventoryItem copyWith({double? remaining}) => InventoryItem(productId: productId, productName: productName, remaining: remaining ?? this.remaining, unit: unit);
}
class InventoryState {
  final String? departmentId; final List<InventoryItem> items; final bool isGenerated;
  const InventoryState({this.departmentId, this.items = const [], this.isGenerated = false});
  InventoryState copyWith({String? departmentId, List<InventoryItem>? items, bool? isGenerated}) => InventoryState(departmentId: departmentId ?? this.departmentId, items: items ?? this.items, isGenerated: isGenerated ?? this.isGenerated);
}
class InventoryStateNotifier extends StateNotifier<InventoryState> {
  InventoryStateNotifier() : super(const InventoryState());
  void selectDepartment(String deptId) { state = state.copyWith(departmentId: deptId, items: [], isGenerated: false); }
  void initItems(List<InventoryItem> items) { state = state.copyWith(items: items); }
  void updateRemaining(String productId, double newValue) {
    final newItems = state.items.map((item) => item.productId == productId ? item.copyWith(remaining: newValue) : item).toList();
    state = state.copyWith(items: newItems);
  }
  void generateReport() { state = state.copyWith(isGenerated: true); }
  void backToInput() { state = state.copyWith(isGenerated: false); }
  void reset() { state = const InventoryState(); }
}
final inventoryStateProvider = StateNotifierProvider<InventoryStateNotifier, InventoryState>((ref) => InventoryStateNotifier());
