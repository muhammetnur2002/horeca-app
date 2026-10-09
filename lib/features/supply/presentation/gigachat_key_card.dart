import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/ocr_quota.dart';

class GigaChatKeyCard extends StatefulWidget {
  final bool isDark;
  const GigaChatKeyCard({super.key, required this.isDark});

  @override
  State<GigaChatKeyCard> createState() => _GigaChatKeyCardState();
}

class _GigaChatKeyCardState extends State<GigaChatKeyCard> {
  final _controller = TextEditingController();
  bool _hasKey = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await SupplyRepository.readGigaChatKey();
    if (!mounted) return;
    setState(() {
      _hasKey = key != null;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await SupplyRepository.saveGigaChatKey(_controller.text);
    _controller.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_hasKey ? 'Ключ GigaChat сохранён на этом телефоне.' : 'Ключ убран.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.radius),
        color: Colors.white.withOpacity(widget.isDark ? 0.06 : 0.55),
        border: Border.all(color: AppColors.orange.withOpacity(0.28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Накладные', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 6),
        Text(
          _ready
              ? (_hasKey
                  ? 'Ключ GigaChat на телефоне есть. В день не больше ${OcrQuota.dailyLimit} фото на заведение.'
                  : 'Ключа нет. Накладную можно вводить руками. Ключ авторизации GigaChat вставьте сюда, в код он не пишется.')
              : 'Проверяю ключ…',
          style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Ключ авторизации',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _save, child: const Text('Сохранить ключ')),
        ),
      ]),
    );
  }
}
