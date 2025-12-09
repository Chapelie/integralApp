// waiter_form_dialog.dart
// Dialog for creating/editing waiters

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/waiter.dart';
import '../../providers/waiter_provider.dart';
import '../../core/beep_service.dart';

class WaiterFormDialog extends ConsumerStatefulWidget {
  final Waiter? waiter;

  const WaiterFormDialog({super.key, this.waiter});

  @override
  ConsumerState<WaiterFormDialog> createState() => _WaiterFormDialogState();
}

class _WaiterFormDialogState extends ConsumerState<WaiterFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.waiter?.name ?? '');
    _phoneController = TextEditingController(text: widget.waiter?.phone ?? '');
    _emailController = TextEditingController(text: widget.waiter?.email ?? '');
    _isActive = widget.waiter?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return AlertDialog(
      title: Text(widget.waiter == null ? 'Nouveau Personnel' : 'Modifier Personnel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                hintText: 'Ex: Jean Dupont',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: 'Ex: +33 6 12 34 56 78',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Ex: jean.dupont@restaurant.fr',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Actif'),
              subtitle: const Text('Le membre du personnel est en service'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
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
          onPress: _saveWaiter,
          style: FButtonStyle.primary(),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _saveWaiter() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      BeepService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom est obligatoire'),
        ),
      );
      return;
    }

    try {
      if (widget.waiter == null) {
        // Create new waiter
        await ref.read(waiterListProvider.notifier).createWaiter(
              name: name,
              phone: phone.isEmpty ? null : phone,
              email: email.isEmpty ? null : email,
              isActive: _isActive,
            );
      } else {
        // Update existing waiter
        final updatedWaiter = widget.waiter!.copyWith(
          name: name,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          isActive: _isActive,
        );
        await ref.read(waiterListProvider.notifier).updateWaiter(updatedWaiter);
      }

      // Play success beep
      BeepService().playSuccess();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personnel enregistré avec succès'),
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
