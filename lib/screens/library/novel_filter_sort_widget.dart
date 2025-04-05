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
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (filter['type'] == 'Picker')
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              value: _currentFilters[filterName]['value'],
                              items:
                                  (filter['options']
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
                                  widget.onFilterChanged(_currentFilters);
                                });
                              },
                            ),
                          if (filter['type'] == 'CheckboxGroup')
                            Wrap(
                              children:
                                  (filter['options']
                                          as List<Map<String, dynamic>>)
                                      .map(
                                        (option) => SizedBox(
                                          width:
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width /
                                                  2 -
                                              24,
                                          child: CheckboxListTile(
                                            title: Text(
                                              option['label'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            value:
                                                (_currentFilters[filterName]['value']
                                                        as List)
                                                    .contains(option['value']),
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                final List currentValue =
                                                    _currentFilters[filterName]['value'];
                                                if (newValue == true) {
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
                                                widget.onFilterChanged(
                                                  _currentFilters,
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Voltar para a Biblioteca'.translate),
                      ),
                      ElevatedButton(
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showFilterDialog(context),
      child: Text('Filtros'.translate),
    );
  }
}
