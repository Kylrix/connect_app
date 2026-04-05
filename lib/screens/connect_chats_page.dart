import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import '../core/models/connect_models.dart';
import '../widgets/connect_dialogs.dart';

class ConnectChatsPage extends StatelessWidget {
  const ConnectChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        if (narrow) {
          if (store.selectedConversation == null) {
            return _ConversationList(narrow: true);
          }
          return ConnectChatView(conversation: store.selectedConversation!);
        }

        return Row(
          children: [
            SizedBox(width: 320, child: _ConversationList(narrow: false)),
            const VerticalDivider(width: 1),
            Expanded(
              child: store.selectedConversation == null
                  ? const Center(child: Text('Pick a conversation to continue.'))
                  : ConnectChatView(conversation: store.selectedConversation!),
            ),
          ],
        );
      },
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.narrow});

  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text('Chats', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              IconButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const NewChatDialog(),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: store.conversations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conversation = store.conversations[index];
              return Card(
                child: ListTile(
                  selected: store.selectedConversationId == conversation.id,
                  onTap: () => context.read<ConnectStore>().openConversation(conversation.id),
                  leading: CircleAvatar(
                    child: Text(conversation.name.isEmpty ? 'C' : conversation.name[0].toUpperCase()),
                  ),
                  title: Text(conversation.name),
                  subtitle: Text(conversation.lastMessage.isEmpty ? 'No messages yet' : conversation.lastMessage),
                  trailing: conversation.unreadCount > 0 ? Badge(label: Text('${conversation.unreadCount}')) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConnectChatView extends StatefulWidget {
  const ConnectChatView({super.key, required this.conversation});
  final ConnectConversation conversation;

  @override
  State<ConnectChatView> createState() => _ConnectChatViewState();
}

class _ConnectChatViewState extends State<ConnectChatView> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final conversation = widget.conversation;
    final messages = store.messages.where((msg) => msg.conversationId == conversation.id).toList(growable: false);
    final isSelf = conversation.isSelf;

    if (store.settings.isLocked) {
      return const Center(child: Text('Unlock Connect to read encrypted chats.'));
    }

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(child: Text(conversation.name.isEmpty ? 'C' : conversation.name[0].toUpperCase())),
            title: Text(conversation.name),
            subtitle: Text(conversation.isEncrypted ? 'Secure chat' : 'Plain chat'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'note') {
                  showDialog(
                    context: context,
                    builder: (_) => const NoteSelectorDialog(),
                  ).then((result) {
                    if (result is ConnectTarget) {
                      context.read<ConnectStore>().sendMessage(
                            conversationId: conversation.id,
                            content: result.label,
                            type: MessageType.note,
                            attachmentLabel: result.label,
                            metadata: {'targetId': result.id, 'kind': result.type},
                          );
                    }
                  });
                } else if (value == 'secret') {
                  showDialog(
                    context: context,
                    builder: (_) => SecretSelectorDialog(isSelfConversation: isSelf),
                  ).then((result) {
                    if (result is ConnectTarget) {
                      final type = result.type == 'totp' ? MessageType.totp : MessageType.secret;
                      context.read<ConnectStore>().sendMessage(
                            conversationId: conversation.id,
                            content: result.label,
                            type: type,
                            attachmentLabel: result.label,
                            metadata: {'targetId': result.id, 'kind': result.type},
                          );
                    }
                  });
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'note', child: Text('Attach note')),
                PopupMenuItem(value: 'secret', child: Text('Attach secret')),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final mine = message.senderId == store.session.userId;
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: const BoxConstraints(maxWidth: 480),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFF3A2A0A) : const Color(0xFF161412),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.senderName, style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Text(message.content),
                      if (message.attachmentLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Attachment: ${message.attachmentLabel}', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const NoteSelectorDialog(),
                  ).then((result) {
                    if (result is ConnectTarget) {
                      context.read<ConnectStore>().sendMessage(
                            conversationId: conversation.id,
                            content: result.label,
                            type: MessageType.note,
                            attachmentLabel: result.label,
                            metadata: {'targetId': result.id, 'kind': result.type},
                          );
                    }
                  }),
                  icon: const Icon(Icons.sticky_note_2_outlined),
                ),
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => SecretSelectorDialog(isSelfConversation: isSelf),
                  ).then((result) {
                    if (result is ConnectTarget) {
                      final type = result.type == 'totp' ? MessageType.totp : MessageType.secret;
                      context.read<ConnectStore>().sendMessage(
                            conversationId: conversation.id,
                            content: result.label,
                            type: type,
                            attachmentLabel: result.label,
                            metadata: {'targetId': result.id, 'kind': result.type},
                          );
                    }
                  }),
                  icon: const Icon(Icons.vpn_key_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;
                      context.read<ConnectStore>().sendMessage(
                            conversationId: conversation.id,
                            content: value.trim(),
                            type: MessageType.text,
                          );
                      controller.clear();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    context.read<ConnectStore>().sendMessage(
                          conversationId: conversation.id,
                          content: value,
                          type: MessageType.text,
                        );
                    controller.clear();
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
