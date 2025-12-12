// lib/features/reports/reports_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../providers/sales_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../core/sales_service.dart';
import '../../core/reports_service.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/unified_header.dart';
import '../../widgets/pdf_preview_page.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final SalesService _salesService = SalesService();
  final ReportsService _reportsService = ReportsService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  bool _isPrinting = false;
  Map<String, dynamic>? _stats;
  String _currentRoute = '/reports';

  @override
  void initState() {
    super.initState();
    // Load current register when page is initialized
    Future.microtask(() {
      if (mounted) {
        ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
      }
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = _salesService.getSalesStats(_startDate, _endDate);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des rapports: $e')),
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
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final cashRegisterState = ref.watch(cashRegisterProvider);

    return MainLayout(
      currentRoute: '/reports',
      appBar: UnifiedHeader(
        title: 'Rapports',
        onFilter: _selectDateRange,
        onRefresh: _loadStats,
        actions: [
          FButton(
            onPress: _isPrinting ? null : () => _printSalesReport(),
            child: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print, size: 16),
                      SizedBox(width: 4),
                      Text('Imprimer'),
                    ],
                  ),
          ),
        ],
      ),
      child: _buildContent(theme, cashRegisterState),
    );
  }

  Widget _buildContent(FThemeData theme, CashRegisterState cashRegisterState) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Période sélectionnée
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Période sélectionnée',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Du ${_formatDate(_startDate)} au ${_formatDate(_endDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques générales
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vue d\'ensemble',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total des ventes',
                          '${_formatCurrency(_stats!['totalSales'])}',
                          Icons.attach_money,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Nombre de ventes',
                          '${_stats!['salesCount']}',
                          Icons.receipt,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Vente moyenne',
                          '${_formatCurrency(_stats!['averageSale'])}',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(), // Placeholder for future stat
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Méthodes de paiement
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Méthodes de paiement',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...(_stats!['paymentMethods'] as Map<String, int>).entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key.toUpperCase()),
                          Text('${entry.value} ventes'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton de comptabilisation
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Comptabilisation',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accédez aux données comptables détaillées et aux exports',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () {
                      Navigator.of(context).pushNamed('/accounting');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance, size: 16),
                        SizedBox(width: 8),
                        Text('Ouvrir la comptabilisation'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top produits
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top produits',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...(_stats!['topProducts'] as List<Map<String, dynamic>>).map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product['productName'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${product['quantity']} vendus'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  // Méthode d'impression
  Future<void> _printSalesReport() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      print('[ReportsPage] 📝 Génération du PDF...');
      final pdfBytes = await _reportsService.generateSalesReportPdf(_startDate, _endDate);
      print('[ReportsPage] ✅ PDF généré: ${pdfBytes.length} bytes');
      
      if (mounted) {
        print('[ReportsPage] 📄 Ouverture de la page d\'aperçu PDF...');
        // Ouvrir la page d'aperçu PDF (comme pour le test d'imprimante)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewPage(
              pdfBytes: pdfBytes,
              title: 'Rapport de ventes',
            ),
          ),
        );
        print('[ReportsPage] ✅ Page d\'aperçu ouverte');
      }
    } catch (e) {
      print('[ReportsPage] ❌ ERREUR génération PDF: $e');
      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF: $e'),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }
}








