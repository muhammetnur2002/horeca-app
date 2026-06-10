import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/pdf_generator/pdf_generator.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class ReportStep extends ConsumerWidget {
  const ReportStep({super.key});

  String _generateReport(InventoryState state, AppLocalizations l10n, String establishmentName) {
    final buffer = StringBuffer();
    buffer.writeln(l10n.reportTitle);
    buffer.writeln('${l10n.date}: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln('${l10n.establishment}: “$establishmentName”');
    buffer.writeln('${l10n.department}: ${state.departmentId}');
    buffer.writeln('');
    for (final item in state.items) {
      buffer.writeln('- ${item.productName}: ${item.remaining} ${item.unit}');
    }
    buffer.writeln('');
    buffer.writeln('${l10n.responsible}: _______________');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(inventoryStateProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final establishmentName = settings.establishmentName;
    final text = _generateReport(state, l10n, establishmentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(historyRepositoryProvider);
      if (!repo.getAll().any((e) => e.type == HistoryType.inventory && e.text == text)) {
        repo.add(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: HistoryType.inventory,
          title: 'Инвентаризация ${state.departmentId}',
          text: text,
          createdAt: DateTime.now(),
        ));
      }
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.preview, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text)).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copySuccess)),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text(l10n.share),
                  onPressed: () => Share.share(text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(l10n.downloadPdf),
              onPressed: () async {
                final pdfBytes = await PdfGenerator.generateInventoryPdf(
                  establishmentName: establishmentName,
                  department: state.departmentId ?? '',
                  items: state.items.map((i) => {
                    'name': i.productName,
                    'remaining': '${i.remaining}',
                    'unit': i.unit,
                  }).toList(),
                  responsiblePerson: '_______________',
                );
                PdfGenerator.downloadFile(pdfBytes, 'inventory_${DateTime.now().millisecondsSinceEpoch}.pdf');
              },
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(inventoryStateProvider.notifier).backToInput(),
            child: Text(l10n.edit),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(inventoryStateProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.newInventory),
          ),
        ],
      ),
    );
  }
}