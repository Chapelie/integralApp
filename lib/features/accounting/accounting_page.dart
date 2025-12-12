// lib/features/accounting/accounting_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/reports_service.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';

class AccountingPage extends ConsumerStatefulWidget {
  const AccountingPage({super.key});

  @override
  ConsumerState<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends ConsumerState<AccountingPage> {
  final ReportsService _reportsService = ReportsService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _accountingStats;
  String _currentRoute = '/accounting';
  bool _enableTax = false;

  @override
  void initState() {
    super.initState();
    _loadTaxSettings();
    _loadAccountingStats();
  }

  Future<void> _loadTaxSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enableTax = prefs.getBool('enableTax') ?? false;
    setState(() {
      _enableTax = enableTax;
    });
  }

  Future<void> _loadAccountingStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = _reportsService.getAccountingStats(_startDate, _endDate);
      setState(() {
        _accountingStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAccountingStats();
    }
  }

  Future<void> _exportAccountingData() async {
    try {
      // Exporter les ventes
      final salesCsv = _reportsService.exportSalesForAccounting(_startDate, _endDate);
      final salesFileName = 'ventes_${_formatDateForFile(_startDate)}_${_formatDateForFile(_endDate)}.csv';
      
      // Exporter les mouvements de caisse
      final movementsCsv = _reportsService.exportCashMovementsForAccounting(_startDate, _endDate);
      final movementsFileName = 'mouvements_${_formatDateForFile(_startDate)}_${_formatDateForFile(_endDate)}.csv';
      
      // Obtenir les statistiques
      final accountingStats = _reportsService.getAccountingStats(_startDate, _endDate);
      final statsJson = _formatJson(accountingStats);
      final statsFileName = 'comptabilisation_${_formatDateForFile(_startDate)}_${_formatDateForFile(_endDate)}.json';
      
      // Partager les fichiers
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(Uint8List.fromList(salesCsv.codeUnits), name: salesFileName, mimeType: 'text/csv'),
            XFile.fromData(Uint8List.fromList(movementsCsv.codeUnits), name: movementsFileName, mimeType: 'text/csv'),
            XFile.fromData(Uint8List.fromList(statsJson.codeUnits), name: statsFileName, mimeType: 'application/json'),
          ],
          text: 'Données de comptabilisation - ${_formatDate(_startDate)} au ${_formatDate(_endDate)}',
        ),
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: FTheme.of(context).colors.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/accounting',
      appBar: UnifiedHeader(
        title: 'Comptabilisation',
        onFilter: _selectDateRange,
        onRefresh: _loadAccountingStats,
      ),
      child: _buildContent(theme),
    );
  }

  Widget _buildContent(FThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_accountingStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final sales = _accountingStats!['sales'] as Map<String, dynamic>;
    final cashFlow = _accountingStats!['cash_flow'] as Map<String, dynamic>;

    return Column(
      children: [
        // Header avec actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colors.background,
            border: Border(
              bottom: BorderSide(
                color: theme.colors.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Comptabilisation',
                style: theme.typography.xl.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                tooltip: 'Sélectionner la période',
              ),
              IconButton(
                onPressed: _exportAccountingData,
                icon: const Icon(Icons.download),
                tooltip: 'Exporter les données',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Période sélectionnée
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Période de comptabilisation',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Du ${_formatDate(_startDate)} au ${_formatDate(_endDate)}',
                    style: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Résumé des ventes
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé des ventes',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Nombre de ventes',
                          '${sales['count']}',
                          Icons.receipt,
                          theme.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Total des ventes',
                          _formatCurrency(sales['total']),
                          Icons.attach_money,
                          theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_enableTax)
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'TVA collectée',
                            _formatCurrency(sales['tax']),
                            Icons.account_balance,
                            theme.colors.primary,
                          ),
                        ),
                      if (_enableTax) const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          _enableTax ? 'Montant net' : 'Montant total',
                          _formatCurrency(sales[_enableTax ? 'net' : 'total']),
                          Icons.calculate,
                          theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Flux de trésorerie
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flux de trésorerie',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Entrées',
                          _formatCurrency(cashFlow['in']),
                          Icons.trending_up,
                          theme.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Sorties',
                          _formatCurrency(cashFlow['out']),
                          Icons.trending_down,
                          theme.colors.destructive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _buildStatCard(
                      theme,
                      'Solde net',
                      _formatCurrency(cashFlow['net']),
                      Icons.account_balance_wallet,
                      (cashFlow['net'] as num) >= 0 ? theme.colors.primary : theme.colors.destructive,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informations de génération
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rapport généré le: ${_formatDateTime(DateTime.parse(_accountingStats!['generated_at']))}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    ],
    );
  }

  Widget _buildStatCard(FThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.typography.xs.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String _formatJson(Map<String, dynamic> data) {
    // Simple JSON formatting for export
    final buffer = StringBuffer();
    buffer.writeln('{');
    _writeJsonObject(buffer, data, 1);
    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeJsonObject(StringBuffer buffer, Map<String, dynamic> data, int indent) {
    final spaces = '  ' * indent;
    final entries = data.entries.toList();
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;
      
      buffer.write('$spaces"${entry.key}": ');
      
      if (entry.value is Map<String, dynamic>) {
        buffer.writeln('{');
        _writeJsonObject(buffer, entry.value as Map<String, dynamic>, indent + 1);
        buffer.write('$spaces}');
      } else if (entry.value is List) {
        buffer.writeln('[');
        final list = entry.value as List;
        for (int j = 0; j < list.length; j++) {
          final isLastItem = j == list.length - 1;
          buffer.writeln('$spaces  "${list[j]}"${isLastItem ? '' : ','}');
        }
        buffer.write('$spaces]');
      } else {
        buffer.write('"${entry.value}"');
      }
      
      if (!isLast) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }
  }
}
