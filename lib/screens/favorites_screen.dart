import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final favs = state.favoriteNovels;
        return Scaffold(
          appBar: AppBar(centerTitle: true, title: Text('favorites'.translate)),
          body: ListView.builder(
            itemCount: favs.length,
            itemBuilder: (ctx, i) {
              final n = favs[i];
              return ListTile(
                leading:
                    n.coverImageUrl.isNotEmpty
                        ? Image.network(
                          n.coverImageUrl,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                        : null,
                title: Text(n.title),
                subtitle: Text(
                  '${n.author} • ${n.numberOfChapters} ${'chapters_short'.translate}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReaderScreen(),
                        settings: RouteSettings(arguments: n),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
