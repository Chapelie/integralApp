// lib/core/pin_manager.dart
// PIN management service with lockout mechanism
// Handles PIN validation, hashing, and security lockout after failed attempts

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// PIN manager service
class PinManager {
  static final PinManager _instance = PinManager._internal();
  factory PinManager() => _instance;
  PinManager._internal();

  final _secureStorage = const FlutterSecureStorage();

  static const String _pinHashKey = 'pin_hash';
  static const String _attemptsKey = 'pin_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  /// Set a new PIN (stores hash in secure storage)
  Future<void> setPin(String pin) async {
    try {
      if (pin.length != AppConstants.pinLength) {
        throw Exception(
          'Le code PIN doit contenir ${AppConstants.pinLength} chiffres',
        );
      }

      // Validate PIN contains only digits
      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        throw Exception('Le code PIN ne doit contenir que des chiffres');
      }

      print('[PinManager] Setting new PIN...');

      // Hash the PIN
      final hash = _hashPin(pin);

      // Store hash in secure storage
      await _secureStorage.write(key: _pinHashKey, value: hash);

      // Reset attempts
      await resetAttempts();

      print('[PinManager] PIN set successfully');
    } catch (e) {
      print('[PinManager] Error setting PIN: $e');
      rethrow;
    }
  }

  /// Validate a PIN against stored hash
  Future<bool> validatePin(String pin) async {
    try {
      // Check lockout first
      if (await checkLockout()) {
        throw Exception(
          'Trop de tentatives. Veuillez réessayer dans ${_getRemainingLockoutSeconds()} secondes',
        );
      }

      print('[PinManager] Validating PIN...');

      // Get stored hash
      final storedHash = await _secureStorage.read(key: _pinHashKey);

      if (storedHash == null) {
        print('[PinManager] No PIN set');
        return false;
      }

      // Hash input PIN
      final inputHash = _hashPin(pin);

      // Compare hashes
      final isValid = storedHash == inputHash;

      if (isValid) {
        print('[PinManager] PIN valid');
        await resetAttempts();
        return true;
      } else {
        print('[PinManager] PIN invalid');
        await incrementAttempts();
        return false;
      }
    } catch (e) {
      print('[PinManager] Error validating PIN: $e');
      rethrow;
    }
  }

  /// Request PIN via dialog
  Future<bool> requestPinDialog(BuildContext context) async {
    try {
      // Check lockout
      if (await checkLockout()) {
        final remaining = _getRemainingLockoutSeconds();
        if (context.mounted) {
          _showLockoutDialog(context, remaining);
        }
        return false;
      }

      if (!context.mounted) return false;

      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PinDialog(),
      );

      if (pin == null) {
        return false;
      }

      final isValid = await validatePin(pin);

      if (!isValid && context.mounted) {
        _showErrorDialog(context);
      }

      return isValid;
    } catch (e) {
      print('[PinManager] Error in PIN dialog: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }

      return false;
    }
  }

  /// Increment failed attempts
  Future<void> incrementAttempts() async {
    try {
      _failedAttempts++;

      await _secureStorage.write(
        key: _attemptsKey,
        value: _failedAttempts.toString(),
      );

      print('[PinManager] Failed attempts: $_failedAttempts');

      // Check if lockout is needed
      if (_failedAttempts >= AppConstants.maxPinAttempts) {
        _lockoutUntil = DateTime.now().add(
          Duration(seconds: AppConstants.pinLockoutDurationSeconds),
        );

        await _secureStorage.write(
          key: _lockoutUntilKey,
          value: _lockoutUntil!.toIso8601String(),
        );

        print('[PinManager] Lockout activated until: $_lockoutUntil');
      }
    } catch (e) {
      print('[PinManager] Error incrementing attempts: $e');
    }
  }

  /// Check if currently locked out
  Future<bool> checkLockout() async {
    try {
      final lockoutStr = await _secureStorage.read(key: _lockoutUntilKey);

      if (lockoutStr == null) {
        _lockoutUntil = null;
        return false;
      }

      _lockoutUntil = DateTime.parse(lockoutStr);

      if (DateTime.now().isBefore(_lockoutUntil!)) {
        print('[PinManager] Currently locked out until: $_lockoutUntil');
        return true;
      } else {
        // Lockout expired, reset
        await resetAttempts();
        return false;
      }
    } catch (e) {
      print('[PinManager] Error checking lockout: $e');
      return false;
    }
  }

  /// Reset failed attempts
  Future<void> resetAttempts() async {
    try {
      _failedAttempts = 0;
      _lockoutUntil = null;

      await _secureStorage.delete(key: _attemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);

      print('[PinManager] Attempts reset');
    } catch (e) {
      print('[PinManager] Error resetting attempts: $e');
    }
  }

  /// Get remaining lockout seconds
  int _getRemainingLockoutSeconds() {
    if (_lockoutUntil == null) return 0;

    final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Hash PIN using SHA256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Show lockout dialog
  void _showLockoutDialog(BuildContext context, int seconds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compte bloqué'),
        content: Text(
          'Trop de tentatives incorrectes. Veuillez réessayer dans $seconds secondes.',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.primary(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context) {
    final remaining = AppConstants.maxPinAttempts - _failedAttempts;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code PIN incorrect'),
        content: Text(
          'Le code PIN est incorrect. Il vous reste $remaining tentative(s).',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.primary(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Clear PIN (for testing or reset)
  Future<void> clearPin() async {
    try {
      await _secureStorage.delete(key: _pinHashKey);
      await resetAttempts();
      print('[PinManager] PIN cleared');
    } catch (e) {
      print('[PinManager] Error clearing PIN: $e');
      rethrow;
    }
  }
}

/// PIN dialog widget
class _PinDialog extends StatefulWidget {
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus on text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entrer le code PIN'),
      content: TextField(
        controller: _pinController,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: AppConstants.pinLength,
        decoration: const InputDecoration(
          hintText: 'Code PIN',
          counterText: '',
        ),
        onSubmitted: (value) {
          if (value.length == AppConstants.pinLength) {
            Navigator.pop(context, value);
          }
        },
      ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.outline(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: () {
              final pin = _pinController.text;
              if (pin.length == AppConstants.pinLength) {
                Navigator.pop(context, pin);
              }
            },
            style: FButtonStyle.primary(),
            child: const Text('Valider'),
          ),
        ),
      ],
    );
  }
}
