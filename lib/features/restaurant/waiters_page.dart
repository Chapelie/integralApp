// waiters_page.dart
// Page for managing restaurant waiters/servers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/waiter.dart';
import '../../providers/waiter_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';
import 'waiter_form_dialog.dart';

class WaitersPage extends ConsumerStatefulWidget {
  const WaitersPage({super.key});

  @override
  ConsumerState<WaitersPage> createState() => _WaitersPageState();
}

class _WaitersPageState extends ConsumerState<WaitersPage> {
  String _searchQuery = '';

  List<Waiter> _filterWaiters(List<Waiter> waiters) {
    if (_searchQuery.isEmpty) return waiters;
    final query = _searchQuery.toLowerCase();
    return waiters.where((waiter) {
      return waiter.name.toLowerCase().contains(query) ||
          (waiter.phone?.toLowerCase().contains(query) ?? false) ||
          (waiter.email?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final waitersAsync = ref.watch(waiterListProvider);
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/waiters',
      appBar: UnifiedHeader(
        title: 'Gestion du Personnel',
        showSearch: true,
        searchHint: 'Rechercher un membre du personnel...',
        onSearch: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onRefresh: () {
          ref.refresh(waiterListProvider);
        },
        actions: [
          FButton(
            onPress: () => _showWaiterForm(context, ref),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 4),
                Text('Ajouter'),
              ],
            ),
          ),
        ],
      ),
      child: waitersAsync.when(
        data: (waiters) {
          final filteredWaiters = _filterWaiters(waiters);
          if (filteredWaiters.isEmpty && waiters.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: theme.colors.mutedForeground),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat',
                    style: theme.typography.lg,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun membre du personnel ne correspond à votre recherche',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            );
          }
          if (filteredWaiters.isEmpty) {
            return _buildEmptyState(context, ref, theme);
          }
          return _buildWaitersList(context, ref, filteredWaiters, theme);
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
            Icons.room_service,
            size: 64,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun personnel',
            style: theme.typography.xl,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier membre du personnel',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          FButton(
            onPress: () => _showWaiterForm(context, ref),
            style: FButtonStyle.primary(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Ajouter du personnel'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitersList(
    BuildContext context,
    WidgetRef ref,
    List<Waiter> waiters,
    FThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: waiters.length,
      itemBuilder: (context, index) {
        return _buildWaiterCard(context, ref, waiters[index], theme);
      },
    );
  }

  Widget _buildWaiterCard(
    BuildContext context,
    WidgetRef ref,
    Waiter waiter,
    FThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: waiter.isActive
              ? theme.colors.primary.withOpacity(0.1)
              : theme.colors.mutedForeground.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: waiter.isActive
                ? theme.colors.primary
                : theme.colors.mutedForeground,
          ),
        ),
        title: Text(
          waiter.name,
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (waiter.phone != null)
              Text('${waiter.phone}'),
            if (waiter.email != null)
              Text('📧 ${waiter.email}'),
            Text('Tables: ${waiter.assignedTableIds.length}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: waiter.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                waiter.isActive ? 'Actif' : 'Inactif',
                style: theme.typography.xs.copyWith(
                  color: waiter.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showWaiterOptions(context, ref, waiter),
            ),
          ],
        ),
        onTap: () => _showWaiterForm(context, ref, waiter),
      ),
    );
  }

  void _showWaiterForm(BuildContext context, WidgetRef ref, [Waiter? waiter]) {
    showDialog(
      context: context,
      builder: (context) => WaiterFormDialog(waiter: waiter),
    );
  }

  void _showWaiterOptions(BuildContext context, WidgetRef ref, Waiter waiter) {
    final theme = FTheme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showWaiterForm(context, ref, waiter);
              },
            ),
            ListTile(
              leading: Icon(
                waiter.isActive ? Icons.pause : Icons.play_arrow,
              ),
              title: Text(waiter.isActive ? 'Désactiver' : 'Activer'),
              onTap: () async {
                await ref.read(waiterListProvider.notifier).toggleActive(waiter.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colors.error),
              title: Text(
                'Supprimer',
                style: TextStyle(color: theme.colors.error),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmer la suppression'),
                    content: Text(
                      'Êtes-vous sûr de vouloir supprimer ${waiter.name} ?',
                    ),
                    actions: [
                      FButton(
                        onPress: () => Navigator.pop(context, false),
                        style: FButtonStyle.outline(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        onPress: () => Navigator.pop(context, true),
                        style: FButtonStyle.destructive(),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await ref.read(waiterListProvider.notifier).deleteWaiter(waiter.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
