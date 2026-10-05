/// Настройка распознавания накладных: ключ Gemini API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/stock/data/gemini_invoice_service.dart';
import 'package:horeca_app/features/stock/presentation/stock_widgets.dart';

class GeminiSettingsScreen extends ConsumerStatefulWidget {
  const GeminiSettingsScreen({super.key});

  @override
  ConsumerState<GeminiSettingsScreen> createState() =>
      _GeminiSettingsScreenState();
}

class _GeminiSettingsScreenState extends ConsumerState<GeminiSettingsScreen> {
  final _ctrl = TextEditingController();
  bool _hasKey = false;
  bool _busy = false;
  bool _obscure = true;
  String? _status;
  bool _statusOk = false;

  @override
  void initState() {
    super.initState();
    ref.read(geminiKeyStoreProvider).read().then((k) {
      if (!mounted) return;
      setState(() => _hasKey = k != null);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    final error = await ref.read(geminiInvoiceServiceProvider).checkKey(key);
    if (!mounted) return;
    if (error == null) {
      await ref.read(geminiKeyStoreProvider).write(key);
      _ctrl.clear();
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusOk = error == null;
      _status = error ?? 'Ключ сохранён и работает.';
      if (error == null) _hasKey = true;
    });
  }

  Future<void> _delete() async {
    await ref.read(geminiKeyStoreProvider).delete();
    if (!mounted) return;
    setState(() {
      _hasKey = false;
      _status = 'Ключ удалён с устройства.';
      _statusOk = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    TextStyle body = TextStyle(fontSize: 13.5, height: 1.4, color: textColor);

    return StockScaffold(
      title: 'Распознавание накладных',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gemini 2.5 Flash',
                    style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'При приёмке поставки сфотографируйте накладную или чек — '
                  'Gemini прочитает строки, количества и цены, а Akyl '
                  'сопоставит их с вашим каталогом. Всё можно поправить '
                  'вручную перед сохранением.',
                  style: body,
                ),
                const SizedBox(height: 10),
                Text(
                  'Фото отправляется в Google Gemini только при нажатии '
                  '«Фото → строки». Ключ хранится в защищённом хранилище '
                  'телефона и никуда больше не передаётся.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    _hasKey ? Icons.check_circle_rounded : Icons.key_outlined,
                    color: _hasKey ? AppColors.green : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(_hasKey ? 'Ключ задан' : 'Ключ не задан',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: textColor)),
                  const Spacer(),
                  if (_hasKey)
                    TextButton(
                      onPressed: _busy ? null : _delete,
                      child: const Text('Удалить',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: _hasKey ? 'Новый ключ API' : 'Ключ API',
                    hintText: 'AIza…',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StockPrimaryButton(
                  label: _busy ? 'Проверяю…' : 'Проверить и сохранить',
                  icon: Icons.verified_outlined,
                  onPressed: _busy ? null : _save,
                ),
                if (_status != null) ...[
                  const SizedBox(height: 10),
                  Text(_status!,
                      style: TextStyle(
                          fontSize: 13,
                          color: _statusOk
                              ? AppColors.green
                              : Colors.redAccent)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Где взять ключ',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  '1. Откройте aistudio.google.com и войдите в аккаунт Google.\n'
                  '2. Нажмите «Get API key» → «Create API key».\n'
                  '3. Скопируйте ключ (начинается с «AIza») и вставьте сюда.\n\n'
                  'Бесплатного лимита Google обычно хватает на десятки '
                  'накладных в день. В некоторых странах Gemini API '
                  'недоступен — тогда проверка ключа сообщит об ошибке.',
                  style: body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
