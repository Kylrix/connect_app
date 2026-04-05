import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import '../core/models/connect_models.dart';
import '../widgets/connect_bottom_nav.dart';
import '../widgets/connect_dialogs.dart';
import '../widgets/connect_feed_page.dart';
import '../widgets/connect_top_bar.dart';
import 'connect_calls_page.dart';
import 'connect_chats_page.dart';
import 'connect_settings_page.dart';

class ConnectShell extends StatelessWidget {
  const ConnectShell({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    final pages = <Widget>[
      const ConnectFeedPage(),
      const ConnectChatsPage(),
      const ConnectCallsPage(),
      const ConnectSettingsPage(),
    ];

    if (store.settings.isLocked) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 48),
                      const SizedBox(height: 16),
                      Text('Connect is locked', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text('Unlock the vault to access chats, calls, and secure sharing.'),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => context.read<ConnectStore>().unlock(),
                        child: const Text('Unlock'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              const SizedBox(width: 300, child: ConnectSidebar()),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    const ConnectTopBar(),
                    Expanded(child: IndexedStack(index: store.tab.index, children: pages)),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              const SizedBox(width: 360, child: ConnectDetailsPanel()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: ConnectTopBar(),
      ),
      body: IndexedStack(index: store.tab.index, children: pages),
      bottomNavigationBar: const ConnectBottomNav(),
      floatingActionButton: const ConnectQuickActions(),
    );
  }
}

class ConnectSidebar extends StatelessWidget {
  const ConnectSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: store.tab == ConnectTab.home,
            onTap: () => context.read<ConnectStore>().setTab(ConnectTab.home),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chats',
            selected: store.tab == ConnectTab.chats,
            onTap: () => context.read<ConnectStore>().setTab(ConnectTab.chats),
          ),
          _NavItem(
            icon: Icons.call_outlined,
            label: 'Calls',
            selected: store.tab == ConnectTab.calls,
            onTap: () => context.read<ConnectStore>().setTab(ConnectTab.calls),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            selected: store.tab == ConnectTab.settings,
            onTap: () => context.read<ConnectStore>().setTab(ConnectTab.settings),
          ),
          const Spacer(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.session.userName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(store.session.email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        selected: selected,
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}

class ConnectDetailsPanel extends StatelessWidget {
  const ConnectDetailsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    final conversation = store.selectedConversation;
    final call = store.selectedCall;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (conversation != null) ...[
              Text(conversation.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(conversation.type.name),
              Text(conversation.isEncrypted ? 'Encrypted' : 'Plain'),
            ] else if (call != null) ...[
              Text(call.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(call.type.name),
              Text(call.status.name),
            ] else
              const Text('Pick a conversation or call to inspect it here.'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...store.activity.take(4).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• $item'),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
