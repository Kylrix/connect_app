import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import '../core/models/connect_models.dart';

class ConnectBottomNav extends StatelessWidget {
  const ConnectBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return NavigationBar(
      selectedIndex: store.tab.index,
      onDestinationSelected: (index) => context.read<ConnectStore>().setTab(ConnectTab.values[index]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
        NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }
}
