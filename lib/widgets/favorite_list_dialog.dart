import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/favorite_list.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteListDialog extends StatefulWidget {
  final Novel novel;

  const FavoriteListDialog({super.key, required this.novel});

  @override
  State<FavoriteListDialog> createState() => _FavoriteListDialogState();
}

class _FavoriteListDialogState extends State<FavoriteListDialog> {
  final _newListController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _newListErrorText;

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  Future<void> _addNewListAndAssignNovel(AppState appState) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final listName = _newListController.text.trim();
    setState(() {
      _newListErrorText = null;
    });

    try {
      await appState.addFavoriteList(listName);

      final newList = appState.favoriteLists.firstWhere(
        (list) => list.name == listName,
        orElse: () => FavoriteList(id: '', name: ''),
      );

      if (newList.id.isNotEmpty) {
        await appState.addNovelToList(newList.id, widget.novel);
      } else {
        debugPrint(
          "Error: Newly created list '$listName' not found immediately.",
        );
      }

      _newListController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lista'.translate +
                ' ' +
                listName +
                ' ' +
                'criada e novel adicionada'.translate,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    } on Exception catch (e) {
      setState(() {
        _newListErrorText = e.toString();
      });
    } catch (e) {
      setState(() {
        _newListErrorText =
            'Erro desconhecido ao criar lista:'.translate + e.toString();
      });
    }
  }

  Future<void> _toggleNovelInList(
    AppState appState,
    FavoriteList list,
    bool isChecked,
  ) async {
    try {
      if (isChecked) {
        await appState.addNovelToList(list.id, widget.novel);
      } else {
        await appState.removeNovelFromList(list.id, widget.novel);
      }
    } catch (e) {
      debugPrint("Error toggling novel in list ${list.name}: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar lista'.translate + list.name),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = context.watch<AppState>();

    final currentListIds = appState.getListsContainingNovel(widget.novel);

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Adicionar/Remover das Listas".translate,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            if (appState.favoriteLists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Nenhuma lista criada ainda.".translate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ...appState.favoriteLists.map((list) {
                final bool isChecked = currentListIds.contains(list.id);
                return Card(
                  color: colorScheme.surfaceVariant,
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      list.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    value: isChecked,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _toggleNovelInList(appState, list, value);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: colorScheme.primary,
                    dense: true,
                  ),
                );
              }),
            const Divider(height: 24.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Criar nova lista e adicionar novel".translate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _newListController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Nome da nova lista".translate,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Nome não pode ser vazio".translate;
                  }
                  final potentialName = value.trim().toLowerCase();
                  if (appState.favoriteLists.any(
                    (l) => l.name.toLowerCase() == potentialName,
                  )) {
                    return "Lista com este nome já existe".translate;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _addNewListAndAssignNovel(appState),
              ),
            ),
            if (_newListErrorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _newListErrorText!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text("Criar e Adicionar".translate),
              onPressed: () => _addNewListAndAssignNovel(appState),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            "Fechar".translate,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

Future<void> showFavoriteListDialog(BuildContext context, Novel novel) {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return ChangeNotifierProvider.value(
        value: Provider.of<AppState>(context, listen: false),
        child: FavoriteListDialog(novel: novel),
      );
    },
  );
}
