// table_form_dialog.dart
// Dialog for creating/editing restaurant tables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/table.dart';
import '../../models/waiter.dart';
import '../../providers/table_provider.dart';
import '../../providers/waiter_provider.dart';
import '../../core/beep_service.dart';

class TableFormDialog extends ConsumerStatefulWidget {
  final RestaurantTable? table;

  const TableFormDialog({super.key, this.table});

  @override
  ConsumerState<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends ConsumerState<TableFormDialog> {
  late TextEditingController _numberController;
  late TextEditingController _capacityController;
  late TextEditingController _notesController;
  String? _selectedWaiterId;
  TableStatus _selectedStatus = TableStatus.available;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.table?.number ?? '');
    _capacityController = TextEditingController(
      text: widget.table?.capacity.toString() ?? '4',
    );
    _notesController = TextEditingController(text: widget.table?.notes ?? '');
    _selectedWaiterId = widget.table?.waiterId;
    _selectedStatus = widget.table?.status ?? TableStatus.available;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final waitersAsync = ref.watch(activeWaitersProvider);

    return AlertDialog(
      title: Text(widget.table == null ? 'Nouvelle Table' : 'Modifier Table'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de table',
                hintText: 'Ex: 1, A1, Terrasse 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Capacité',
                hintText: 'Nombre de personnes',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TableStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Statut',
              ),
              items: TableStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            waitersAsync.when(
              data: (waiters) {
                return DropdownButtonFormField<String>(
                  value: _selectedWaiterId,
                  decoration: const InputDecoration(
                    labelText: 'Personnel assigné',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...waiters.map((waiter) {
                      return DropdownMenuItem(
                        value: waiter.id,
                        child: Text(waiter.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWaiterId = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Erreur: $error'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Ex: Près de la fenêtre',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.outline(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 8),
        FButton(
          onPress: _saveTable,
          style: FButtonStyle.primary(),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _saveTable() async {
    final number = _numberController.text.trim();
    final capacityText = _capacityController.text.trim();
    final notes = _notesController.text.trim();

    if (number.isEmpty || capacityText.isEmpty) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La capacité doit être un nombre positif'),
        ),
      );
      return;
    }

    try {
      String? waiterName;
      if (_selectedWaiterId != null) {
        final waiter = await ref.read(
          waiterByIdProvider(_selectedWaiterId!).future,
        );
        waiterName = waiter?.name;
      }

      if (widget.table == null) {
        // Create new table
        await ref.read(tableListProvider.notifier).createTable(
              number: number,
              capacity: capacity,
              waiterId: _selectedWaiterId,
              waiterName: waiterName,
              notes: notes.isEmpty ? null : notes,
            );
      } else {
        // Update existing table
        final updatedTable = widget.table!.copyWith(
          number: number,
          capacity: capacity,
          status: _selectedStatus,
          waiterId: _selectedWaiterId,
          waiterName: waiterName,
          notes: notes.isEmpty ? null : notes,
        );
        await ref.read(tableListProvider.notifier).updateTable(updatedTable);
      }

      // Play success beep
      BeepService().playSuccess();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Table enregistrée avec succès'),
          ),
        );
      }
    } catch (e) {
      // Play error beep
      BeepService().playError();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
