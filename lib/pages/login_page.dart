import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/page_transitions.dart';
import 'chat_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscureText = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      _showMessage('Lütfen şifrenizi girin.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      final isPasswordCorrect = await _databaseHelper.verifyPassword(password);

      if (isPasswordCorrect) {
        HapticFeedback.lightImpact();
        if (mounted) {
          Navigator.of(context).pushReplacementSmooth(
            const ChatPage(),
            type: PageTransitionType.fadeSlide,
          );
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _isLoading = false;
        });
        _showMessage(
          'Giriş başarısız! Yanlış şifre girdiniz.',
          isError: true,
          isPasswordError: true,
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
      });
      _showMessage('Bir hata oluştu. Lütfen tekrar deneyin.', isError: true);
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
    bool isPasswordError = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isPasswordError,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isError ? 'Hata' : 'Başarılı',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isPasswordError) {
                SystemNavigator.pop();
              }
            },
            child: Text(isPasswordError ? 'Uygulamayı Kapat' : 'Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    theme.colorScheme.secondaryContainer.withOpacity(0.2),
                    theme.colorScheme.surface,
                  ],
                ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ResponsiveBuilder(
                    mobile: (context, constraints) =>
                        _buildMobileLayout(context),
                    tablet: (context, constraints) =>
                        _buildTabletLayout(context),
                    desktop: (context, constraints) =>
                        _buildDesktopLayout(context),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: _buildLoginCard(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildWelcomeSection(context)),
        Expanded(
          child: Container(
            decoration: AppTheme.glassmorphism(context),
            child: _buildLoginCard(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildWelcomeSection(context)),
        Expanded(
          flex: 2,
          child: Container(
            decoration: AppTheme.glassmorphism(context),
            child: _buildLoginCard(context),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassmorphism(context),
                child: Icon(
                  Icons.auto_awesome,
                  size: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 64,
                    tablet: 80,
                    desktop: 96,
                  ),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Chat Assistant',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gelişmiş yapay zeka ile güçlendirilmiş sohbet deneyimi. Sorularınızı sorun, fikirlerinizi paylaşın ve akıllı yanıtlar alın.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFeatureChip(context, Icons.psychology, 'Akıllı AI'),
                      _buildFeatureChip(context, Icons.security, 'Güvenli'),
                      _buildFeatureChip(context, Icons.speed, 'Hızlı'),
                      _buildFeatureChip(
                        context,
                        Icons.chat_bubble,
                        'Etkileşimli',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          child: Center(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: ResponsiveUtils.getIconSize(
                          context,
                          baseSize: 40,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),

                  // Title with theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giriş Yapın',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Güvenli sohbete başlayın',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ThemeToggleButton(),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 32,
                      tablet: 40,
                      desktop: 48,
                    ),
                  ),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscureText,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      hintText: 'Güvenlik şifrenizi girin',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        tooltip: _obscureText
                            ? 'Şifreyi göster'
                            : 'Şifreyi gizle',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi girin';
                      }
                      return null;
                    },
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveUtils.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                        disabledBackgroundColor: theme.colorScheme.onSurface
                            .withOpacity(0.12),
                        disabledForegroundColor: theme.colorScheme.onSurface
                            .withOpacity(0.38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(
                              context,
                              baseRadius: 16,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getResponsiveValue(
                            context,
                            mobile: 24,
                            tablet: 32,
                            desktop: 40,
                          ),
                          vertical: ResponsiveUtils.getResponsiveValue(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveValue(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bu uygulama güvenli şifre ile korunmaktadır',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
