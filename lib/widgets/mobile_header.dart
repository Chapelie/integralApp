import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../core/responsive_helper.dart';

class MobileHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? color;

  const MobileHeader({super.key, required this.title, this.actions, this.color});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final headerColor = color ?? theme.colors.primary;
    final isDesktop = Responsive.isDesktop(context);
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      backgroundColor: theme.colors.background,
      foregroundColor: theme.colors.foreground,
      surfaceTintColor: Colors.transparent, // Évite les couleurs qui se chevauchent
      leading: isDesktop
          ? null
          : Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6, height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Text(
                title,
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
      actions: actions,
    );
  }
}
