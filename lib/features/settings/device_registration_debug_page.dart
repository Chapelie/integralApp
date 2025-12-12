// lib/features/settings/device_registration_debug_page.dart
// Page de debug pour l'enregistrement du device

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/device_registration_service.dart';
import '../../core/device_service.dart';
import '../../widgets/unified_header.dart';
import '../../widgets/main_layout.dart';

class DeviceRegistrationDebugPage extends ConsumerStatefulWidget {
  const DeviceRegistrationDebugPage({super.key});

  @override
  ConsumerState<DeviceRegistrationDebugPage> createState() => _DeviceRegistrationDebugPageState();
}

class _DeviceRegistrationDebugPageState extends ConsumerState<DeviceRegistrationDebugPage> {
  final DeviceRegistrationService _deviceRegistrationService = DeviceRegistrationService();
  final DeviceService _deviceService = DeviceService();
  
  Map<String, dynamic>? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _deviceRegistrationService.getRegistrationStatus();
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _startMonitoring() async {
    try {
      await _deviceRegistrationService.startRegistrationMonitoring();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monitoring démarré')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      await _deviceRegistrationService.stopRegistrationMonitoring();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monitoring arrêté')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _resetRegistration() async {
    try {
      await _deviceRegistrationService.resetRegistration();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement réinitialisé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _tryRegisterNow() async {
    try {
      await _deviceRegistrationService.tryRegisterDevice();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tentative d\'enregistrement lancée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _startPolling() async {
    try {
      await _deviceRegistrationService.startPolling();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polling démarré')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _stopPolling() async {
    try {
      await _deviceRegistrationService.stopPolling();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polling arrêté')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _setDebugWarehouseId() async {
    try {
      // Simuler un warehouse ID pour les tests
      await _deviceRegistrationService.setDebugWarehouseId('test-warehouse-123');
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warehouse ID simulé défini')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/device-debug',
      appBar: UnifiedHeader(
        title: 'Debug - Enregistrement Device',
        color: theme.colors.primary,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  FCard.raw(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _status?['isRegistered'] == true 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                color: _status?['isRegistered'] == true 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Statut d\'enregistrement',
                                style: theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_status != null) ...[
                            _buildStatusRow('Enregistré', _status!['isRegistered'] ? 'Oui ✅' : 'Non ❌'),
                            _buildStatusRow('Tentatives', '${_status!['attempts']}/${_status!['maxAttempts']}'),
                            _buildStatusRow('Peut retry', _status!['canRetry'] ? 'Oui ✅' : 'Non ❌'),
                            _buildStatusRow('En cours de retry', _status!['isRetrying'] ? 'Oui 🔄' : 'Non'),
                            _buildStatusRow('En cours de polling', _status!['isPolling'] ? 'Oui 🔄' : 'Non'),
                            _buildStatusRow('Intervalle polling', '${_status!['pollingInterval']} secondes'),
                            _buildStatusRow('Device ID Local', _status!['deviceId'] ?? 'N/A'),
                            _buildStatusRow('Device ID Backend', _status!['backendDeviceId'] ?? 'Non enregistré'),
                            if (_status!['lastAttempt'] != null)
                              _buildStatusRow('Dernière tentative', _formatDateTime(_status!['lastAttempt'])),
                            if (_status!['nextRetryIn'] > 0)
                              _buildStatusRow('Prochain retry dans', '${_status!['nextRetryIn']} minutes'),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  FCard.raw(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Actions',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          FButton(
                            onPress: _tryRegisterNow,
                            child: const Text('Tenter enregistrement maintenant'),
                            prefix: const Icon(Icons.refresh),
                            style: FButtonStyle.outline(),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          FButton(
                            onPress: _startMonitoring,
                            child: const Text('Démarrer monitoring automatique'),
                            prefix: const Icon(Icons.play_arrow),
                            style: FButtonStyle.primary(),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          FButton(
                            onPress: _stopMonitoring,
                            child: const Text('Arrêter monitoring'),
                            prefix: const Icon(Icons.stop),
                            style: FButtonStyle.outline(),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          FButton(
                            onPress: _startPolling,
                            child: const Text('Démarrer polling'),
                            prefix: const Icon(Icons.schedule),
                            style: FButtonStyle.outline(),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          FButton(
                            onPress: _stopPolling,
                            child: const Text('Arrêter polling'),
                            prefix: const Icon(Icons.stop),
                            style: FButtonStyle.outline(),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          FButton(
                            onPress: _loadStatus,
                            child: const Text('Actualiser statut'),
                            prefix: const Icon(Icons.refresh),
                            style: FButtonStyle.outline(),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          FButton(
                            onPress: _setDebugWarehouseId,
                            child: const Text('Simuler Warehouse ID'),
                            prefix: const Icon(Icons.warehouse),
                            style: FButtonStyle.outline(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          FButton(
                            onPress: _resetRegistration,
                            child: const Text('Réinitialiser enregistrement'),
                            prefix: const Icon(Icons.delete),
                            style: FButtonStyle.destructive(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}

