// lib/providers/sync_provider.dart
// Providers Riverpod pour la synchronisation

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync_service.dart';

/// Provider pour le service de synchronisation
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

/// Provider pour l'état de synchronisation
final syncStateProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});

/// Notifier pour l'état de synchronisation
class SyncNotifier extends Notifier<SyncState> {
  late final SyncService _syncService;

  @override
  SyncState build() {
    _syncService = ref.read(syncServiceProvider);
    _syncService.startConnectivityMonitoring();
    _updatePendingCount();
    return SyncState();
  }

  /// Mettre à jour le nombre d'éléments en attente
  Future<void> _updatePendingCount() async {
    try {
      final pendingCount = await _syncService.getPendingCount();
      state = state.copyWith(pendingCount: pendingCount);
    } catch (e) {
      // Ignorer les erreurs pour le moment
    }
  }

  /// Démarrer la synchronisation
  Future<void> sync() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      await _syncService.fullSync();
      await _updatePendingCount();
      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
        status: 'Synchronisation terminée',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
        status: 'Erreur de synchronisation',
      );
    }
  }

  /// Synchronisation forcée
  Future<void> forceSync() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      await _syncService.forceFullSync();
      await _updatePendingCount();
      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
        status: 'Synchronisation forcée terminée',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
        status: 'Erreur de synchronisation forcée',
      );
    }
  }

  /// Vérifier la connectivité
  Future<void> checkConnectivity() async {
    final isOnline = await _syncService.checkConnectivity();
    state = state.copyWith(isOnline: isOnline);
  }

  // Note: dispose() n'est pas nécessaire avec Notifier dans Riverpod 2.x
}
