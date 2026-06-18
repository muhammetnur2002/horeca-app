import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestItem {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final String? comment;

  RequestItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    this.comment,
  });

  RequestItem copyWith({double? quantity, String? comment}) {
    return RequestItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unit: unit,
      comment: comment ?? this.comment,
    );
  }
}

class RequestState {
  final int step; // 0-отдел, 1-категория, 2-товары, 3-генерация
  final String? departmentId;
  final String? categoryId;
  final List<RequestItem> items;

  const RequestState({
    this.step = 0,
    this.departmentId,
    this.categoryId,
    this.items = const [],
  });

  RequestState copyWith({
    int? step,
    String? departmentId,
    String? categoryId,
    List<RequestItem>? items,
  }) {
    return RequestState(
      step: step ?? this.step,
      departmentId: departmentId ?? this.departmentId,
      categoryId: categoryId ?? this.categoryId,
      items: items ?? this.items,
    );
  }
}

class RequestStateNotifier extends StateNotifier<RequestState> {
  RequestStateNotifier() : super(const RequestState());

  void selectDepartment(String deptId) {
    // Не очищаем items, чтобы сохранить товары из предыдущих отделов
    state = state.copyWith(departmentId: deptId, step: 1, categoryId: null);
  }

  void selectCategory(String catId) {
    state = state.copyWith(categoryId: catId, step: 2);
  }

  void updateItem(String productId, double newQuantity, {String? productName, String? unit}) {
    final newItems = [...state.items];
    final index = newItems.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      if (newQuantity > 0) {
        newItems[index] = newItems[index].copyWith(quantity: newQuantity);
      } else {
        newItems.removeAt(index);
      }
    } else if (newQuantity > 0) {
      newItems.add(RequestItem(
        productId: productId,
        productName: productName ?? 'Товар $productId',
        quantity: newQuantity,
        unit: unit ?? 'шт',
      ));
    }
    state = state.copyWith(items: newItems);
  }

  void goToGenerate() {
    final validItems = state.items.where((i) => i.quantity > 0).toList();
    state = state.copyWith(items: validItems, step: 3);
  }

  void goBack() {
    if (state.step == 1) {
      state = state.copyWith(step: 0, departmentId: null, categoryId: null);
    } else if (state.step == 2) {
      state = state.copyWith(step: 1, categoryId: null);
    } else if (state.step == 3) {
      state = state.copyWith(step: 2);
    }
  }

  void reset() {
    state = const RequestState();
  }
}

final requestStateProvider = StateNotifierProvider<RequestStateNotifier, RequestState>((ref) {
  return RequestStateNotifier();
});
