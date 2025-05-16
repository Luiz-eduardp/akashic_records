import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/favorite_list.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageListsScreen extends StatefulWidget {
  const ManageListsScreen({super.key});

  @override
  State<ManageListsScreen> createState() => _ManageListsScreenState();
}

class _ManageListsScreenState extends State<ManageListsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _editingListId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({FavoriteList? list}) {
    _editingListId = list?.id;
    _nameController.text = list?.name ?? '';

    showDialog(
      context: context,
      builder: (context) {
        String? dialogErrorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                _editingListId == null
                    ? "Criar Nova Lista".translate
                    : "Renomear Lista".translate,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              content: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nome da Lista".translate,
                    errorText: dialogErrorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Nome não pode ser vazio".translate;
                    }
                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    final potentialName = value.trim().toLowerCase();
                    if (appState.favoriteLists.any(
                      (l) =>
                          l.id != _editingListId &&
                          l.name.toLowerCase() == potentialName,
                    )) {
                      return "Lista com este nome já existe".translate;
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancelar".translate,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      final name = _nameController.text.trim();
                      try {
                        if (_editingListId == null) {
                          appState.addFavoriteList(name);
                        } else {
                          appState.renameFavoriteList(_editingListId!, name);
                        }
                        Navigator.of(context).pop();
                      } catch (e) {
                        setDialogState(() {
                          dialogErrorText = "Erro: $e".translate;
                        });
                      }
                    } else {
                      setDialogState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _editingListId == null
                        ? "Criar".translate
                        : "Salvar".translate,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _nameController.clear();
      _editingListId = null;
      setState(() {});
    });
  }

  void _confirmDeleteList(FavoriteList list) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Confirmar Exclusão".translate,
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            "Tem certeza que deseja excluir a lista '${list.name}'? As novels nesta lista não serão removidas dos favoritos gerais (se estiverem em outras listas)."
                .translate,
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancelar".translate,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<AppState>(
                  context,
                  listen: false,
                ).removeFavoriteList(list.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Lista '${list.name}' excluída.".translate),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                "Excluir".translate,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gerenciar Listas de Favoritos".translate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body:
          appState.favoriteLists.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Nenhuma lista criada. Toque no botão '+' para adicionar sua primeira lista."
                        .translate,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 20,
                    ),
                  ),
                ),
              )
              : ListView.builder(
                itemCount: appState.favoriteLists.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final list = appState.favoriteLists[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: ListTile(
                      title: Text(
                        list.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "${list.novelIds.length} ${list.novelIds.length == 1 ? 'novel'.translate : (list.novelIds.isEmpty ? 'nenhuma novel'.translate : 'novels'.translate)}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: theme.colorScheme.secondary,
                            ),
                            tooltip: "Renomear Lista".translate,
                            onPressed: () => _showAddEditDialog(list: list),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                            ),
                            tooltip: "Excluir Lista".translate,
                            onPressed: () => _confirmDeleteList(list),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: "Criar Nova Lista".translate,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
