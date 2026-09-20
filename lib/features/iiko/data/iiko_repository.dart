import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

class IikoConfig {
  final bool isConnected;
  final String? organizationId;
  final String? organizationName;
  final List<String> storeIds;

  const IikoConfig({
    this.isConnected = false,
    this.organizationId,
    this.organizationName,
    this.storeIds = const [],
  });

  IikoConfig copyWith({
    bool? isConnected,
    String? organizationId,
    String? organizationName,
    List<String>? storeIds,
  }) {
    return IikoConfig(
      isConnected: isConnected ?? this.isConnected,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      storeIds: storeIds ?? this.storeIds,
    );
  }
}

class IikoRepository extends StateNotifier<IikoConfig> {
  final SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();
  // API-логин iiko — это по сути ключ доступа к остаткам/финансовым данным
  // заведения, поэтому храним его в защищённом (шифрованном) хранилище,
  // а не в обычных SharedPreferences.
  static const _apiLoginSecureKey = 'iiko_api_login';
  static const _key = 'iiko_config';

  IikoRepository(this._prefs) : super(const IikoConfig()) {
    _load();
  }

  Future<void> _load() async {
    final orgId = _prefs.getString('${_key}_org_id');
    final orgName = _prefs.getString('${_key}_org_name');
    final stores = _prefs.getStringList('${_key}_stores') ?? [];
    String? apiLogin;
    try {
      apiLogin = await _secureStorage.read(key: _apiLoginSecureKey);
    } catch (_) {
      apiLogin = null;
    }
    state = IikoConfig(
      isConnected: apiLogin != null && apiLogin.isNotEmpty,
      organizationId: orgId,
      organizationName: orgName,
      storeIds: stores,
    );
  }

  Future<String?> getApiLogin() async {
    try {
      return await _secureStorage.read(key: _apiLoginSecureKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConnection({
    required String apiLogin,
    required String organizationId,
    required String organizationName,
  }) async {
    await _secureStorage.write(key: _apiLoginSecureKey, value: apiLogin);
    state = IikoConfig(
      isConnected: true,
      organizationId: organizationId,
      organizationName: organizationName,
      storeIds: state.storeIds,
    );
    await _prefs.setString('${_key}_org_id', organizationId);
    await _prefs.setString('${_key}_org_name', organizationName);
  }

  void setStoreIds(List<String> ids) {
    state = state.copyWith(storeIds: ids);
    _prefs.setStringList('${_key}_stores', ids);
  }

  Future<void> disconnect() async {
    await _secureStorage.delete(key: _apiLoginSecureKey);
    state = const IikoConfig();
    await _prefs.remove('${_key}_org_id');
    await _prefs.remove('${_key}_org_name');
    await _prefs.remove('${_key}_stores');
  }
}

final iikoRepositoryProvider = StateNotifierProvider<IikoRepository, IikoConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return IikoRepository(prefs);
});
