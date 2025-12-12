// lib/widgets/unified_header.dart
// Unified header component that handles desktop/mobile automatically
// Replaces TopBar and MobileHeader with a single consistent component

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../core/responsive_helper.dart';
import '../providers/product_provider.dart';
import '../providers/sync_provider.dart';

class UnifiedHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? color;
  final bool showSearch;
  final bool showSyncStatus;
  final bool showNetworkIndicator;
  final bool showUserAvatar;
  final bool showSettings;
  final VoidCallback? onSearchChanged;
  final String? searchHint;
  
  // Callbacks personnalisés pour actions spécifiques à la page
  final Function(String)? onSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onFilter;
  final Widget? customLeading;
  final List<Widget>? leadingActions; // Actions à gauche (avant la recherche)
  final List<Widget>? trailingActions; // Actions à droite (après les actions standards)

  const UnifiedHeader({
    super.key,
    required this.title,
    this.actions,
    this.color,
    this.showSearch = false,
    this.showSyncStatus = false,
    this.showNetworkIndicator = false,
    this.showUserAvatar = false,
    this.showSettings = false,
    this.onSearchChanged,
    this.onSearch,
    this.onRefresh,
    this.onFilter,
    this.searchHint,
    this.customLeading,
    this.leadingActions,
    this.trailingActions,
  });

  @override
  ConsumerState<UnifiedHeader> createState() => _UnifiedHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _UnifiedHeaderState extends ConsumerState<UnifiedHeader> {
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
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final headerColor = widget.color ?? theme.colors.primary;

    // On desktop with search/sync features, show full-featured header
    if (isDesktop && (widget.showSearch || widget.showSyncStatus)) {
      return _buildDesktopFullHeader(context, theme, headerColor);
    }

    // On desktop without search/sync, don't show AppBar (Sidebar has its own header)
    // On mobile, always show AppBar
    if (isDesktop && !widget.showSearch && !widget.showSyncStatus) {
      // Return a minimal transparent AppBar to avoid layout issues
      return AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      );
    }

    // On mobile, show AppBar
    return _buildAppBarHeader(context, theme, headerColor, isMobile);
  }

  /// Build full-featured desktop header (like TopBar)
  Widget _buildDesktopFullHeader(BuildContext context, FThemeData theme, Color headerColor) {
    final syncState = widget.showSyncStatus ? ref.watch(syncStateProvider) : null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        height: 64,
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
              // Custom leading widget or default logo
              if (widget.customLeading != null)
                widget.customLeading!
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 32,
                    height: 32,
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
              if (widget.customLeading != null || widget.leadingActions != null)
                const SizedBox(width: 16)
              else
                const SizedBox(width: 24),

              // Leading actions (before search)
              if (widget.leadingActions != null) ...widget.leadingActions!,
              if (widget.leadingActions != null) const SizedBox(width: 8),

              // Search Field (if enabled)
              if (widget.showSearch)
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: FTextField(
                      controller: _searchController,
                      hint: widget.searchHint ?? 'Rechercher...',
                      onChange: (value) {
                        if (widget.onSearch != null) {
                          widget.onSearch!(value);
                        } else if (widget.onSearchChanged != null) {
                          widget.onSearchChanged!();
                        } else {
                          // Default: search products
                          ref.read(productProvider.notifier).searchProducts(value);
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ),

              if (widget.showSearch) const SizedBox(width: 8),

              // Sync Status Badge (if enabled)
              if (widget.showSyncStatus && syncState != null)
                _buildSyncButton(context, syncState, theme),

              if (widget.showSyncStatus) const SizedBox(width: 8),

              // Network Indicator (if enabled)
              if (widget.showNetworkIndicator)
                _buildNetworkIndicator(context, theme),

              if (widget.showNetworkIndicator) const SizedBox(width: 8),

              // User Avatar (if enabled)
              if (widget.showUserAvatar)
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

              if (widget.showUserAvatar) const SizedBox(width: 8),

              // Settings Button (if enabled)
              if (widget.showSettings)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                  tooltip: 'Paramètres',
                ),

              if (widget.showSettings) const SizedBox(width: 8),

              // Refresh button (if callback provided)
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: widget.onRefresh,
                  tooltip: 'Rafraîchir',
                ),

              if (widget.onRefresh != null) const SizedBox(width: 8),

              // Filter button (if callback provided)
              if (widget.onFilter != null)
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: widget.onFilter,
                  tooltip: 'Filtrer',
                ),

              if (widget.onFilter != null) const SizedBox(width: 8),

              // Custom actions (standard actions)
              if (widget.actions != null) ...widget.actions!,

              // Trailing actions (after all standard actions)
              if (widget.trailingActions != null) ...widget.trailingActions!,
            ],
          ),
        ),
      ),
    );
  }

  /// Build standard AppBar header (for mobile and simple desktop)
  Widget _buildAppBarHeader(BuildContext context, FThemeData theme, Color headerColor, bool isMobile) {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      backgroundColor: theme.colors.background,
      foregroundColor: theme.colors.foreground,
      surfaceTintColor: Colors.transparent,
      leading: isMobile
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            )
          : null,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Search button on mobile (if enabled)
        if (isMobile && widget.showSearch)
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: 'Rechercher',
          ),

        // Sync status on mobile (if enabled)
        if (isMobile && widget.showSyncStatus)
          Builder(
            builder: (context) {
              final syncState = ref.watch(syncStateProvider);
              return IconButton(
                onPressed: syncState.isSyncing
                    ? null
                    : () {
                        ref.read(syncStateProvider.notifier).sync();
                      },
                icon: Icon(syncState.isSyncing ? Icons.sync : Icons.sync),
                tooltip: 'Synchroniser',
              );
            },
          ),

        // Custom actions
        if (widget.actions != null) ...widget.actions!,
      ],
      bottom: (isMobile && widget.showSearch && _isSearching)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.searchHint ?? 'Rechercher...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    if (widget.onSearch != null) {
                      widget.onSearch!(value);
                    } else if (widget.onSearchChanged != null) {
                      widget.onSearchChanged!();
                    } else {
                      // Default: search products
                      ref.read(productProvider.notifier).searchProducts(value);
                    }
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSyncButton(BuildContext context, dynamic syncState, FThemeData theme) {
    return Semantics(
      label: 'Synchronisation, ${syncState.pendingCount} opérations en attente',
      button: true,
      child: Stack(
        children: [
          IconButton(
            icon: Icon(
              syncState.isSyncing ? Icons.sync : Icons.sync,
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
                    syncState.pendingCount > 9 ? '9+' : '${syncState.pendingCount}',
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

  Widget _buildNetworkIndicator(BuildContext context, FThemeData theme) {
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

