import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../core/responsive_helper.dart';
import '../../../core/auth_service.dart';
import '../../../core/api_service.dart';
import '../../../core/beep_service.dart';

/// Widget formulaire de login avec validation
///
/// Gère l'authentification avec email et mot de passe.
/// Affiche les erreurs et états de chargement.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valide que l'email n'est pas vide et a un format valide
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Valide que le mot de passe n'est pas vide
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  /// Effectue la connexion
  Future<void> _handleLogin() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      BeepService().playError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('[LoginForm] Starting login process for email: $email');

      // Appel direct à l'API de login
      final authService = AuthService();
      final user = await authService.login(email: email, password: password);
      
      print('[LoginForm] Login successful: ${user.email}');
      
      // Play success beep
      BeepService().playSuccess();
      
      if (!mounted) return;

      // Redirection directe vers la page de configuration
      print('[LoginForm] Redirecting to config page');
      Navigator.of(context).pushReplacementNamed('/company-warehouse-config');
      
    } catch (e) {
      print('[LoginForm] Login error: $e');
      
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Email ou mot de passe incorrect';
      }
      
      // Play error beep
      BeepService().playError();

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Semantics(
      label: 'Formulaire de connexion',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message display
            if (_errorMessage != null) ...[
              Semantics(
                label: 'Erreur de connexion',
                liveRegion: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    border: Border.all(
                      color: theme.colors.destructive.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colors.destructive,
                        size: isMobile ? 18.0 : 20.0,
                      ),
                      SizedBox(width: isMobile ? 10.0 : 12.0),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: (isMobile ? theme.typography.xs : theme.typography.sm).copyWith(
                            color: theme.colors.destructive,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20.0 : 24.0),
            ],

            // Email field
            Semantics(
              label: 'Champ email',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adresse email',
                    style: (isMobile ? theme.typography.xs : theme.typography.sm).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6.0 : 8.0),
                  FTextField(
                    controller: _emailController,
                    hint: 'exemple@email.com',
                    enabled: !_isLoading,
                    maxLines: 1,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    error: _validateEmail(_emailController.text) != null
                        ? Text(
                            _validateEmail(_emailController.text)!,
                            style: TextStyle(fontSize: isMobile ? 12.0 : 13.0),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 24.0 : 32.0),

            // Password field
            Semantics(
              label: 'Champ mot de passe',
              textField: true,
              obscured: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mot de passe',
                    style: (isMobile ? theme.typography.xs : theme.typography.sm).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6.0 : 8.0),
                  FTextField(
                    controller: _passwordController,
                    hint: 'Votre mot de passe',
                    enabled: !_isLoading,
                    maxLines: 1,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    error: _validatePassword(_passwordController.text) != null
                        ? Text(
                            _validatePassword(_passwordController.text)!,
                            style: TextStyle(fontSize: isMobile ? 12.0 : 13.0),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 32.0 : 40.0),

            // Login button
            Semantics(
              label: 'Bouton de connexion',
              button: true,
              enabled: !_isLoading,
              child: SizedBox(
                height: isMobile ? 52.0 : 56.0,
                child: FButton(
                  onPress: _isLoading ? null : _handleLogin,
                  style: FButtonStyle.primary(),
                  prefix: _isLoading
                      ? SizedBox(
                          width: isMobile ? 18.0 : 20.0,
                          height: isMobile ? 18.0 : 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colors.primaryForeground,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.login_rounded,
                          size: isMobile ? 18.0 : 20.0,
                          color: theme.colors.primaryForeground,
                        ),
                  child: Text(
                    _isLoading ? 'Connexion en cours...' : 'Se connecter',
                    style: (isMobile ? theme.typography.sm : theme.typography.base).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.primaryForeground,
                    ),
                  ),
                ),
              ),
            ),

            // Additional help text for mobile
            if (isMobile) ...[
              SizedBox(height: 20.0),
              Text(
                'Utilisez vos identifiants pour accéder à votre compte',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
