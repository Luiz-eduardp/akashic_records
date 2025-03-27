import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterPressed;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onFilterPressed,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color darkFillColor = Colors.grey[800]!;
    final Color darkTextColor = Colors.white;
    final Color darkIconColor = Colors.white70;
    final Color darkBorderColor = Colors.grey[700]!;

    final Color lightFillColor = Colors.grey[200]!;
    final Color lightTextColor = Colors.black;
    final Color lightIconColor = Colors.grey[600]!;
    final Color lightBorderColor = Colors.grey[300]!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(
                color: isDarkMode ? darkTextColor : lightTextColor,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar novels...',
                hintStyle: TextStyle(
                  color: isDarkMode ? darkIconColor : lightIconColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? darkIconColor : lightIconColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? darkBorderColor : lightBorderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? darkBorderColor : lightBorderColor,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? darkFillColor : lightFillColor,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDarkMode ? darkIconColor : lightIconColor,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch("");
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
              ),
              onSubmitted: (value) {
                widget.onSearch(value);
              },
            ),
          ),
          const SizedBox(width: 8.0),
          Material(
            color: isDarkMode ? darkFillColor : lightFillColor,
            borderRadius: BorderRadius.circular(25.0),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: isDarkMode ? darkIconColor : lightIconColor,
              ),
              onPressed: widget.onFilterPressed,
              splashRadius: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}
