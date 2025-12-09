// lib/features/settings/simple_connection_test.dart
// Page simplifiée pour tester la connexion

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants.dart';

class SimpleConnectionTest extends StatelessWidget {
  const SimpleConnectionTest({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Connexion'),
        backgroundColor: theme.colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration Backend',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'URL: ${AppConstants.baseUrl}',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: Prêt pour les tests',
                      style: theme.typography.base.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test de connexion lancé'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Tester la Connexion'),
            ),
          ],
        ),
      ),
    );
  }
}



