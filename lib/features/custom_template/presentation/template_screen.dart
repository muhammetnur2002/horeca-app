import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/custom_template/data/excel_parser.dart';
import 'package:horeca_app/features/custom_template/data/field_matcher.dart';
import 'package:horeca_app/features/custom_template/data/template_models.dart';
import 'package:horeca_app/features/custom_template/data/template_repository.dart';

class TemplateScreen extends ConsumerStatefulWidget {
  const TemplateScreen({super.key});
  @override
  ConsumerState<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends ConsumerState<TemplateScreen> {
  ParsedTemplate? _parsed;
  List<ColumnMapping> _mappings = [];
  bool _loading = false;
  bool _aiLoading = false;
  bool _aiTried = false;
  String? _error;

  Future<void> _pickFile() async {
    setState(() { _loading = true; _error = null; });
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.single.path == null) {
      setState(() => _loading = false);
      return;
    }

    final parsed = await ExcelParser.parseFile(result.files.single.path!);
    if (parsed == null) {
      setState(() {
        _error = 'Не удалось прочитать файл. Убедитесь, что это Excel-файл с заголовками в первой строке.';
        _loading = false;
      });
      return;
    }

    final mappings = FieldMatcher.autoMatchColumns(parsed.headers);
    setState(() {
      _parsed = parsed;
      _mappings = mappings;
      _loading = false;
    });
  }

Future<void> _tryAiImprove() async {
  if (_parsed == null) return;
  setState(() => _aiLoading = true);
  final aiMappings = await FieldMatcher.tryAiMatch(_parsed!.headers);
  setState(() {
    _aiLoading = false;
    _aiTried = true;
    if (aiMappings != null) {
      _mappings = aiMappings;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Сопоставление улучшено через AI', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF378ADD),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Не удалось подключиться к AI. Используется офлайн-словарь', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
    }
  });
}
  void _saveTemplate() {
    if (_parsed == null) return;
    final template = CustomTemplate(
      name: _parsed!.sheetName,
      columns: _mappings,
      createdAt: DateTime.now(),
    );
    ref.read(templateRepositoryProvider.notifier).saveTemplate(template);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Шаблон сохранён', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final currentTemplate = ref.watch(templateRepositoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Свой шаблон PDF',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          if (currentTemplate != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () {
                ref.read(templateRepositoryProvider.notifier).removeTemplate();
                setState(() { _parsed = null; _mappings = []; });
              },
            ),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (currentTemplate != null && _parsed == null) ...[
                _ActiveTemplateCard(template: currentTemplate, isDark: isDark),
                const SizedBox(height: 16),
              ],

              if (_parsed == null) ...[
                Text(
                  'Загрузите свой Excel-файл с шаблоном инвентаризации. '
                  'Мы автоматически распознаем колонки — вы сможете проверить и подтвердить.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _loading ? null : _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.orange.withOpacity(0.1),
                      border: Border.all(color: AppColors.orange.withOpacity(0.3), style: BorderStyle.solid)),
                    child: Column(children: [
                      _loading
                          ? const CircularProgressIndicator(color: AppColors.orange)
                          : const Icon(Icons.upload_file_rounded, color: AppColors.orange, size: 36),
                      const SizedBox(height: 10),
                      Text(_loading ? 'Загрузка...' : 'Выбрать Excel-файл',
                          style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ] else ...[
  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Expanded(child: Text('Проверьте сопоставление колонок',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
    if (!_aiTried)
      GestureDetector(
        onTap: _aiLoading ? null : _tryAiImprove,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF378ADD).withOpacity(0.15),
            border: Border.all(color: const Color(0xFF378ADD).withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _aiLoading
                ? const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF378ADD)))
                : const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF378ADD)),
            const SizedBox(width: 6),
            const Text('Улучшить через AI', style: TextStyle(fontSize: 11, color: Color(0xFF378ADD), fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
  ]),
  const SizedBox(height: 6),
  Text('Лист: ${_parsed!.sheetName}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
  const SizedBox(height: 16),
                ..._mappings.map((m) => _MappingRow(
                  mapping: m, isDark: isDark,
                  onChanged: (field) => setState(() => m.mappedField = field),
                )),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() { _parsed = null; _mappings = []; }),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.muted.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Отмена', style: TextStyle(color: AppColors.muted)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: _saveTemplate,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Сохранить шаблон', style: TextStyle(fontWeight: FontWeight.w600)),
                  )),
                ]),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ActiveTemplateCard extends StatelessWidget {
  final CustomTemplate template;
  final bool isDark;
  const _ActiveTemplateCard({required this.template, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.green.withOpacity(isDark ? 0.1 : 0.06),
            border: Border.all(color: AppColors.green.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Активный шаблон: ${template.name}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              Text('${template.columns.length} колонок настроено',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _MappingRow extends StatelessWidget {
  final ColumnMapping mapping;
  final bool isDark;
  final ValueChanged<TemplateField> onChanged;
  const _MappingRow({required this.mapping, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final autoMatched = mapping.confidence > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('«${mapping.originalHeader}»',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
          if (autoMatched)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('авто', style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<TemplateField>(
          value: mapping.mappedField,
          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
          items: TemplateField.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
          onChanged: (v) => onChanged(v!),
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ]),
    );
  }
}