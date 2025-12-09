import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../core/responsive_helper.dart';
import 'widgets/login_form.dart';

/// Page de connexion pour IntegralPOS
///
/// Affiche un formulaire de login centré avec logo et champs email/mot de passe.
/// Responsive pour mobile et desktop avec un design moderne et adaptatif.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24.0 : (isTablet ? 80.0 : 120.0),
              vertical: 32.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : (isTablet ? 500 : 400),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo section
                      _buildLogoSection(theme, isMobile, isTablet),
                      
                      SizedBox(height: isMobile ? 32.0 : 40.0),

                      // Message de bienvenue
                      _buildWelcomeMessage(theme, isMobile, isTablet),

                      SizedBox(height: isMobile ? 24.0 : 32.0),

                      // Formulaire de connexion
                      const LoginForm(),

                      SizedBox(height: isMobile ? 24.0 : 32.0),

                      // Informations de version et copyright
                      _buildFooter(theme, isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(FThemeData theme, bool isMobile, bool isTablet) {
    return Semantics(
      label: 'Logo IntegralPOS',
      child: Center(
        child: Image.asset(
          'assets/images/IntegralPOS.jpg',
          width: isMobile ? 150 : (isTablet ? 200 : 180),
          height: isMobile ? 150 : (isTablet ? 200 : 180),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.storefront_rounded,
              size: isMobile ? 80.0 : 100.0,
              color: theme.colors.primary,
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(FThemeData theme, bool isMobile, bool isTablet) {
    return Center(
      child: Text(
        'Connectez-vous',
        style: (isMobile ? theme.typography.xl2 : theme.typography.xl3).copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colors.foreground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooter(FThemeData theme, bool isMobile) {
    return Center(
      child: Text(
        '© 2025 IntegralPOS',
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
