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
        title: Text('Notificações'.translate),
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
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                return Text('Erro: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(width: 4);
              } else {
                final notifications = snapshot.data!;
                _isExpandedList = List.generate(
                  notifications.length,
                  (index) => false,
                );
                return RefreshIndicator(
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          notification['content'] ?? 'Sem conteúdo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _handleAction(notification, context);
                            },
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
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Atenção'),
            content: Text(
              'Nenhuma ação extra disponível para esta notificação.',
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
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
      SnackBar(content: Text('Notificações atualizadas!'.translate)),
    );
  }
}
