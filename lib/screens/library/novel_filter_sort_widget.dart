import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class NovelFilterSortWidget extends StatefulWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onFilterChanged;

  const NovelFilterSortWidget({
    super.key,
    required this.filters,
    required this.onFilterChanged,
  });

  @override
  State<NovelFilterSortWidget> createState() => _NovelFilterSortWidgetState();
}

class _NovelFilterSortWidgetState extends State<NovelFilterSortWidget> {
  late Map<String, dynamic> _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = Map<String, dynamic>.from(widget.filters);
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  Text(
                    'Filtros e Ordenação'.translate,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...widget.filters.entries.map((entry) {
                          final filterName = entry.key;
                          final filter = entry.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filter['label'],
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (filter['type'] == 'Picker')
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.0),
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 12.0,
                                      ),
                                    ),
                                    value: _currentFilters[filterName]['value'],
                                    items: (filter['options']
                                            as List<Map<String, dynamic>>)
                                        .map(
                                          (option) => DropdownMenuItem<String>(
                                            value: option['value'],
                                            child: Text(option['label']),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _currentFilters[filterName]['value'] =
                                            newValue!;
                                      });
                                    },
                                  ),
                                if (filter['type'] == 'CheckboxGroup')
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: (filter['options']
                                            as List<Map<String, dynamic>>)
                                        .map(
                                          (option) => FilterChip(
                                            label: Text(option['label']),
                                            selected: (_currentFilters[filterName]['value']
                                                    as List)
                                                .contains(option['value']),
                                            onSelected: (bool selected) {
                                              setState(() {
                                                final List currentValue =
                                                    _currentFilters[filterName]['value'];
                                                if (selected) {
                                                  currentValue.add(
                                                    option['value'],
                                                  );
                                                } else {
                                                  currentValue.remove(
                                                    option['value'],
                                                  );
                                                }
                                                _currentFilters[filterName]['value'] =
                                                    currentValue;
                                              });
                                            },
                                            selectedColor: theme.colorScheme.primaryContainer,
                                            checkmarkColor: theme.colorScheme.onPrimaryContainer,
                                            labelStyle: theme.textTheme.labelLarge,
                                          ),
                                        )
                                        .toList(),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancelar'.translate),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          widget.onFilterChanged(_currentFilters);
                          Navigator.pop(context);
                        },
                        child: Text('Aplicar Filtros'.translate),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.tonal(
      onPressed: () => _showFilterDialog(context),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text('Filtros'.translate),
    );
  }
}
