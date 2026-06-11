import 'dart:async';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = [Locale('ru')];

  static const Map<String, String> _localizedStrings = {
    'appTitle': 'Akyl',
    'makeRequest': 'Сделать заявку',
    'inventory': 'Инвентаризация',
    'history': 'История',
    'settings': 'Настройки',
    'copy': 'Скопировать',
    'share': 'Поделиться',
    'downloadPdf': 'Скачать PDF',
    'edit': 'Редактировать',
    'newRequest': 'Новая заявка',
    'newInventory': 'Новая инвентаризация',
    'preview': 'Предпросмотр',
    'addDepartment': 'Новый отдел',
    'editDepartment': 'Изменить отдел',
    'addCategory': 'Новая категория',
    'editCategory': 'Изменить категорию',
    'addProduct': 'Новый товар',
    'editProduct': 'Изменить товар',
    'bulkAddProducts': 'Массовое добавление',
    'requestTitle': 'Заявка',
    'reportTitle': 'Отчёт об инвентаризации',
    'importExcel': 'Импорт Excel',
    'department': 'Отдел',
    'category': 'Категория',
    'product': 'Товар',
    'quantity': 'Количество',
    'searchProducts': 'Поиск товаров...',
    'noDepartments': 'Нет отделов',
    'noCategories': 'Нет категорий',
    'selectDepartment': 'Сначала выберите отдел',
    'selectCategory': 'Сначала выберите категорию',
    'copySuccess': 'Текст скопирован в буфер обмена',
    'establishmentName': 'Название заведения',
    'clearHistory': 'Очистить историю',
    'historyCleared': 'История очищена',
    'deleteConfirm': 'Вы уверены?',
    'delete': 'Удалить',
    'theme': 'Тема',
    'darkTheme': 'Тёмная тема',
    'darkThemeOn': 'Включена',
    'lightThemeOn': 'Выключена',
    'successDepartmentAdded': 'Отдел добавлен',
    'successDepartmentDeleted': 'Отдел удалён',
    'successDepartmentUpdated': 'Отдел обновлён',
    'successCategoryAdded': 'Категория добавлена',
    'successCategoryDeleted': 'Категория удалена',
    'successCategoryUpdated': 'Категория обновлена',
    'successProductAdded': 'Товар добавлен',
    'successProductDeleted': 'Товар удалён',
    'successProductUpdated': 'Товар обновлён',
    'successProductsBulkAdded': 'Товары добавлены',
    'successHistoryCleared': 'История очищена',
    'errorSync': 'Ошибка синхронизации',
    'errorImport': 'Ошибка импорта',
    'add': 'Добавить',
    'cancel': 'Отмена',
    'save': 'Сохранить',
    'close': 'Закрыть',
    'date': 'Дата',
    'establishment': 'Заведение',
    'responsible': 'Ответственный',
  };

  String translate(String key) => _localizedStrings[key] ?? key;

  String get appTitle => translate('appTitle');
  String get makeRequest => translate('makeRequest');
  String get inventory => translate('inventory');
  String get history => translate('history');
  String get settings => translate('settings');
  String get copy => translate('copy');
  String get share => translate('share');
  String get downloadPdf => translate('downloadPdf');
  String get edit => translate('edit');
  String get newRequest => translate('newRequest');
  String get newInventory => translate('newInventory');
  String get preview => translate('preview');
  String get addDepartment => translate('addDepartment');
  String get editDepartment => translate('editDepartment');
  String get addCategory => translate('addCategory');
  String get editCategory => translate('editCategory');
  String get addProduct => translate('addProduct');
  String get editProduct => translate('editProduct');
  String get bulkAddProducts => translate('bulkAddProducts');
  String get requestTitle => translate('requestTitle');
  String get reportTitle => translate('reportTitle');
  String get importExcel => translate('importExcel');
  String get department => translate('department');
  String get category => translate('category');
  String get product => translate('product');
  String get quantity => translate('quantity');
  String get searchProducts => translate('searchProducts');
  String get noDepartments => translate('noDepartments');
  String get noCategories => translate('noCategories');
  String get selectDepartment => translate('selectDepartment');
  String get selectCategory => translate('selectCategory');
  String get copySuccess => translate('copySuccess');
  String get establishmentName => translate('establishmentName');
  String get clearHistory => translate('clearHistory');
  String get historyCleared => translate('historyCleared');
  String get deleteConfirm => translate('deleteConfirm');
  String get delete => translate('delete');
  String get theme => translate('theme');
  String get darkTheme => translate('darkTheme');
  String get darkThemeOn => translate('darkThemeOn');
  String get lightThemeOn => translate('lightThemeOn');
  String get successDepartmentAdded => translate('successDepartmentAdded');
  String get successDepartmentDeleted => translate('successDepartmentDeleted');
  String get successDepartmentUpdated => translate('successDepartmentUpdated');
  String get successCategoryAdded => translate('successCategoryAdded');
  String get successCategoryDeleted => translate('successCategoryDeleted');
  String get successCategoryUpdated => translate('successCategoryUpdated');
  String get successProductAdded => translate('successProductAdded');
  String get successProductDeleted => translate('successProductDeleted');
  String get successProductUpdated => translate('successProductUpdated');
  String get successProductsBulkAdded => translate('successProductsBulkAdded');
  String get successHistoryCleared => translate('successHistoryCleared');
  String get errorSync => translate('errorSync');
  String get errorImport => translate('errorImport');
  String get add => translate('add');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get close => translate('close');
  String get date => translate('date');
  String get establishment => translate('establishment');
  String get responsible => translate('responsible');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ru';

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}