import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      centerTitle: true,
      pinned: false,
      floating: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(15),
        child: const SizedBox(height: 15),
      ),
      title: Text(
        'app_title'.translate,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
