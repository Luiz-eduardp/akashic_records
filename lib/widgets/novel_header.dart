import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';

class NovelHeader extends StatelessWidget {
  final Novel novel;
  final bool loading;
  const NovelHeader({super.key, required this.novel, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          if (novel.coverImageUrl.isNotEmpty)
            Image.network(
              novel.coverImageUrl,
              width: 96,
              height: 128,
              fit: BoxFit.cover,
            )
          else
            Container(width: 96, height: 128, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  novel.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                if (novel.author.isNotEmpty)
                  Text(
                    'by ${novel.author}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                Text(
                  novel.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
