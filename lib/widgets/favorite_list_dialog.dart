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
    if (mounted) {
      setState(() {
        _newListErrorText = null;
      });
    }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lista '$listName' criada e novel adicionada.".translate,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _newListErrorText = e.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newListErrorText = "Erro desconhecido ao criar lista: $e".translate;
        });
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar lista '${list.name}'".translate),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    final currentListIds = appState.getListsContainingNovel(widget.novel);

    return AlertDialog(
      title: Text("Adicionar/Remover das Listas".translate),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            if (appState.favoriteLists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Nenhuma lista criada ainda.".translate),
              )
            else
              ...appState.favoriteLists.map((list) {
                final bool isChecked = currentListIds.contains(list.id);
                return CheckboxListTile(
                  title: Text(list.name),
                  value: isChecked,
                  onChanged: (bool? value) {
                    if (value != null) {
                      _toggleNovelInList(appState, list, value);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: theme.colorScheme.primary,
                  dense: true,
                );
              }),

            const Divider(height: 24.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Criar nova lista e adicionar novel".translate,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _newListController,
                decoration: InputDecoration(
                  hintText: "Nome da nova lista".translate,
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
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text("Criar e Adicionar".translate),
              onPressed: () => _addNewListAndAssignNovel(appState),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("Fechar".translate),
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
