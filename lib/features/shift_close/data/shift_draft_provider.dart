import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

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

  bool get hasUserInput =>
      step > 0 ||
      selectedStaff.isNotEmpty ||
      desserts.any((d) => d.showcase != 0 || d.stock != 0 || d.writeOff != 0) ||
      manualWriteOffs.isNotEmpty ||
      qr.isNotEmpty ||
      card.isNotEmpty ||
      cash.isNotEmpty ||
      manual.isNotEmpty ||
      morningCash.isNotEmpty ||
      eveningCash.isNotEmpty ||
      inkass.isNotEmpty ||
      hasInkass;

  Map<String, dynamic> toJson() => {
        'step': step,
        'selectedStaff': selectedStaff.toList(),
        'dessertsLoaded': dessertsLoaded,
        'desserts': desserts
            .map((d) => {
                  'name': d.name,
                  'showcase': d.showcase,
                  'stock': d.stock,
                  'writeOff': d.writeOff,
                })
            .toList(),
        'manualWriteOffs': manualWriteOffs
            .map((m) => {
                  'name': m.name,
                  'quantity': m.quantity,
                  'unit': m.unit,
                })
            .toList(),
        'qr': qr,
        'card': card,
        'cash': cash,
        'manual': manual,
        'morningCash': morningCash,
        'eveningCash': eveningCash,
        'inkass': inkass,
        'hasInkass': hasInkass,
      };

  factory ShiftDraft.fromJson(Map<String, dynamic> json) {
    final desserts = (json['desserts'] as List? ?? [])
        .whereType<Map>()
        .map((raw) => DessertItem(
              name: raw['name'] as String? ?? '',
              showcase: (raw['showcase'] as num?)?.toInt() ?? 0,
              stock: (raw['stock'] as num?)?.toInt() ?? 0,
              writeOff: (raw['writeOff'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    final manual = (json['manualWriteOffs'] as List? ?? [])
        .whereType<Map>()
        .map((raw) => ManualWriteOff(
              name: raw['name'] as String? ?? '',
              quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
              unit: raw['unit'] as String? ?? 'шт',
            ))
        .toList();
    return ShiftDraft(
      step: (json['step'] as num?)?.toInt() ?? 0,
      selectedStaff: ((json['selectedStaff'] as List?) ?? []).whereType<String>().toSet(),
      desserts: desserts,
      dessertsLoaded: json['dessertsLoaded'] as bool? ?? desserts.isNotEmpty,
      manualWriteOffs: manual,
      qr: json['qr'] as String? ?? '',
      card: json['card'] as String? ?? '',
      cash: json['cash'] as String? ?? '',
      manual: json['manual'] as String? ?? '',
      morningCash: json['morningCash'] as String? ?? '',
      eveningCash: json['eveningCash'] as String? ?? '',
      inkass: json['inkass'] as String? ?? '',
      hasInkass: json['hasInkass'] as bool? ?? false,
    );
  }
}

class ShiftDraftNotifier extends StateNotifier<ShiftDraft> {
  final SharedPreferences _prefs;
  final String _key;

  ShiftDraftNotifier(this._prefs, String venueCode)
      : _key = 'shift_draft${venueKeySuffix(venueCode)}',
        super(ShiftDraft()) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      state = ShiftDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      state = ShiftDraft();
    }
  }

  void reset() {
    state = ShiftDraft();
    _prefs.remove(_key);
  }

  void save(ShiftDraft draft) {
    state = draft;
    if (!draft.hasUserInput) {
      _prefs.remove(_key);
      return;
    }
    _prefs.setString(_key, jsonEncode(draft.toJson()));
  }
}

final shiftDraftProvider = StateNotifierProvider<ShiftDraftNotifier, ShiftDraft>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final venueCode = ref.watch(venueRepositoryProvider).activeVenueCode;
  return ShiftDraftNotifier(prefs, venueCode);
});
