import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/sync_provider.dart';
import '../../../core/responsive_helper.dart';

class TopBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;

  const TopBar({
    super.key,
    this.onMenuPressed,
  });

  @override
  ConsumerState<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _TopBarState extends ConsumerState<TopBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final syncState = ref.watch(syncStateProvider);
    final isMobile = Responsive.isMobile(context);

    // Use Material AppBar for mobile, custom container for desktop
    if (isMobile) {
      return AppBar(
        title: const Text('IntegralPOS'),
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
        elevation: 1,
        actions: [
          // Search button
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          // Sync status
          IconButton(
            onPressed: syncState.isSyncing
                ? null
                : () {
                    ref.read(syncStateProvider.notifier).sync();
                  },
            icon: Icon(syncState.isSyncing ? Icons.sync : Icons.sync),
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      ref.read(productProvider.notifier).searchProducts(value);
                    },
                  ),
                ),
              )
            : null,
      );
    }

    return Container(
      height: widget.preferredSize.height,
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Menu Button (Mobile)
            if (isMobile && widget.onMenuPressed != null) ...[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onMenuPressed,
                tooltip: 'Menu',
              ),
              const SizedBox(width: 8),
            ],

            // Title
            if (!_isSearching || !isMobile) ...[
              Container(
                width: 32,
                height: 32,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/IntegralPOS.jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.store,
                        color: theme.colors.primary,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],

            // Search Field
            if (!isMobile || _isSearching)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: FTextField(
                    controller: _searchController,
                    hint: 'Rechercher des produits...',
                    onChange: (value) {
                      ref.read(productProvider.notifier).searchProducts(value);
                      setState(() {});
                    },
                  ),
                ),
              ),

            if (isMobile && !_isSearching) const Spacer(),

            // Search Toggle (Mobile)
            if (isMobile && !_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() => _isSearching = true);
                },
                tooltip: 'Rechercher',
              ),

            const SizedBox(width: 8),

            // Sync Status Badge
            _buildSyncButton(context, syncState),

            const SizedBox(width: 8),

            // Network Indicator
            _buildNetworkIndicator(context),

            const SizedBox(width: 8),

            // User Avatar
            IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colors.primary,
                ),
              ),
              onPressed: () {
                // Show user menu
              },
              tooltip: 'Profil utilisateur',
            ),

            const SizedBox(width: 8),

            // Settings Button
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to settings
              },
              tooltip: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, dynamic syncState) {
    final theme = FTheme.of(context);

    return Semantics(
      label: 'Synchronisation, ${syncState.pendingCount} opérations en attente',
      button: true,
      child: Stack(
        children: [
          IconButton(
            icon: Icon(
              syncState.isSyncing
                  ? Icons.sync
                  : Icons.sync,
            ),
            onPressed: syncState.isSyncing
                ? null
                : () {
                    ref.read(syncStateProvider.notifier).sync();
                  },
            tooltip: 'Synchroniser',
          ),
          if (syncState.pendingCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colors.destructive,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    syncState.pendingCount > 9
                        ? '9+'
                        : '${syncState.pendingCount}',
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkIndicator(BuildContext context) {
    final theme = FTheme.of(context);
    // For now, assume online. Can be enhanced with connectivity check

    return Semantics(
      label: 'En ligne',
      child: Tooltip(
        message: 'En ligne',
        child: Icon(
          Icons.wifi,
          size: 20,
          color: theme.colors.primary,
        ),
      ),
    );
  }
}
