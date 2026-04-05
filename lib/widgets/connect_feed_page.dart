import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connect_store.dart';

class ConnectFeedPage extends StatelessWidget {
  const ConnectFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConnectStore>();
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Home', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(text: 'For You'),
                Tab(text: 'Trending'),
                Tab(text: 'Search'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _FeedList(items: store.feed.where((item) => item.kind != 'share').toList(growable: false)),
                  _FeedList(items: store.feed.where((item) => item.tags.contains('call') || item.tags.contains('team')).toList(growable: false)),
                  _FeedSearch(items: store.feed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.items});
  final List items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(item.body),
            trailing: Text(item.author),
          ),
        );
      },
    );
  }
}

class _FeedSearch extends StatefulWidget {
  const _FeedSearch({required this.items});
  final List items;

  @override
  State<_FeedSearch> createState() => _FeedSearchState();
}

class _FeedSearchState extends State<_FeedSearch> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = controller.text.toLowerCase();
    final results = widget.items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          item.author.toLowerCase().contains(query);
    }).toList(growable: false);
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Search feed',
            prefixIcon: Icon(Icons.search_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = results[index];
              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.body),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
