// lib/core/pin_service.dart
// Service de gestion des codes PIN pour la sécurité

import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'constants.dart';

/// Service de gestion des codes PIN
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialiser le service
  Future<void> init() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('[PinService] Initialized');
  }

  /// Définir un code PIN
  Future<bool> setPin(String pin) async {
    try {
      if (!_isInitialized) await init();
      
      if (pin.length != AppConstants.pinLength) {
        throw Exception('Le code PIN doit contenir ${AppConstants.pinLength} chiffres');
      }

      // Hacher le PIN pour la sécurité
      final hashedPin = _hashPin(pin);
      
      await _prefs!.setString('user_pin', hashedPin);
      await _prefs!.setBool('pin_enabled', true);
      
      print('[PinService] PIN set successfully');
      return true;
    } catch (e) {
      print('[PinService] Error setting PIN: $e');
      return false;
    }
  }

  /// Vérifier un code PIN
  Future<bool> verifyPin(String pin) async {
    try {
      if (!_isInitialized) await init();
      
      if (!await isPinEnabled()) {
        return true; // Pas de PIN défini, accès libre
      }

      final storedHashedPin = _prefs!.getString('user_pin');
      if (storedHashedPin == null) {
        return false;
      }

      final inputHashedPin = _hashPin(pin);
      final isValid = storedHashedPin == inputHashedPin;
      
      if (isValid) {
        // Réinitialiser le compteur de tentatives
        await _prefs!.setInt('pin_attempts', 0);
        print('[PinService] PIN verified successfully');
      } else {
        // Incrémenter le compteur de tentatives
        await _incrementAttempts();
        print('[PinService] PIN verification failed');
      }
      
      return isValid;
    } catch (e) {
      print('[PinService] Error verifying PIN: $e');
      return false;
    }
  }

  /// Vérifier si le PIN est activé
  Future<bool> isPinEnabled() async {
    try {
      if (!_isInitialized) await init();
      return _prefs!.getBool('pin_enabled') ?? false;
    } catch (e) {
      print('[PinService] Error checking PIN status: $e');
      return false;
    }
  }

  /// Désactiver le PIN
  Future<bool> disablePin(String currentPin) async {
    try {
      if (!_isInitialized) await init();
      
      // Vérifier le PIN actuel avant de désactiver
      if (await isPinEnabled() && !await verifyPin(currentPin)) {
        throw Exception('Code PIN incorrect');
      }

      await _prefs!.remove('user_pin');
      await _prefs!.setBool('pin_enabled', false);
      await _prefs!.setInt('pin_attempts', 0);
      
      print('[PinService] PIN disabled successfully');
      return true;
    } catch (e) {
      print('[PinService] Error disabling PIN: $e');
      return false;
    }
  }

  /// Changer le code PIN
  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      if (!_isInitialized) await init();
      
      // Vérifier le PIN actuel
      if (await isPinEnabled() && !await verifyPin(currentPin)) {
        throw Exception('Code PIN actuel incorrect');
      }

      // Définir le nouveau PIN
      return await setPin(newPin);
    } catch (e) {
      print('[PinService] Error changing PIN: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur est bloqué
  Future<bool> isLocked() async {
    try {
      if (!_isInitialized) await init();
      
      final attempts = _prefs!.getInt('pin_attempts') ?? 0;
      return attempts >= AppConstants.maxPinAttempts;
    } catch (e) {
      print('[PinService] Error checking lock status: $e');
      return false;
    }
  }

  /// Obtenir le nombre de tentatives restantes
  Future<int> getRemainingAttempts() async {
    try {
      if (!_isInitialized) await init();
      
      final attempts = _prefs!.getInt('pin_attempts') ?? 0;
      return AppConstants.maxPinAttempts - attempts;
    } catch (e) {
      print('[PinService] Error getting remaining attempts: $e');
      return AppConstants.maxPinAttempts;
    }
  }

  /// Obtenir le temps de déverrouillage
  Future<DateTime?> getUnlockTime() async {
    try {
      if (!_isInitialized) await init();
      
      final lockTime = _prefs!.getString('pin_lock_time');
      if (lockTime == null) return null;
      
      final lockDateTime = DateTime.parse(lockTime);
      return lockDateTime.add(Duration(seconds: AppConstants.pinLockoutDurationSeconds));
    } catch (e) {
      print('[PinService] Error getting unlock time: $e');
      return null;
    }
  }

  /// Déverrouiller manuellement (pour les administrateurs)
  Future<bool> unlock() async {
    try {
      if (!_isInitialized) await init();
      
      await _prefs!.setInt('pin_attempts', 0);
      await _prefs!.remove('pin_lock_time');
      
      print('[PinService] Manually unlocked');
      return true;
    } catch (e) {
      print('[PinService] Error unlocking: $e');
      return false;
    }
  }

  /// Incrémenter le compteur de tentatives
  Future<void> _incrementAttempts() async {
    final attempts = (_prefs!.getInt('pin_attempts') ?? 0) + 1;
    await _prefs!.setInt('pin_attempts', attempts);
    
    if (attempts >= AppConstants.maxPinAttempts) {
      await _prefs!.setString('pin_lock_time', DateTime.now().toIso8601String());
      print('[PinService] User locked after $attempts attempts');
    }
  }

  /// Hacher un code PIN
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Réinitialiser le service (pour les tests)
  Future<void> reset() async {
    try {
      if (!_isInitialized) await init();
      
      await _prefs!.remove('user_pin');
      await _prefs!.remove('pin_enabled');
      await _prefs!.remove('pin_attempts');
      await _prefs!.remove('pin_lock_time');
      
      print('[PinService] Reset completed');
    } catch (e) {
      print('[PinService] Error resetting: $e');
    }
  }
}


















