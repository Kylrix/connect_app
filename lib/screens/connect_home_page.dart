import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';
import 'connect_shell.dart';

class ConnectHomePage extends StatelessWidget {
  const ConnectHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectStore>(
      builder: (context, store, _) {
        if (!store.isReady || store.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (store.error != null) {
          return Scaffold(
            body: Center(child: Text(store.error!)),
          );
        }

        return const ConnectShell();
      },
    );
  }
}
