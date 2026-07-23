import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

class IikoConfig {
  final String? apiLogin;
  final String? organizationId;
  final String? organizationName;
  final List<String> storeIds;

  const IikoConfig({
    this.apiLogin,
    this.organizationId,
    this.organizationName,
    this.storeIds = const [],
  });

  bool get isConnected => apiLogin != null && apiLogin!.isNotEmpty;

  IikoConfig copyWith({
    String? apiLogin,
    String? organizationId,
    String? organizationName,
    List<String>? storeIds,
  }) {
    return IikoConfig(
      apiLogin: apiLogin ?? this.apiLogin,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      storeIds: storeIds ?? this.storeIds,
    );
  }
}

class IikoRepository extends StateNotifier<IikoConfig> {
  final SharedPreferences _prefs;
  static const _key = 'iiko_config';

  IikoRepository(this._prefs) : super(const IikoConfig()) {
    _load();
  }

  void _load() {
    final login = _prefs.getString('${_key}_login');
    final orgId = _prefs.getString('${_key}_org_id');
    final orgName = _prefs.getString('${_key}_org_name');
    final stores = _prefs.getStringList('${_key}_stores') ?? [];
    state = IikoConfig(
      apiLogin: login,
      organizationId: orgId,
      organizationName: orgName,
      storeIds: stores,
    );
  }

  void saveConnection({
    required String apiLogin,
    required String organizationId,
    required String organizationName,
  }) {
    state = IikoConfig(
      apiLogin: apiLogin,
      organizationId: organizationId,
      organizationName: organizationName,
      storeIds: state.storeIds,
    );
    _prefs.setString('${_key}_login', apiLogin);
    _prefs.setString('${_key}_org_id', organizationId);
    _prefs.setString('${_key}_org_name', organizationName);
  }

  void setStoreIds(List<String> ids) {
    state = state.copyWith(storeIds: ids);
    _prefs.setStringList('${_key}_stores', ids);
  }

  void disconnect() {
    state = const IikoConfig();
    _prefs.remove('${_key}_login');
    _prefs.remove('${_key}_org_id');
    _prefs.remove('${_key}_org_name');
    _prefs.remove('${_key}_stores');
  }
}

final iikoRepositoryProvider = StateNotifierProvider<IikoRepository, IikoConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return IikoRepository(prefs);
});



