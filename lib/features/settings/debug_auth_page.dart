import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/responsive_helper.dart';
import '../../widgets/unified_header.dart';

/// Page de débogage pour tester l'authentification
class DebugAuthPage extends ConsumerStatefulWidget {
  const DebugAuthPage({super.key});

  @override
  ConsumerState<DebugAuthPage> createState() => _DebugAuthPageState();
}

class _DebugAuthPageState extends ConsumerState<DebugAuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final apiService = ApiService();
      apiService.init();

      // Test de connexion basique
      final response = await apiService.get('/test');
      setState(() {
        _result = 'Connexion réussie: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final apiService = ApiService();
      apiService.init();

      final response = await apiService.post(
        AppConstants.authLoginEndpoint,
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      setState(() {
        _result = 'Login réussi: ${response.statusCode}\nData: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de login: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      child: Scaffold(
        appBar: UnifiedHeader(
          title: 'Debug Authentification',
        ),
      body: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations de connexion
            FCard.raw(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration API',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, multiplier: 2)),
                    Text('URL: ${AppConstants.baseUrl}'),
                    Text('Login Endpoint: ${AppConstants.authLoginEndpoint}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, multiplier: 4)),

            // Test de connexion
            FButton(
              onPress: _isLoading ? null : _testConnection,
              style: FButtonStyle.outline(),
              child: const Text('Tester la connexion'),
            ),

            SizedBox(height: Responsive.spacing(context, multiplier: 4)),

            // Formulaire de test de login
            FCard.raw(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Test de Login',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, multiplier: 4)),

                    FTextField(
                      controller: _emailController,
                      hint: 'Email de test',
                      enabled: !_isLoading,
                    ),

                    SizedBox(height: Responsive.spacing(context, multiplier: 3)),

                    FTextField(
                      controller: _passwordController,
                      hint: 'Mot de passe de test',
                      enabled: !_isLoading,
                      obscureText: true,
                    ),

                    SizedBox(height: Responsive.spacing(context, multiplier: 4)),

                    FButton(
                      onPress: _isLoading ? null : _testLogin,
                      style: FButtonStyle.primary(),
                      child: const Text('Tester le Login'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, multiplier: 4)),

            // Résultats
            if (_result != null || _error != null)
              FCard.raw(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résultat',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, multiplier: 2)),
                      if (_result != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 2)),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _result!,
                            style: theme.typography.sm.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ),
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 2)),
                          decoration: BoxDecoration(
                            color: theme.colors.destructive.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colors.destructive.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.destructive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.spacing(context, multiplier: 4)),
                  child: CircularProgressIndicator(
                    color: theme.colors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
