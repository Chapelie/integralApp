// tables_page.dart
// Page for managing restaurant tables
// Displays tables in a grid with status and allows CRUD operations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/table.dart';
import '../../providers/table_provider.dart';
import '../../providers/waiter_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/mobile_header.dart';
import 'table_form_dialog.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableListProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/tables',
      appBar: MobileHeader(
        title: 'Gestion des Tables',
        actions: [
          FButton(
            onPress: () => _showTableForm(context, ref),
            style: FButtonStyle.primary(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      child: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return _buildEmptyState(context, ref, theme);
          }
          return _buildTablesGrid(context, ref, tables, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: theme.colors.error),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant,
            size: 64,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune table',
            style: theme.typography.xl,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première table',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          FButton(
            onPress: () => _showTableForm(context, ref),
            style: FButtonStyle.primary(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Ajouter une table'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesGrid(
    BuildContext context,
    WidgetRef ref,
    List<RestaurantTable> tables,
    FThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 380) crossAxisCount = 2;
        else if (constraints.maxWidth < 680) crossAxisCount = 3;
        final aspect = constraints.maxWidth < 380 ? 1.0 : 1.2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspect,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            return _buildTableCard(context, ref, tables[index], theme);
          },
        );
      },
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    FThemeData theme,
  ) {
    final statusColor = _getStatusColor(table.status, theme);

    return InkWell(
      onTap: () => _showTableDetails(context, ref, table),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          border: Border.all(
            color: statusColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Table ${table.number}',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                table.status.label,
                style: theme.typography.sm.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (table.waiterName != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    table.waiterName!,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TableStatus status, FThemeData theme) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      case TableStatus.cleaning:
        return Colors.blue;
    }
  }

  void _showTableForm(BuildContext context, WidgetRef ref, [RestaurantTable? table]) {
    showDialog(
      context: context,
      builder: (context) => TableFormDialog(table: table),
    );
  }

  void _showTableDetails(BuildContext context, WidgetRef ref, RestaurantTable table) {
    final theme = FTheme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Table ${table.number}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Statut', table.status.label, theme),
              _buildDetailRow('Capacité', '${table.capacity} personnes', theme),
              if (table.waiterName != null)
                _buildDetailRow('Serveur', table.waiterName!, theme),
              if (table.notes != null)
                _buildDetailRow('Notes', table.notes!, theme),
            ],
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.outline(),
            child: const Text('Fermer'),
          ),
          if (table.status == TableStatus.occupied) ...[
            const SizedBox(width: 8),
            FButton(
              onPress: () async {
                await ref.read(tableListProvider.notifier).clearTable(table.id);
                if (context.mounted) Navigator.pop(context);
              },
              style: FButtonStyle.primary(),
              child: const Text('Libérer'),
            ),
          ],
          const SizedBox(width: 8),
          FButton(
            onPress: () {
              Navigator.pop(context);
              _showTableForm(context, ref, table);
            },
            style: FButtonStyle.outline(),
            child: const Text('Modifier'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () async {
              await ref.read(tableListProvider.notifier).deleteTable(table.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: FButtonStyle.destructive(),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.typography.sm,
          ),
        ],
      ),
    );
  }
}
