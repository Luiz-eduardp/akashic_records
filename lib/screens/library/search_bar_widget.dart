import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onFilterPressed;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.onFilterPressed,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateClearButtonVisibility);
  }

  void _updateClearButtonVisibility() {
    if (_controller.text.isEmpty && _hasText) {
      setState(() {
        _hasText = false;
      });
    } else if (_controller.text.isNotEmpty && !_hasText) {
      setState(() {
        _hasText = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateClearButtonVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color fillColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Buscar novels...',
                hintStyle: TextStyle(color: iconColor),
                prefixIcon: Icon(Icons.search, color: iconColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                filled: true,
                fillColor: fillColor,
                suffixIcon: _hasText
                    ? IconButton(
                        icon: Icon(Icons.clear, color: iconColor),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearch("");
                          setState(() {
                            _hasText = false;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
              ),
              onSubmitted: (value) {
                widget.onSearch(value);
              },
              onChanged: (value) {
                setState(() {
                  _hasText = value.isNotEmpty;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}