import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import '../core/models/connect_models.dart';

class ConnectPortalDialog extends StatelessWidget {
  const ConnectPortalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final apps = const [
      ('Accounts', Icons.verified_user_outlined),
      ('Vault', Icons.vpn_key_outlined),
      ('Note', Icons.sticky_note_2_outlined),
      ('Flow', Icons.timeline_outlined),
      ('Connect', Icons.chat_bubble_outline),
    ];
    return AlertDialog(
      title: const Text('Ecosystem portal'),
      content: SizedBox(
        width: 420,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: apps
              .map(
                (app) => SizedBox(
                  width: 120,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(app.$2),
                          const SizedBox(height: 8),
                          Text(app.$1),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    );
  }
}

class ConnectSearchDialog extends StatefulWidget {
  const ConnectSearchDialog({super.key});

  @override
  State<ConnectSearchDialog> createState() => _ConnectSearchDialogState();
}

class _ConnectSearchDialogState extends State<ConnectSearchDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final results = store.searchUsers(controller.text);
    return AlertDialog(
      title: const Text('Search people'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ...results.map(
              (profile) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(profile.shortName),
                subtitle: Text(profile.email),
                onTap: () {
                  context.read<ConnectStore>().createConversation(profile);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    );
  }
}

class NoteSelectorDialog extends StatelessWidget {
  const NoteSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return AlertDialog(
      title: const Text('Attach note'),
      content: SizedBox(
        width: 480,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: store.notes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final note = store.notes[index];
            return Card(
              child: ListTile(
                title: Text(note.label),
                subtitle: Text(note.subtitle),
                onTap: () => Navigator.of(context).pop(note),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SecretSelectorDialog extends StatefulWidget {
  const SecretSelectorDialog({super.key, required this.isSelfConversation});
  final bool isSelfConversation;

  @override
  State<SecretSelectorDialog> createState() => _SecretSelectorDialogState();
}

class _SecretSelectorDialogState extends State<SecretSelectorDialog> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final items = tab == 0 ? store.secrets : store.secrets.where((item) => item.type == 'totp').toList(growable: false);
    return AlertDialog(
      title: const Text('Attach secret'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Secrets')),
                ButtonSegment(value: 1, label: Text('TOTP')),
              ],
              selected: {tab},
              onSelectionChanged: (values) => setState(() => tab = values.first),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Card(
                child: ListTile(
                  enabled: tab == 1 || widget.isSelfConversation,
                  title: Text(item.label),
                  subtitle: Text(item.subtitle),
                  trailing: tab == 0 && !widget.isSelfConversation ? const Text('Self only') : null,
                  onTap: tab == 0 && !widget.isSelfConversation
                      ? null
                      : () => Navigator.of(context).pop(item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final results = store.searchUsers(controller.text);
    return AlertDialog(
      title: const Text('New chat'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Search people'),
            ),
            const SizedBox(height: 16),
            ...results.map(
              (profile) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(profile.shortName),
                subtitle: Text(profile.bio),
                onTap: () {
                  context.read<ConnectStore>().createConversation(profile);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewCallDialog extends StatefulWidget {
  const NewCallDialog({super.key});

  @override
  State<NewCallDialog> createState() => _NewCallDialogState();
}

class _NewCallDialogState extends State<NewCallDialog> {
  final controller = TextEditingController();
  CallType callType = CallType.video;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return AlertDialog(
      title: const Text('New call'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Call title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<CallType>(
              initialValue: callType,
              items: const [
                DropdownMenuItem(value: CallType.video, child: Text('Video')),
                DropdownMenuItem(value: CallType.audio, child: Text('Audio')),
              ],
              onChanged: (value) => setState(() => callType = value ?? CallType.video),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            store.createCall(
              title: controller.text.isEmpty ? 'New Call' : controller.text,
              type: callType,
              conversationId: store.selectedConversationId ?? store.conversations.first.id,
              isLink: true,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class ConnectQuickActions extends StatelessWidget {
  const ConnectQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (value) {
        if (value == 'chat') {
          showDialog<void>(context: context, builder: (_) => const NewChatDialog());
        } else if (value == 'call') {
          showDialog<void>(context: context, builder: (_) => const NewCallDialog());
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'chat', child: Text('New chat')),
        PopupMenuItem(value: 'call', child: Text('New call')),
      ],
    );
  }
}
