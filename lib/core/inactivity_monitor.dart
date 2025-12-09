// lib/core/inactivity_monitor.dart
// Service de monitoring de l'inactivité de l'utilisateur

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'pin_service.dart';
import 'constants.dart';

/// Service de monitoring de l'inactivité
class InactivityMonitor {
  static final InactivityMonitor _instance = InactivityMonitor._internal();
  factory InactivityMonitor() => _instance;
  InactivityMonitor._internal();

  Timer? _inactivityTimer;
  Timer? _periodicCheckTimer;
  DateTime? _lastActivityTime;
  final Set<VoidCallback> _listeners = {};
  bool _isActive = true;
  final PinService _pinService = PinService();

  /// Démarrer le monitoring
  void start() {
    print('[InactivityMonitor] Starting inactivity monitoring');
    _lastActivityTime = DateTime.now();
    _startInactivityTimer();
    _startPeriodicCheck();
  }

  /// Arrêter le monitoring
  void stop() {
    print('[InactivityMonitor] Stopping inactivity monitoring');
    _inactivityTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _inactivityTimer = null;
    _periodicCheckTimer = null;
    _lastActivityTime = null;
  }

  /// Notifier une activité de l'utilisateur
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _isActive = true;
    _restartInactivityTimer();
  }

  /// Marquer l'app comme active
  void setActive(bool active) {
    _isActive = active;
    if (active) {
      recordActivity();
    }
  }

  /// Ajouter un listener pour les événements d'inactivité
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Retirer un listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Démarrer le timer d'inactivité
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: AppConstants.inactivityTimeoutSeconds), () {
      _onInactivityDetected();
    });
  }

  /// Redémarrer le timer d'inactivité
  void _restartInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }

  /// Timer de vérification périodique
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isActive) return;
      
      if (_lastActivityTime != null) {
        final inactivityDuration = DateTime.now().difference(_lastActivityTime!);
        if (inactivityDuration.inSeconds >= AppConstants.inactivityTimeoutSeconds) {
          _onInactivityDetected();
        }
      }
    });
  }

  /// Gestionnaire d'inactivité détectée
  void _onInactivityDetected() async {
    print('[InactivityMonitor] Inactivity detected');

    // Vérifier si le PIN est activé
    final isPinEnabled = await _pinService.isPinEnabled();
    if (!isPinEnabled) {
      print('[InactivityMonitor] PIN not enabled, skipping lock');
      return;
    }

    print('[InactivityMonitor] Notifying listeners of inactivity');
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        print('[InactivityMonitor] Error in listener: $e');
      }
    }
  }

  /// Obtenir le temps d'inactivité
  Duration getInactivityDuration() {
    if (_lastActivityTime == null) return Duration.zero;
    return DateTime.now().difference(_lastActivityTime!);
  }

  /// Vérifier si l'utilisateur est actif
  bool get isUserActive => _isActive && _lastActivityTime != null && 
      DateTime.now().difference(_lastActivityTime!).inSeconds < AppConstants.inactivityTimeoutSeconds;
}









