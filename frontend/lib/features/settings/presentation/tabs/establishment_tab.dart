import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class EstablishmentTab extends ConsumerWidget {
  const EstablishmentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = ref.watch(settingsRepositoryProvider).establishmentName;
    final repo = ref.read(settingsRepositoryProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(l10n.establishmentName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: Text(l10n.edit),
              onPressed: () {
                final ctrl = TextEditingController(text: name);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.establishmentName),
                    content: TextField(controller: ctrl, decoration: InputDecoration(hintText: l10n.establishmentName)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                      ElevatedButton(
                        onPressed: () {
                          if (ctrl.text.isNotEmpty) {
                            repo.setEstablishmentName(ctrl.text);
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}