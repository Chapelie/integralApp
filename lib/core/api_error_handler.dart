// lib/core/api_error_handler.dart
// Gestionnaire d'erreurs API pour les réponses Laravel

import 'dart:convert';
import 'package:flutter/material.dart';

class ApiError {
  final bool success;
  final String message;
  final List<String> errors;
  final String? timestamp;
  final int? statusCode;

  ApiError({
    required this.success,
    required this.message,
    required this.errors,
    this.timestamp,
    this.statusCode,
  });

  factory ApiError.fromResponse(dynamic response, int statusCode) {
    try {
      if (response is Map<String, dynamic>) {
        return ApiError(
          success: response['success'] ?? false,
          message: response['message'] ?? 'Erreur inconnue',
          errors: List<String>.from(response['errors'] ?? []),
          timestamp: response['timestamp'],
          statusCode: statusCode,
        );
      } else if (response is String) {
        // Essayer de parser la réponse JSON
        final Map<String, dynamic> jsonResponse = json.decode(response);
        return ApiError(
          success: jsonResponse['success'] ?? false,
          message: jsonResponse['message'] ?? 'Erreur inconnue',
          errors: List<String>.from(jsonResponse['errors'] ?? []),
          timestamp: jsonResponse['timestamp'],
          statusCode: statusCode,
        );
      }
    } catch (e) {
      // Si le parsing échoue, utiliser les valeurs par défaut
    }

    // Valeurs par défaut si le parsing échoue
    return ApiError(
      success: false,
      message: _getDefaultMessage(statusCode),
      errors: [],
      statusCode: statusCode,
    );
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide';
      case 401:
        return 'Non autorisé - Email ou mot de passe incorrect';
      case 403:
        return 'Accès interdit';
      case 404:
        return 'Ressource non trouvée';
      case 422:
        return 'Données de validation invalides';
      case 500:
        return 'Erreur interne du serveur';
      case 503:
        return 'Service temporairement indisponible';
      default:
        return 'Erreur inconnue (Code: $statusCode)';
    }
  }

  /// Retourne le message d'erreur principal
  String get displayMessage {
    if (message.isNotEmpty) {
      return message;
    }
    return _getDefaultMessage(statusCode ?? 500);
  }

  /// Retourne tous les messages d'erreur combinés
  String get fullMessage {
    final messages = <String>[];
    
    if (message.isNotEmpty) {
      messages.add(message);
    }
    
    if (errors.isNotEmpty) {
      messages.addAll(errors);
    }
    
    return messages.join('\n');
  }

  /// Vérifie si c'est une erreur d'authentification
  bool get isAuthError => statusCode == 401;

  /// Vérifie si c'est une erreur de validation
  bool get isValidationError => statusCode == 422;

  /// Vérifie si c'est une erreur serveur
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    return 'ApiError(success: $success, message: $message, errors: $errors, statusCode: $statusCode)';
  }
}

class ApiErrorHandler {
  /// Traite une réponse d'erreur HTTP et retourne un ApiError
  static ApiError handleError(dynamic response, int statusCode) {
    return ApiError.fromResponse(response, statusCode);
  }

  /// Traite une exception et retourne un ApiError
  static ApiError handleException(dynamic exception) {
    if (exception is ApiError) {
      return exception;
    }

    String message = 'Erreur inconnue';
    int statusCode = 500;

    if (exception.toString().contains('SocketException')) {
      message = 'Problème de connexion réseau';
      statusCode = 0;
    } else if (exception.toString().contains('TimeoutException')) {
      message = 'Délai d\'attente dépassé';
      statusCode = 408;
    } else if (exception.toString().contains('FormatException')) {
      message = 'Format de données invalide';
      statusCode = 400;
    }

    return ApiError(
      success: false,
      message: message,
      errors: [exception.toString()],
      statusCode: statusCode,
    );
  }

  /// Affiche une erreur dans l'interface utilisateur
  static void showError(BuildContext context, ApiError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.displayMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: error.errors.isNotEmpty
            ? SnackBarAction(
                label: 'Détails',
                textColor: Colors.white,
                onPressed: () {
                  _showErrorDetails(context, error);
                },
              )
            : null,
      ),
    );
  }

  /// Affiche les détails de l'erreur dans une boîte de dialogue
  static void _showErrorDetails(BuildContext context, ApiError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'erreur'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message: ${error.message}'),
              if (error.statusCode != null) ...[
                const SizedBox(height: 8),
                Text('Code: ${error.statusCode}'),
              ],
              if (error.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Erreurs:'),
                ...error.errors.map((e) => Text('• $e')),
              ],
              if (error.timestamp != null) ...[
                const SizedBox(height: 8),
                Text('Timestamp: ${error.timestamp}'),
              ],
            ],
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            style: FButtonStyle.primary(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
