import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/cloudflare_cookie_manager.dart';

class CloudflareWebviewScreen extends StatefulWidget {
  final String targetUrl;
  final String? titleName;

  const CloudflareWebviewScreen({
    super.key,
    required this.targetUrl,
    this.titleName,
  });

  static Future<bool> openSolver(BuildContext context, String url, {String? titleName}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CloudflareWebviewScreen(
          targetUrl: url,
          titleName: titleName,
        ),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }

  @override
  State<CloudflareWebviewScreen> createState() => _CloudflareWebviewScreenState();
}

class _CloudflareWebviewScreenState extends State<CloudflareWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _solved = false;
  String _currentTitle = 'cf_verification_title'.translate;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startCookiePolling();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    final desktopUserAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(desktopUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) async {
            if (mounted) setState(() => _isLoading = false);
            final title = await _controller.getTitle();
            if (title != null && title.isNotEmpty && mounted) {
              setState(() => _currentTitle = title);
            }
            _checkCloudflareCleared(url);
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.targetUrl));
  }

  void _startCookiePolling() {
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _controller.currentUrl().then((url) {
        if (url != null) {
          _checkCloudflareCleared(url);
        }
      });
    });
  }

  Future<void> _checkCloudflareCleared(String url) async {
    if (_solved) return;
    try {
      final rawCookies = await _controller.runJavaScriptReturningResult('document.cookie');
      final cookieString = rawCookies.toString().replaceAll('"', '');
      final userAgent = await _controller.runJavaScriptReturningResult('navigator.userAgent');
      final uaString = userAgent.toString().replaceAll('"', '');

      if (cookieString.contains('cf_clearance') ||
          cookieString.contains('__cf_bm') ||
          (!cookieString.contains('challenge') && cookieString.length > 15)) {
        await CloudflareCookieManager().saveRawCookieString(
          url,
          cookieString,
          userAgent: uaString.isNotEmpty ? uaString : null,
        );

        if (mounted && !_solved) {
          setState(() {
            _solved = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cf_verification_saved'.translate),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) Navigator.of(context).pop(true);
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = widget.titleName ?? _currentTitle;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'cf_verification_title'.translate,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              displayTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'reload_page'.translate,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              final url = await _controller.currentUrl();
              if (url != null) {
                await _checkCloudflareCleared(url);
                if (mounted) Navigator.of(context).pop(true);
              }
            },
            tooltip: 'done'.translate,
          ),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.secondaryContainer.withOpacity(0.4),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'cf_solve_prompt'.translate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
