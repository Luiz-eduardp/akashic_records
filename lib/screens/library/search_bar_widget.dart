import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onFilterPressed;
  final List<Widget>? extraActions;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.onFilterPressed,
    this.extraActions,
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

  _saveSearchTerm(String searchTerm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('novelSearchTerm', searchTerm);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar novels...'.translate,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                suffixIcon:
                    _hasText
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                _saveSearchTerm(value);
              },
              onChanged: (value) {
                setState(() {
                  _hasText = value.isNotEmpty;
                });
              },
            ),
          ),

          if (widget.extraActions != null) ...widget.extraActions!,
        ],
      ),
    );
  }
}
