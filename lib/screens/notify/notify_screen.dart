import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class NotificationScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> notificationsFuture;
  final Function(String) onNotificationRead;

  const NotificationScreen({
    super.key,
    required this.notificationsFuture,
    required this.onNotificationRead,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<bool> _isExpandedList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificações'.translate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Shimmer.fromColors(
                    baseColor: theme.colorScheme.surfaceVariant,
                    highlightColor: theme.colorScheme.onInverseSurface,
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: theme.colorScheme.surface,
                          child: const ExpansionTile(
                            title: SizedBox(
                              height: 20,
                              width: 150,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.white),
                              ),
                            ),
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SizedBox(
                                  height: 50,
                                  width: double.infinity,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhuma notificação.'.translate,
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              } else {
                final notifications = snapshot.data!;
                _isExpandedList = List.generate(
                  notifications.length,
                  (index) => false,
                );
                return RefreshIndicator(
                  backgroundColor: theme.colorScheme.surface,
                  color: theme.colorScheme.primary,
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(notification, index, theme);
                    },
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    int index,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceVariant,
      child: ExpansionTile(
        title: Text(
          notification['content'] ?? 'Sem conteúdo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        initiallyExpanded: _isExpandedList[index],
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpandedList[index] = expanded;
          });
        },
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${notification['details'] ?? ' '}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      notification['action'] != 'none'
                          ? ElevatedButton(
                            onPressed: () {
                              _handleAction(notification, context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(notification['action'] ?? 'Ver Mais'),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(
    Map<String, dynamic> notification,
    BuildContext context,
  ) async {
    final url = notification['url'];
    final notificationId = notification['id'];

    if (url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível abrir o link: $url',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Atenção',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Text(
              'Nenhuma ação extra disponível para esta notificação.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          );
        },
      );
    }

    if (notificationId != null) {
      _markNotificationAsRead(notificationId);
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readNotifications =
        prefs.getStringList('readNotifications') ?? [];
    if (!readNotifications.contains(notificationId)) {
      readNotifications.add(notificationId);
      await prefs.setStringList('readNotifications', readNotifications);
      widget.onNotificationRead(notificationId);
    }
  }

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      widget.notificationsFuture.then((notifications) {});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notificações atualizadas!'.translate,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }
}
