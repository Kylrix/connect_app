import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import '../core/models/connect_models.dart';

class ConnectSettingsPage extends StatelessWidget {
  const ConnectSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            value: store.settings.isLocked,
            onChanged: (_) => context.read<ConnectStore>().toggleLock(),
            title: const Text('Vault lock'),
            subtitle: const Text('Lock Connect secure chat and sharing.'),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: store.settings.showPortal,
            onChanged: (value) => context.read<ConnectStore>().updateSettings(
                  ConnectSettings(
                    isLocked: store.settings.isLocked,
                    showPortal: value,
                    enablePush: store.settings.enablePush,
                    showActiveStatus: store.settings.showActiveStatus,
                    allowMessages: store.settings.allowMessages,
                    allowCalls: store.settings.allowCalls,
                    allowShares: store.settings.allowShares,
                    discoverability: store.settings.discoverability,
                  ),
                ),
            title: const Text('Show ecosystem portal'),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: store.settings.showActiveStatus,
            onChanged: (value) => context.read<ConnectStore>().updateSettings(
                  ConnectSettings(
                    isLocked: store.settings.isLocked,
                    showPortal: store.settings.showPortal,
                    enablePush: store.settings.enablePush,
                    showActiveStatus: value,
                    allowMessages: store.settings.allowMessages,
                    allowCalls: store.settings.allowCalls,
                    allowShares: store.settings.allowShares,
                    discoverability: store.settings.discoverability,
                  ),
                ),
            title: const Text('Active status'),
          ),
        ),
        const SizedBox(height: 12),
        Text('Passkeys', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...store.passkeys.map(
          (passkey) => Card(
            child: ListTile(
              leading: const Icon(Icons.fingerprint_outlined),
              title: Text(passkey.name),
              trailing: passkey.active ? const Text('Active') : const Text('Disabled'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Discoverability', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<Discoverability>(
          segments: const [
            ButtonSegment(value: Discoverability.public, label: Text('Public')),
            ButtonSegment(value: Discoverability.private, label: Text('Private')),
            ButtonSegment(value: Discoverability.friendsOnly, label: Text('Friends')),
          ],
          selected: {store.settings.discoverability},
          onSelectionChanged: (values) => context.read<ConnectStore>().updateSettings(
                ConnectSettings(
                  isLocked: store.settings.isLocked,
                  showPortal: store.settings.showPortal,
                  enablePush: store.settings.enablePush,
                  showActiveStatus: store.settings.showActiveStatus,
                  allowMessages: store.settings.allowMessages,
                  allowCalls: store.settings.allowCalls,
                  allowShares: store.settings.allowShares,
                  discoverability: values.first,
                ),
                ),
              ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bolt_outlined),
            title: const Text('Repair permissions'),
            subtitle: const Text('Rebuild shared-item access from the connected Accounts API.'),
            onTap: () => context.read<ConnectStore>().reclaimGhostNotes().then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permission repair requested')),
              );
            }).catchError((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permission repair failed')),
              );
            }),
          ),
        ),
      ],
    );
  }
}
