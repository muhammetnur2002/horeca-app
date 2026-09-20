import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';

class ShiftDraft {
  int step;
  Set<String> selectedStaff;
  List<DessertItem> desserts;
  bool dessertsLoaded;
  List<ManualWriteOff> manualWriteOffs;
  String qr, card, cash, manual, morningCash, eveningCash, inkass;
  bool hasInkass;

  ShiftDraft({
    this.step = 0,
    Set<String>? selectedStaff,
    List<DessertItem>? desserts,
    this.dessertsLoaded = false,
    List<ManualWriteOff>? manualWriteOffs,
    this.qr = '',
    this.card = '',
    this.cash = '',
    this.manual = '',
    this.morningCash = '',
    this.eveningCash = '',
    this.inkass = '',
    this.hasInkass = false,
  })  : selectedStaff = selectedStaff ?? {},
        desserts = desserts ?? [],
        manualWriteOffs = manualWriteOffs ?? [];
}

class ShiftDraftNotifier extends StateNotifier<ShiftDraft> {
  ShiftDraftNotifier() : super(ShiftDraft());

  void reset() {
    state = ShiftDraft();
  }

  void save(ShiftDraft draft) {
    state = draft;
  }
}

final shiftDraftProvider = StateNotifierProvider<ShiftDraftNotifier, ShiftDraft>((ref) {
  return ShiftDraftNotifier();
});
