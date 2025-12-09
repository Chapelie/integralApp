import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/responsive_helper.dart';
import 'sales_list_widget.dart';

/// Widget affichant le résumé de la caisse
///
/// Affiche l'ouverture, les ventes, le montant attendu,
/// le montant réel et la différence (si disponible).
class RegisterSummary extends StatelessWidget {
  /// Montant d'ouverture de la caisse
  final double openingBalance;

  /// Total des ventes
  final double totalSales;

  /// Nombre de ventes
  final int salesCount;

  /// Montant attendu en caisse
  final double expectedCash;

  /// Montant réel compté (optionnel)
  final double? actualCash;

  /// Différence entre réel et attendu (optionnel)
  final double? difference;

  /// ID de la caisse (pour filtrer les ventes)
  final String? cashRegisterId;

  /// Date d'ouverture (pour filtrer les ventes)
  final DateTime? openedAt;

  /// Date de fermeture (pour filtrer les ventes)
  final DateTime? closedAt;

  /// Afficher la liste des ventes
  final bool showSalesList;

  const RegisterSummary({
    super.key,
    required this.openingBalance,
    required this.totalSales,
    required this.salesCount,
    required this.expectedCash,
    this.actualCash,
    this.difference,
    this.cashRegisterId,
    this.openedAt,
    this.closedAt,
    this.showSalesList = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Semantics(
      label: 'Résumé de la caisse',
      child: FCard.raw(
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title with icon
              Row(
                children: [
                  Icon(
                    FIcons.list,
                    size: 24,
                    color: theme.colors.primary,
                  ),
                  SizedBox(width: Responsive.spacing(context, multiplier: 2)),
                  Text(
                    'Résumé de la caisse',
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Responsive.spacing(context, multiplier: 4)),

              // Opening balance
              _buildSummaryRow(
                context: context,
                icon: FIcons.circleArrowUp,
                label: 'Montant d\'ouverture',
                value: CurrencyFormatter.format(openingBalance),
                iconColor: theme.colors.primary,
              ),

              SizedBox(height: Responsive.spacing(context, multiplier: 3)),

              // Sales info
              _buildSummaryRow(
                context: context,
                icon: FIcons.receipt,
                label: 'Ventes ($salesCount transactions)',
                value: CurrencyFormatter.format(totalSales),
                iconColor: theme.colors.primary,
              ),

              SizedBox(height: Responsive.spacing(context, multiplier: 3)),

              Divider(
                color: theme.colors.border,
                height: 1,
              ),

              // Expected cash
              _buildSummaryRow(
                context: context,
                icon: FIcons.circleDollarSign,
                label: 'Montant attendu',
                value: CurrencyFormatter.format(expectedCash),
                iconColor: theme.colors.primary,
                isHighlighted: true,
              ),

              // Actual cash (if available)
              if (actualCash != null) ...[
                SizedBox(height: Responsive.spacing(context, multiplier: 3)),
                _buildSummaryRow(
                  context: context,
                  icon: FIcons.circleDollarSign,
                  label: 'Montant réel compté',
                  value: CurrencyFormatter.format(actualCash!),
                  iconColor: theme.colors.primary,
                ),
              ],

              // Difference (if available)
              if (difference != null) ...[
                SizedBox(height: Responsive.spacing(context, multiplier: 3)),
                Divider(
                  color: theme.colors.border,
                  height: 1,
                ),
              _buildSummaryRow(
                context: context,
                icon: difference! < 0
                    ? FIcons.trendingDown
                    : FIcons.trendingUp,
                label: 'Différence',
                value: CurrencyFormatter.format(difference!.abs()),
                iconColor: difference! < 0
                    ? theme.colors.destructive
                    : Colors.green,
                isHighlighted: true,
                valueColor: difference! < 0
                    ? theme.colors.destructive
                    : Colors.green,
              ),

                // Warning if there's a significant difference
                if (difference!.abs() > 0) ...[
                  SizedBox(height: Responsive.spacing(context, multiplier: 3)),
                  Semantics(
                    label: difference! < 0
                        ? 'Avertissement: manque en caisse'
                        : 'Information: surplus en caisse',
                    child: FCard.raw(
                      child: Container(
                        decoration: BoxDecoration(
                          color: difference! < 0
                              ? theme.colors.destructive.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: difference! < 0
                                ? theme.colors.destructive
                                : Colors.green,
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 3)),
                        child: Row(
                          children: [
                            Icon(
                              difference! < 0
                                  ? FIcons.triangleAlert
                                  : FIcons.info,
                              size: 20,
                              color: difference! < 0
                                  ? theme.colors.destructive
                                  : Colors.green,
                            ),
                            SizedBox(width: Responsive.spacing(context, multiplier: 2)),
                            Expanded(
                              child: Text(
                                difference! < 0
                                    ? 'Manque en caisse: Vérifiez les transactions'
                                    : 'Surplus en caisse: Vérifiez les transactions',
                                style: theme.typography.sm.copyWith(
                                  color: difference! < 0
                                      ? theme.colors.destructive
                                      : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],

              // Sales list (if enabled)
              if (showSalesList) ...[
                SizedBox(height: Responsive.spacing(context, multiplier: 4)),
                Divider(
                  color: theme.colors.border,
                  height: 1,
                ),
                SizedBox(height: Responsive.spacing(context, multiplier: 3)),
                SalesListWidget(
                  cashRegisterId: cashRegisterId,
                  openedAt: openedAt,
                  closedAt: closedAt,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit une ligne du résumé
  Widget _buildSummaryRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    final theme = FTheme.of(context);

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: isHighlighted
            ? EdgeInsets.all(Responsive.spacing(context, multiplier: 3))
            : EdgeInsets.zero,
        decoration: isHighlighted
            ? BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            SizedBox(width: Responsive.spacing(context, multiplier: 2)),
            Expanded(
              child: Text(
                label,
                style: theme.typography.base.copyWith(
                  color: isHighlighted
                      ? theme.colors.secondaryForeground
                      : theme.colors.foreground,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              value,
              style: theme.typography.base.copyWith(
                color: valueColor ??
                    (isHighlighted
                        ? theme.colors.secondaryForeground
                        : theme.colors.foreground),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
