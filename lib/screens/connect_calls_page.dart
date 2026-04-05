import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import '../core/models/connect_models.dart';
import '../widgets/connect_dialogs.dart';

class ConnectCallsPage extends StatelessWidget {
  const ConnectCallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final active = store.selectedCall;

        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text('Calls', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const NewCallDialog(),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Join with ID or URL',
                  prefixIcon: Icon(Icons.tag),
                ),
                onSubmitted: (value) {
                  final id = value.contains('/call/') ? value.split('/call/').last : value;
                  if (id.trim().isNotEmpty) {
                    context.read<ConnectStore>().openCall(id.trim());
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: store.calls.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final call = store.calls[index];
                  return Card(
                    child: ListTile(
                      selected: active?.id == call.id,
                      onTap: () => context.read<ConnectStore>().openCall(call.id),
                      title: Text(call.title),
                      subtitle: Text('${call.type.name} • ${call.status.name}'),
                      trailing: Text(call.isLink ? 'Link' : 'Direct'),
                    ),
                  );
                },
              ),
            ),
          ],
        );

        if (narrow) {
          return active == null ? list : ConnectCallRoom(call: active);
        }

        return Row(
          children: [
            SizedBox(width: 360, child: list),
            const VerticalDivider(width: 1),
            Expanded(
              child: active == null ? const Center(child: Text('Select a call to inspect it.')) : ConnectCallRoom(call: active),
            ),
          ],
        );
      },
    );
  }
}

class ConnectCallRoom extends StatefulWidget {
  const ConnectCallRoom({super.key, required this.call});
  final ConnectCall call;

  @override
  State<ConnectCallRoom> createState() => _ConnectCallRoomState();
}

class _ConnectCallRoomState extends State<ConnectCallRoom> {
  bool muted = false;
  bool videoOff = false;
  bool sharing = false;
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final call = widget.call;
    ConnectConversation? conversation;
    for (final item in store.conversations) {
      if (item.id == call.conversationId) {
        conversation = item;
        break;
      }
    }
    final messages = store.messages.where((item) => item.conversationId == call.conversationId).toList(growable: false);

    return Column(
      children: [
        ListTile(
          title: Text(call.title),
          subtitle: Text('${call.type.name} • ${call.status.name}'),
          trailing: FilledButton(
            onPressed: () => context.read<ConnectStore>().updateCallStatus(call.id, CallStatus.completed),
            child: const Text('End'),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilterChip(label: Text(muted ? 'Muted' : 'Mic on'), selected: muted, onSelected: (value) => setState(() => muted = value)),
                      FilterChip(label: Text(videoOff ? 'Video off' : 'Video on'), selected: videoOff, onSelected: (value) => setState(() => videoOff = value)),
                      FilterChip(label: Text(sharing ? 'Sharing' : 'Share screen'), selected: sharing, onSelected: (value) => setState(() => sharing = value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('In-call chat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...messages.map(
                (message) => Card(
                  child: ListTile(
                    title: Text(message.senderName),
                    subtitle: Text(message.content),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (conversation != null)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'Send call chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        context.read<ConnectStore>().sendMessage(
                              conversationId: conversation.id,
                              content: text,
                              type: MessageType.text,
                            );
                        controller.clear();
                      },
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
