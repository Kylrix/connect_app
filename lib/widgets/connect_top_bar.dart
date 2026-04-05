import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import 'connect_dialogs.dart';

class ConnectTopBar extends StatelessWidget {
  const ConnectTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
        ),
        child: Row(
          children: [
            Text('Connect', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            if (store.settings.showPortal)
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ConnectPortalDialog(),
                ),
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Portal'),
              ),
            const Spacer(),
            IconButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ConnectSearchDialog(),
              ),
              icon: const Icon(Icons.search_outlined),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              child: Text(store.session.userName.isEmpty ? 'C' : store.session.userName[0].toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
